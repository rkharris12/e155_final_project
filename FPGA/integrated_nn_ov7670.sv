/*
 * Authors: Veronica Cortes, Richie Harris
 * Email:   vcortes@g.hmc.edu, rkharris@g.hmc.edu
 * Date:    20 November 2019
 * 
 * Feedforward neural network for image classification
 * 
 */

`include "nn_15_node_defines.svh"

module top(input  logic     clk,
		   input  logic       pclk, reset,
		   input  logic       vsync,
		   input  logic       href,
		   input  logic       d0, d1, d2, d3, d4, d5, d6, d7,
		   input  logic       sck,
		   input  logic       sdi,
		   output logic       sdo,
		   output logic       done,
		   output logic       xclk);

	assign xclk = clk; // drive camera xclk with 40 Hz from oscillator				  
	
	logic [2047:0] 			frame;
	logic 						decimate_done;
   logic [`UINT_8-1:0]  	px_uint8;
   logic [`ADR_LEN-1:0] 	cycle, ra1;
	logic [15*16-1:0] 		classification;
				  	
	decimate dec(pclk, reset, vsync, href, d0, d1, d2, d3, d4, d5, d6, d7, decimate_done, frame);
	
	spi s(sck, sdi, sdo, done, classification);
	
	choose_pixel cp(ra1, frame, px_uint8);
    
   nn feedforward(clk, reset, decimate_done, px_uint8, cycle, ra1, classification, done);
				  
endmodule


module nn(input  logic                  clk, reset,
			 input  logic						 decimate_done,
          input  logic [`UINT_8-1:0]    px_uint8,
          output logic [`ADR_LEN-1:0]   cycle, ra1,
          output logic [15*16-1:0]      classification,
          output logic                  done);

    // wires
    logic                                we, clear;     // controls for RAM
    logic                                rd_src1;
    logic [1:0]                          rd_src2;
    logic [`HIDDEN_LAYER_WID-1:0]        rd1, rd2, rd3; // rd from weight ROMs
    logic [0:`NUM_MULTS-1] [`INT_16-1:0] result;        // wd to RAM
    logic [`RESULT_RD_WID-1:0]           prev_result;   // rd from RAM
	 logic										  captureclassification;
    
    // weight memories
    // 257 rows of 15 int16s
    w1rom h1_weights(clk, ra1, rd1);
    // 16 rows of 15 int16s
    w2rom h2_weights(clk, cycle, rd2);
    w3rom h3_weights(clk, cycle, rd3);
    
    // output layer mem
    oram result_ram(clk, we, cycle, result, prev_result);
    
    // controller
    controller c(clk, reset, decimate_done, we, cycle, ra1, rd_src1, rd_src2, clear, captureclassification);
    
    // datapath
    datapath d(clk, rd_src1, rd_src2, clear, px_uint8, rd1, rd2, rd3, prev_result, result, captureclassification, classification, done);
    
    
endmodule

module datapath(input  logic                                clk,
                input  logic                                rd_src1,
                input  logic [1:0]                          rd_src2,
                input  logic                                clear,
                input  logic [`UINT_8-1:0]                  px_uint8,
                input  logic [`HIDDEN_LAYER_WID-1:0]        rd1, rd2, rd3, 
					 input  logic [`RESULT_RD_WID-1:0]           prev_result, 
                output logic [0:`NUM_MULTS-1] [`INT_16-1:0] result,
					 input  logic 											captureclassification,
                output logic [15*16-1:0]                    classification,
					 output logic											done);
    
    logic signed [`INT_16-1:0]                  px_int16;
    logic signed [`INT_16-1:0]                  src1;
    logic signed [`HIDDEN_LAYER_WID-1:0]        src2;
    logic signed [0:`NUM_MULTS-1] [`INT_16-1:0] src2_int16; 
    logic signed [0:`NUM_MULTS-1] [`INT_32-1:0] prod, sum, activ_sum;
	 logic 													captured;
    
    // extend incoming image to int16
    // maps [0,255] uint8 to [-16,16) Q4_11 int16
    assign px_int16 = {5'b0, px_uint8, 3'b0}; 
    
    // select read sources
    /*  src1 | src2
     *  -----------
     *  img  | rd1
     *  out  | rd2
     *  out  | rd3     
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
	 
	// synchronously capture the classification when the output layer has been computed
	always_ff @(posedge clk)
		if (captureclassification & !captured) begin
			classification <= {result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7], result[8], result[9], result[10], result[11], result[12], result[13], result[14]};
			done <= 1'b1;
			captured <= 1'b1;
		end
		else if (!captureclassification) begin
			done <= 1'b0;
			captured <= 1'b0;
		end
		
endmodule

module controller(input  logic                clk, reset,
						input  logic					 decimate_done,
                  output logic                we,
                  output logic [`ADR_LEN-1:0] cycle, ra1,
                  output logic                rd_src1,
                  output logic [1:0]          rd_src2, 
                  output logic                clear,
                  output logic                captureclassification);
	 
	typedef enum logic [5:0] {RESET, 
                              MUL1, WB1, CLR1, 
                              MUL2, WB2, CLR2, 
                              MUL3, WB3, DONE} statetype;
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
            RESET: if (decimate_done)               	nextstate = MUL1;
					   else			                     	nextstate = RESET;
				MUL1:  if (cycle == `MULT_INPUT_CYCLES)   nextstate = WB1;
					   else			                     	nextstate = MUL1;
				WB1:   			                         	nextstate = CLR1;
				CLR1:				                     		nextstate = MUL2;
				MUL2:  if (cycle == `MULT_HIDDEN_CYCLES) 	nextstate = WB2;
					   else			                     	nextstate = MUL2;
				WB2:				                     		nextstate = CLR2;
				CLR2:				                     		nextstate = MUL3;
				MUL3:  if (cycle == `MULT_HIDDEN_CYCLES) 	nextstate = DONE;
					   else			                     	nextstate = MUL3;
				DONE:					                 			nextstate = DONE;
				default:				                 			nextstate = RESET;
        endcase
    end
	
    // sequential controls 
    always_ff @(posedge clk)
        case(state)
            RESET:	 begin 
                        cycle <= 0;
                        layers_done_count <= 0;
                     end
            MUL1:	    	cycle <= cycle + 1'b1;
            WB1:	 begin 
                        cycle <= 0;
                        layers_done_count <= layers_done_count + 1'b1;
                     end
            CLR1:	    	cycle <= 0; // delay to calculate final sum
            MUL2:	    	cycle <= cycle + 1'b1;           
            WB2:	 begin
                        cycle <= 0;
                        layers_done_count <= layers_done_count + 1'b1;
                     end
            CLR2:	    	cycle <= 0; 
            MUL3:	    	cycle <= cycle + 1'b1;           
            default:    cycle <= 0;
        endcase
        
	// combinational controls
    always_comb begin
		case(state)
            RESET: 	controls = 4'b0100;
            MUL1:	 	controls = 4'b0000;
            WB1:	 	controls = 4'b1010;
            CLR1:	 	controls = 4'b0110;
            MUL2:	 	controls = 4'b0010;
            WB2:	 	controls = 4'b1010;
            CLR2:	 	controls = 4'b0110;
            MUL3:	 	controls = 4'b0010;
            DONE:	 	controls = 4'b0011;
            default: controls = 4'bxxxx;
        endcase
	end	
    
	// added for synchronous w1rom
	always_comb begin
        if (state == RESET & nextstate == MUL1) begin
            ra1 = '0;
        end
        else if (state == MUL1) begin
            ra1 = cycle + 1'b1;
        end
        else begin
            ra1 = '0;
        end
   end
	 
	 
    // set controls
   assign {we, clear, input_layer_done, output_layer_done} = controls;	
	
    // assign flags
	assign rd_src1 = input_layer_done;
   assign rd_src2 = layers_done_count;
   assign captureclassification    = output_layer_done;
    
endmodule

// selects a pixel from the frame buffer to input into the neural net
module choose_pixel(input  logic [`ADR_LEN-1:0] ra1,
						  input  logic [2047:0]       frame,
						  output logic [`UINT_8-1:0]  px_uint8);
						  
	
	logic 					select;
	logic [`UINT_8-1:0]  bias;
	
	assign bias = 8'hFF;
	
	assign select = (ra1==10'd0 | ra1==10'd1);
	
	mux2 #(`UINT_8) pixelmux(frame[`UINT_8*(ra1-1)-1 -: `UINT_8], bias, select, px_uint8);
						  
endmodule


//
// --- NN Memories ---
//

// wh1rom is the only one implemented synchronously and thus actually 
// stored to memory on the FPGA.
// The rest are stored in logic elements. The complexity was
// reduced when the roms were asynchronous so we chose to implement
// as few roms into memory as possible.
module w1rom(input  logic                         clk,
             input  logic [`ADR_LEN-1:0]          a,
             output logic [`HIDDEN_LAYER_WID-1:0] rd);

    logic [`HIDDEN_LAYER_WID-1:0] ROM[`INPUT_LAYER_LEN-1:0];
    
    initial
        $readmemh("hiddenweights1.dat", ROM);
    
    always_ff @(posedge clk)
		rd <= ROM[a[`ADR_LEN-1:0]];
endmodule

module w2rom(input  logic                         clk,
             input  logic [`ADR_LEN-1:0]          a,
             output logic [`HIDDEN_LAYER_WID-1:0] rd);

    logic [`HIDDEN_LAYER_WID-1:0] ROM[`HIDDEN_LAYER_LEN-1:0];
    
    initial
        $readmemh("hiddenweights2.dat", ROM);
    
    assign rd = ROM[a[`ADR_LEN-1:0]];
endmodule


module w3rom(input  logic                         clk,
             input  logic [`ADR_LEN-1:0]          a,
             output logic [`HIDDEN_LAYER_WID-1:0] rd);

    logic [`HIDDEN_LAYER_WID-1:0] ROM[`HIDDEN_LAYER_LEN-1:0];
    
    initial
        $readmemh("outputweights.dat", ROM);
    
    assign rd = ROM[a[`ADR_LEN-1:0]];
endmodule

module oram(input  logic                      clk, we,
            input  logic [`ADR_LEN-1:0]       a,
            input  logic [`RESULT_WD_WID-1:0] wd,
            output logic [`RESULT_RD_WID-1:0] rd);

    logic [`RESULT_RD_WID-1:0] RAM[`RESULT_LEN-1:0];
    
    assign rd = RAM[a[`ADR_LEN-1:0]];
  
    always_ff @(posedge clk)
        if (we) begin
            RAM[0]  <= 16'h0800; // bias
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

module mul #(parameter WIDTH = 16)
            (input  logic signed [WIDTH-1:0]   a, b,
             output logic signed [2*WIDTH-1:0] y);
  
    assign y = (a * b) << 5; // LSL to get rid of extra integer bits
  
endmodule

module acc #(parameter WIDTH = 32)
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

//
// --- Camera modules ---
//

module decimate(input logic 				pclk, reset,
					 input logic 				vsync,
					 input logic 				href,
					 input logic 				d0, d1, d2, d3, d4, d5, d6, d7,
					 output logic 				done,
					 output logic [2047:0]  frame);
			
	logic 			y; // luminance is every other byte
	logic [19:0]   a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15;
	logic [9:0] 	rowcount;
	logic [9:0] 	colcount;
	logic [7:0] 	min;
	logic [11:0] 	vsync_count;
	 
   typedef enum {RESET, COUNT, WAIT, START, GETROW, NEWROW, WAITROW, DECIMATE, LASTROW, DONE} statetype;
   statetype state, nextstate;

	always_ff @(posedge pclk, posedge reset) begin
		if (reset)	state <= RESET;
		else        state <= nextstate;
   end
        
	// next state logic
   always_comb begin
      case(state)
						// wait for vsync pulse at beginning of new frame
         RESET: 	if (vsync)  														  		nextstate = COUNT; 
						else        														  		nextstate = RESET;
						// make sure vsync is indicating the start of a frame
			COUNT: 	if (~vsync) 														  		nextstate = RESET;
						else if (vsync_count == `T_LINE_X3)							  		nextstate = WAIT; 
						else 																	  		nextstate = COUNT;
         WAIT:  	if (~vsync) 														  		nextstate = START;
						else        														  		nextstate = WAIT;
						// wait for href to start capture
         START: 	if (href)   														  		nextstate = GETROW;
						else        														  		nextstate = START;
						// capture a row until href goes low
         GETROW:	if (~href)  														  		nextstate = NEWROW;
						else        														  		nextstate = GETROW;
						// end of row in decimated image
						// every 30 rows, shift a new decimated row into frame buffer
						// else wait for next row
			NEWROW:	if (rowcount < `CAMERA_ROWS && (rowcount % `DEC_ROWS == 0)) nextstate = DECIMATE;
						else if (rowcount == `CAMERA_ROWS)									nextstate = LASTROW;
						else			 														  		nextstate = WAITROW;
						// wait for href
         WAITROW: if (href)   														  		nextstate = GETROW;
						else			 														  		nextstate = WAITROW;
						// shift out decimated bytes into frame buffer
			DECIMATE:																		  		nextstate = WAITROW;
						// filter out bad images and shift out last decimated bytes
			LASTROW:	if (min > `MIN_THRESH)													nextstate = RESET; 
						else 																	  		nextstate = DONE;
			DONE:					 															  		nextstate = DONE;
			default:				 															  		nextstate = RESET;
		endcase
   end
						 
	// sequential image capture
	always_ff @(posedge pclk) begin
		if (state == RESET) begin
			done <= 1'b0;
			colcount <= '0;
			y <= 1'b0;
			min <= 8'b11111111;
			vsync_count <= 12'b0;
      end
		// count how many clock cycles vsync is high to make sure it is the start of a new frame
		else if (state == COUNT)	begin
			vsync_count = vsync_count + 1'b1;
		end
		// reset colcount for new row
		else if (state == WAIT) begin
			done <= 1'b0;
			colcount <= '0;
			y <= 1'b0;
      end
		// reset rowcount, clear accumulators before start of new frame
		else if (state == START) begin
			rowcount <= '0;
			{a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15} = '0;
		end
		// add chunks of 40 pixel values into each accumulator
		else if (state == GETROW) begin
         if (~y)	begin
				if 	  (colcount <   `DEC_COLS)	 a0  <= a0  + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 2*`DEC_COLS)	 a1  <= a1  + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 3*`DEC_COLS)	 a2  <= a2  + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 4*`DEC_COLS)	 a3  <= a3  + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 5*`DEC_COLS)	 a4  <= a4  + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 6*`DEC_COLS)	 a5  <= a5  + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 7*`DEC_COLS)	 a6  <= a6  + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 8*`DEC_COLS)	 a7  <= a7  + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 9*`DEC_COLS)	 a8  <= a8  + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 10*`DEC_COLS) a9  <= a9  + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 11*`DEC_COLS) a10 <= a10 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 12*`DEC_COLS) a11 <= a11 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 13*`DEC_COLS) a12 <= a12 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 14*`DEC_COLS) a13 <= a13 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < 15*`DEC_COLS) a14 <= a14 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				else if (colcount < `CAMERA_COLS) a15 <= a15 + {12'b0, {d7, d6, d5, d4, d3, d2, d1, d0}};
				colcount <= colcount + 1'b1;
			end
			y = y + 1'b1; // every other byte is the luminance
			done <= 1'b0;
      end
		// finish row, increment rowcount, reset colcount
		else if (state == NEWROW) 	begin
			rowcount <= rowcount + 1'b1;
			colcount <= 10'b0;
		end
		// every time 30 rows are read, accumulators are full.  Shift out decimated bytes to frame buffer
		else if (state == DECIMATE) begin
			frame <= {{a15[17:10], a14[17:10], a13[17:10], a12[17:10], a11[17:10], a10[17:10], a9[17:10], a8[17:10], a7[17:10], a6[17:10], a5[17:10], a4[17:10], a3[17:10], a2[17:10], a1[17:10], a0[17:10]}, frame[2047:128]};
			{a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15} = '0;
			if 	  (a0[17:10]  < min)	min <= a0[17:10];
			else if (a1[17:10]  < min)	min <= a1[17:10];
			else if (a2[17:10]  < min)	min <= a2[17:10];
			else if (a3[17:10]  < min)	min <= a3[17:10];
			else if (a4[17:10]  < min)	min <= a4[17:10];
			else if (a5[17:10]  < min)	min <= a5[17:10];
			else if (a6[17:10]  < min)	min <= a6[17:10];
			else if (a7[17:10]  < min)	min <= a7[17:10];
			else if (a8[17:10]  < min)	min <= a8[17:10];
			else if (a9[17:10]  < min)	min <= a9[17:10];
			else if (a10[17:10] < min)	min <= a10[17:10];
			else if (a11[17:10] < min)	min <= a11[17:10];
			else if (a12[17:10] < min)	min <= a12[17:10];
			else if (a13[17:10] < min)	min <= a13[17:10];
			else if (a14[17:10] < min)	min <= a14[17:10];
			else if (a15[17:10] < min)	min <= a15[17:10];
		end
		// shift out last decimated row to the frame buffer
		else if (state == LASTROW) begin
			frame <= {{a15[17:10], a14[17:10], a13[17:10], a12[17:10], a11[17:10], a10[17:10], a9[17:10], a8[17:10], a7[17:10], a6[17:10], a5[17:10], a4[17:10], a3[17:10], a2[17:10], a1[17:10], a0[17:10]}, frame[2047:128]};
		end
		// assert done
      else if (state == DONE) begin
          done <= 1'd1;
		end  
   end  		 		 
						 
endmodule

/////////////////////////////////////////////
// spi
//   SPI interface.  Shifts out the classification
//   Tricky cases to properly change sdo on negedge clk
/////////////////////////////////////////////

module spi(input  logic sck, 
               input  logic sdi,
               output logic sdo,
               input  logic done,
               input  logic [239:0] classification);

    logic sdodelayed, wasdone;
	 logic [239:0] classificationcaptured;
               
    // shift out the data.  80 scks to shift out data
    always_ff @(posedge sck)
		  if (!wasdone)	classificationcaptured = classification;
		  else				classificationcaptured = {classificationcaptured[238:0], sdi};
    
    // sdo should change on the negative edge of sck
    always_ff @(negedge sck) begin
        wasdone = done;
		  sdodelayed = classificationcaptured[238];
    end
    
    // when done is first asserted, shift out msb before clock edge
    assign sdo = (done & !wasdone) ? classification[239] : sdodelayed;
endmodule









