/*
 * Authors: Veronica Cortes, Richie Harris
 * Email:   vcortes@g.hmc.edu, rkharris@g.hmc.edu
 * Date:    20 November 2019
 * 
 * Feedforward neural network for image classification
 * 
 */

`include "nn_15_node_defines.svh"

module top(input logic clk,
			     input logic pclk, reset,
				  input logic vsync,
				  input logic href,
				  input logic d0, d1, d2, d3, d4, d5, d6, d7,
				  input logic sck,
				  input logic sdi,
				  output logic sdo,
				  output logic done,
				  output logic xclk,
				  output logic [9:0] classification);

	assign xclk = clk; // drive camera xclk with 40 Hz from oscillator
				  
	
	logic [2047:0] frame;
	logic decimate_done;
				  
	
	decimate dec(pclk, reset, vsync, href, d0, d1, d2, d3, d4, d5, d6, d7, decimate_done, frame);
	
	spi s(sck, sdi, sdo, done, frame);
	
	choose_pixel cp(clk, cycle, frame, px_uint8);
	
	logic [`UINT_8-1:0]  px_uint8;
   logic [`ADR_LEN-1:0] cycle;

   nn feedforward(clk, reset, decimate_done, px_uint8, cycle, classification, done);
				  
endmodule

module choose_pixel(input logic clk,
						  input logic [`ADR_LEN-1:0] cycle,
						  input logic [2047:0] frame,
						  output logic [`UINT_8-1:0] px_uint8);
						  
	
	logic select;
	logic [`UINT_8-1:0] bias;
	
	assign bias = 8'hFF;
	
	assign select = (cycle==10'd0);
	
	mux2 #(`UINT_8) pixelmux(frame[`UINT_8*cycle-1 -: `UINT_8], bias, select, px_uint8);
						  
endmodule


module nn(input  logic                  clk, reset, decimate_done,
          input  logic [`UINT_8-1:0]    px_uint8,
          output logic [`ADR_LEN-1:0]   cycle,
          output logic [0:9]            classification,
          output logic                  done);

    // wires
    logic                                we, clear;     // controls for RAM
    logic                                rd_src1;
    logic [1:0]                          rd_src2;
    logic [`HIDDEN_LAYER_WID-1:0]        rd1, rd2, rd3; // rd from weight ROMs
    logic [0:`NUM_MULTS-1] [`INT_16-1:0] result;        // wd to RAM
    logic [`RESULT_RD_WID-1:0]           prev_result;   // rd from RAM
    
    // weight memories
    // 257 rows of 15 int16s
    w1rom h1_weights(clk, cycle, rd1);
    // 16 rows of 15 int16s
    w2rom h2_weights(clk, cycle, rd2);
    w3rom h3_weights(clk, cycle, rd3);
    
    // output layer mem
    oram result_ram(clk, we, cycle, result, prev_result);
    
    // controller
    controller c(clk, reset, decimate_done, we, cycle, rd_src1, rd_src2, clear, done);
    
    // datapath
    datapath d(clk, rd_src1, rd_src2, clear, px_uint8, rd1, rd2, rd3, prev_result, result, classification);
    
    
endmodule

module datapath(input  logic                                clk,
                input  logic                                rd_src1,
                input  logic [1:0]                          rd_src2,
                input  logic                                clear,
                input  logic [`UINT_8-1:0]                  px_uint8,
                input  logic [`HIDDEN_LAYER_WID-1:0]        rd1, rd2, rd3, 
				input  logic [`RESULT_RD_WID-1:0]           prev_result,
                output logic [0:`NUM_MULTS-1] [`INT_16-1:0] result,
                output logic [0:9]                          classification);
    
    logic        [`INT_16-1:0]                  px_int16;
    logic signed [`INT_16-1:0]                  src1;
    logic signed [`HIDDEN_LAYER_WID-1:0]        src2;
    logic signed [0:`NUM_MULTS-1] [`INT_16-1:0] src2_int16; 
    logic signed [0:`NUM_MULTS-1] [`INT_32-1:0] prod, sum, activ_sum;
    
    // extend incoming image to int16 and convert to Q15
    // maps [0,255] uint8 to [-1,1) Q15 int16
    assign px_int16 = {1'b0, px_uint8, 7'b0}; 
    
    // select read sources
    /*  src1 | src2
     *  -----------
     *  img  | rd1
     *  out  | rd2
     *  out  | rdN
     */ 
     mux2 #(`INT_16) src1mux(px_int16, prev_result, rd_src1, src1);
     mux3 #(`HIDDEN_LAYER_WID) src2mux(rd1, rd2, rd3, rd_src2, src2);
    
    // generate datapath            
    genvar i;
    generate 
        for (i=0 ; i<`NUM_MULTS; i++) begin : dpsl // generate wires
        	// 1st column of weights is the MSB of src2
            // therefore, d0 corresponds to first hidden weight, d1 to second, ...
            assign src2_int16[i] = src2[(`INT_16*(16-(i+1))-1) -: `INT_16]; //*(16-i) so that d0 is the first column (MSB)
            mul #(`INT_16) m(src1, src2_int16[i], prod[i]);
            acc #(`INT_32) lc(clk, clear, prod[i], sum[i]);
            neg_comp #(`INT_32) relu(sum[i], activ_sum[i]);
            assign result[i] = activ_sum[i][31:16];
        end
    endgenerate 
    
	// TODO: assign classification (can't send out 10 int16s because of I/O pin limit)
    assign classification = '0;
       
endmodule

module controller(input  logic                clk, reset, decimate_done,
                  output logic                we,
                  output logic [`ADR_LEN-1:0] cycle,
                  output logic                rd_src1,
                  output logic [1:0]          rd_src2, 
                  output logic                clear,
                  output logic                done);
	 
	typedef enum {RESET, 
                  MUL1, WB1, CLR1, 
                  MUL2, WB2, CLR2, 
                  MUL3, WB3, CLR3, 
                  DONE} statetype;
    statetype state, nextstate;
    
    // control signals
    logic [3:0] controls;
    // flags
    logic       input_layer_done, output_layer_done;
    logic [1:0] layers_done_count;

	always_ff @(posedge clk, posedge reset) begin
		if (reset) state <= RESET;
        else       state <= nextstate;
    end
        
    always_comb begin
        case(state)
            RESET: if (decimate_done)             nextstate = MUL1;
					   else			                     nextstate = RESET;
				MUL1:  if (cycle == `MULT_INPUT_CYCLES)  nextstate = WB1;
					   else			                     nextstate = MUL1;
				WB1:   			                         nextstate = CLR1;
				CLR1:				                     nextstate = MUL2;
				MUL2:  if (cycle == `MULT_HIDDEN_CYCLES) nextstate = WB2;
					   else			                     nextstate = MUL2;
				WB2:				                     nextstate = CLR2;
				CLR2:				                     nextstate = MUL3;
				MUL3:  if (cycle == `MULT_HIDDEN_CYCLES) nextstate = WB3;
					   else			                     nextstate = MUL3;
				WB3:					                 nextstate = CLR3;
				CLR3:					                 nextstate = DONE;
				DONE:					                 nextstate = DONE;
				default:				                 nextstate = RESET;
        endcase
    end
	
    // sequential controls
    // TODO: condense this further, if possible 
    always_ff @(posedge clk)
        case(state)
            RESET:	 begin 
                        cycle <= 0;
                        layers_done_count <= 0;
                     end
            MUL1:	    cycle <= cycle + 1'b1;
            WB1:	 begin 
                        cycle <= 0;
                        layers_done_count <= layers_done_count + 1'b1;
                     end
            CLR1:	    cycle <= 0; // delay to calculate final sum
            MUL2:	    cycle <= cycle + 1'b1;           
            WB2:	 begin
                        cycle <= 0;
                        layers_done_count <= layers_done_count + 1'b1;
                     end
            CLR2:	    cycle <= 0;                     
            MUL3:	    cycle <= cycle + 1'b1;
            WB3:	    cycle <= 0; // TODO: finish implementing
            CLR3:	    cycle <= 0; // TODO: finish implementing
            DONE:	    cycle <= 0; // TODO: finish implementing
            default:    cycle <= 0; // TODO: finish implementing
        endcase
        
	// combinational controls
    always_comb begin
		case(state)
            RESET:	 controls = 4'b0100;
            MUL1:	 controls = 4'b0000;
            WB1:	 controls = 4'b1010;
            CLR1:	 controls = 4'b0110;
            MUL2:	 controls = 4'b0010;
            WB2:	 controls = 4'b1010;
            CLR2:	 controls = 4'b0110;
            MUL3:	 controls = 4'b0010;
            WB3:	 controls = 4'b1011; // stop here in sim to check results
            CLR3:	 controls = 4'b0110;
            DONE:	 controls = 4'b0010;
            default: controls = 4'bxxxx;
        endcase
	end	
    
    // set controls
    assign {we, clear, input_layer_done, output_layer_done} = controls;	
	
    // assign flags
	assign rd_src1 = input_layer_done;
    assign rd_src2 = layers_done_count;
    assign done    = output_layer_done;
    
endmodule

//
// --- NN Memories ---
//

module inputmem(input  logic                clk, 
                input  logic [`ADR_LEN-1:0] a,
                output logic [`UINT_8-1:0]  rd);

    logic [`UINT_8-1:0] ROM[`INPUT_LAYER_LEN-1:0];
    
    initial
        $readmemh("inputlayer.dat", ROM);
    
    assign rd = ROM[a[`ADR_LEN-1:0]]; // changed the 2 to 0
endmodule

module w1rom(input  logic                         clk,
             input  logic [`ADR_LEN-1:0]          a,
             output logic [`HIDDEN_LAYER_WID-1:0] rd);

    logic [`HIDDEN_LAYER_WID-1:0] ROM[`INPUT_LAYER_LEN-1:0];
    
    initial
        $readmemh("hiddenweights1.dat", ROM);
    
    assign rd = ROM[a[`ADR_LEN-1:0]]; // changed the 2 to 0
endmodule

module w2rom(input  logic                         clk,
             input  logic [`ADR_LEN-1:0]          a,
             output logic [`HIDDEN_LAYER_WID-1:0] rd);

    logic [`HIDDEN_LAYER_WID-1:0] ROM[`HIDDEN_LAYER_LEN-1:0];
    
    initial
        $readmemh("hiddenweights2.dat", ROM);
    
    assign rd = ROM[a[`ADR_LEN-1:0]]; // changed the 2 to 0
endmodule

module w3rom(input  logic                         clk,
             input  logic [`ADR_LEN-1:0]          a, // TODO: remove this hack
             output logic [`HIDDEN_LAYER_WID-1:0] rd);

    logic [`HIDDEN_LAYER_WID-1:0] ROM[`HIDDEN_LAYER_LEN-1:0];
    
    initial
        $readmemh("outputweights.dat", ROM);
    
    assign rd = ROM[a[`ADR_LEN-1:0]]; // changed the 2 to 0
endmodule

module oram(input  logic                      clk, we,
            input  logic [`ADR_LEN-1:0]       a,
            input  logic [`RESULT_WD_WID-1:0] wd,
            output logic [`RESULT_RD_WID-1:0] rd);

    logic [`RESULT_RD_WID-1:0] RAM[`RESULT_LEN-1:0];
    
    assign rd = RAM[a[`ADR_LEN-1:0]]; // changed the 2 to 0
  
    // TODO: review this; synthesizes to flops instead of RAM
    always_ff @(posedge clk)
        if (we) begin
            RAM[0]  <= 16'h7FFF; 
            RAM[1]  <= wd[`INT_16*15-1 -:`INT_16]; 
            RAM[2]  <= wd[`INT_16*14-1 -:`INT_16]; 
            RAM[3]  <= wd[`INT_16*13-1 -:`INT_16]; 
            RAM[4]  <= wd[`INT_16*12-1 -:`INT_16]; 
            RAM[5]  <= wd[`INT_16*11-1 -:`INT_16]; 
            RAM[6]  <= wd[`INT_16*10-1 -:`INT_16]; 
            RAM[7]  <= wd[`INT_16*9-1  -:`INT_16]; 
            RAM[8]  <= wd[`INT_16*8-1  -:`INT_16]; 
            RAM[9]  <= wd[`INT_16*7-1  -:`INT_16]; 
            RAM[10] <= wd[`INT_16*6-1  -:`INT_16]; 
            RAM[11] <= wd[`INT_16*5-1  -:`INT_16]; 
            RAM[12] <= wd[`INT_16*4-1  -:`INT_16]; 
            RAM[13] <= wd[`INT_16*3-1  -:`INT_16]; 
            RAM[14] <= wd[`INT_16*2-1  -:`INT_16];
            RAM[15] <= wd[`INT_16*1-1  -:`INT_16];
        end
endmodule

//
// --- NN-specific Gates ---
//

module mul #(parameter WIDTH = 8)
            (input  logic signed [WIDTH-1:0]   a, b,
             output logic signed [2*WIDTH-1:0] y);
  
    assign y = (a * b) << 1; // LSL to get rid of extra integer bit
  
endmodule

module acc #(parameter WIDTH = 8)
            (input  logic                    clk, reset,
             input  logic signed [WIDTH-1:0] d, 
             output logic signed [WIDTH-1:0] sum);

    always_ff @(posedge clk, posedge reset)
        if (reset) sum <= 0;
        else       sum <= sum + d;
endmodule

module neg_comp #(parameter WIDTH = 8)
                 (input  logic signed [WIDTH-1:0] x,
                  output logic signed [WIDTH-1:0] y);

    assign y = (x[WIDTH-1] == 0) ? x : '0; 
endmodule

//
// --- Basic Logic Gates ---
//

module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset,
               input  logic [WIDTH-1:0] d, 
               output logic [WIDTH-1:0] q);

    always_ff @(posedge clk, posedge reset)
        if (reset) q <= 0;
        else       q <= d;
endmodule

module mux2 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, 
              input  logic             s, 
              output logic [WIDTH-1:0] y);

    assign y = s ? d1 : d0; 
endmodule

module mux3 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, d2,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);

    assign y = s[1] ? d2 : (s[0] ? d1 : d0); 
endmodule



module decimate(input logic pclk, reset,
						 input logic vsync,
						 input logic href,
						 input logic d0, d1, d2, d3, d4, d5, d6, d7,
						 output logic done,
						 output logic [2047:0] frame);
						 
			
	logic y;
	logic [19:0] a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15;
	logic [9:0] rowcount;
	logic [9:0] colcount;
	
	 
   typedef enum {S0, S1, S2, S3, S4, S5, S6, S7, S8} statetype;
   statetype state, nextstate;
				  

	always_ff @(posedge pclk, posedge reset) begin
		if (reset)	state <= S0;
      else        state <= nextstate;
    end
        
    always_comb begin
        case(state)
            S0:    if (vsync)  nextstate = S1;
                   else        nextstate = S0;
            S1:    if (~vsync) nextstate = S2;
                   else        nextstate = S1;
            S2:    if (href)   nextstate = S3;
                   else        nextstate = S2;
            S3:    if (~href)  nextstate = S4;
                   else        nextstate = S3;
				S4:	 if (colcount == 10'd30)		 		 nextstate = S6;
						 else if (colcount == 10'd60)		 	 nextstate = S6;
						 else if (colcount == 10'd90)		 	 nextstate = S6;
						 else if (colcount == 10'd120)		 nextstate = S6;
						 else if (colcount == 10'd150)		 nextstate = S6;
						 else if (colcount == 10'd180)		 nextstate = S6;
						 else if (colcount == 10'd210)		 nextstate = S6;
						 else if (colcount == 10'd240)		 nextstate = S6;
						 else if (colcount == 10'd270)		 nextstate = S6;
						 else if (colcount == 10'd300)		 nextstate = S6;
						 else if (colcount == 10'd330)		 nextstate = S6;
						 else if (colcount == 10'd360)		 nextstate = S6;
						 else if (colcount == 10'd390)		 nextstate = S6;
						 else if (colcount == 10'd420)		 nextstate = S6;
						 else if (colcount == 10'd450)		 nextstate = S6;
						 else if (colcount == 10'd480)		 nextstate = S7;
						 else			 nextstate = S5;
            S5:    if (href)   nextstate = S3;
						 else			 nextstate = S5;
				S6:					 nextstate = S5;
				S7:					 nextstate = S8;
				S8:					 nextstate = S8;
				default:				 nextstate = S0;
        endcase
    end
						 
	always_ff @(posedge pclk) begin
		  if (state == S2) begin
				colcount <= '0;
				a0 <= '0;
				a1 <= '0;
				a2 <= '0;
				a3 <= '0;
				a4 <= '0;
				a5 <= '0;
				a6 <= '0;
				a7 <= '0;
				a8 <= '0;
				a9 <= '0;
				a10 <= '0;
				a11 <= '0;
				a12 <= '0;
				a13 <= '0;
				a14 <= '0;
				a15 <= '0;
		  end
		  else if (state == S4) 	begin
				colcount <= colcount + 1'b1;
				rowcount <= 10'b0;
		  end
		  else if (state == S6) begin
				frame <= {{a15[17:10], a14[17:10], a13[17:10], a12[17:10], a11[17:10], a10[17:10], a9[17:10], a8[17:10], a7[17:10], a6[17:10], a5[17:10], a4[17:10], a3[17:10], a2[17:10], a1[17:10], a0[17:10]}, frame[2047:128]};
				a0 <= '0;
				a1 <= '0;
				a2 <= '0;
				a3 <= '0;
				a4 <= '0;
				a5 <= '0;
				a6 <= '0;
				a7 <= '0;
				a8 <= '0;
				a9 <= '0;
				a10 <= '0;
				a11 <= '0;
				a12 <= '0;
				a13 <= '0;
				a14 <= '0;
				a15 <= '0;
		  end
		  else if (state == S7) begin
				frame <= {{a15[17:10], a14[17:10], a13[17:10], a12[17:10], a11[17:10], a10[17:10], a9[17:10], a8[17:10], a7[17:10], a6[17:10], a5[17:10], a4[17:10], a3[17:10], a2[17:10], a1[17:10], a0[17:10]}, frame[2047:128]};
		  end
		  else if (state == S3) begin
            if (~y)	begin
					if (rowcount < 10'd40)	a0 <= a0 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd80)	a1 <= a1 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd120)	a2 <= a2 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd160)	a3 <= a3 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd200)	a4 <= a4 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd240)	a5 <= a5 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd280)	a6 <= a6 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd320)	a7 <= a7 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd360)	a8 <= a8 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd400)	a9 <= a9 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd440)	a10 <= a10 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd480)	a11 <= a11 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd520)	a12 <= a12 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd560)	a13 <= a13 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd600)	a14 <= a14 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					else if (rowcount < 10'd640)	a15 <= a15 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
					rowcount <= rowcount + 1'b1;
				end
				y = y + 1'b1;
				done <= 1'b0;
        end
        else if (state == S8) begin
            done <= 1'd1;
        end 
        else if (state == S0) begin
				done <= 1'b0;
				rowcount <= '0;
				y <= 1'b0;
        end
		  else if (state == S1) begin
				done <= 1'b0;
				rowcount <= '0;
				y <= 1'b0;
        end
    end  
						 		 
						 
endmodule



/////////////////////////////////////////////
// spi
//   SPI interface.  Shifts in key and plaintext
//   Captures ciphertext when done, then shifts it out
//   Tricky cases to properly change sdo on negedge clk
/////////////////////////////////////////////

module spi(input  logic sck, 
               input  logic sdi,
               output logic sdo,
               input  logic done,
               input  logic [2047:0] frame);

    logic sdodelayed, wasdone;
	 logic [2047:0] framecaptured;
               
    // shift out the data.  80 scks to shift out data
    always_ff @(posedge sck)
		  if (!wasdone)	framecaptured = frame;
		  else				framecaptured = {framecaptured[2046:0], sdi};
    
    // sdo should change on the negative edge of sck
    always_ff @(negedge sck) begin
        wasdone = done;
		  sdodelayed = framecaptured[2046];
    end
    
    // when done is first asserted, shift out msb before clock edge
    assign sdo = (done & !wasdone) ? frame[2047] : sdodelayed;
endmodule











