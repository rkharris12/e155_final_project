/*
 * Authors: Veronica Cortes, Richie Harris
 * Email:   vcortes@g.hmc.edu, rkharris@g.hmc.edu
 * Date:    20 November 2019
 * 
 * Feedforward neural network for image classification
 * 
 */

`include "nn_15_node_defines.svh"

module top(input  logic       clk, reset,
           output logic [15*16-1:0] classification,
           output logic       done);
           // TODO: add input for image from decimators
           // TODO: finish done signal
           
    logic [`UINT_8-1:0]  px_uint8;
    logic [`ADR_LEN-1:0] cycle, ra1;
    
    // adhoc input layer RAM
    // TODO: add input for image from decimators
    inputmem irom(clk, ra1, px_uint8);

    nn feedforward(clk, reset, px_uint8, cycle, ra1, classification, done);

endmodule

module nn(input  logic                  clk, reset,
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
    controller c(clk, reset, we, cycle, ra1, rd_src1, rd_src2, clear, captureclassification);
    
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
					 input  logic											captureclassification,
                output logic [15*16-1:0]                    classification,
					 output logic 											done);
    
    logic signed [`INT_16-1:0]                  px_int16;
    logic signed [`INT_16-1:0]                  src1;
    logic signed [`HIDDEN_LAYER_WID-1:0]        src2;
    logic signed [0:`NUM_MULTS-1] [`INT_16-1:0] src2_int16; 
    logic signed [0:`NUM_MULTS-1] [`INT_32-1:0] prod, sum, activ_sum;
    
    // extend incoming image to int16 and convert to Q15
    // maps [0,255] uint8 to [-8,8) Q3_12 int16
    assign px_int16 = {4'b0, px_uint8, 4'b0}; 
    
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
    
	 logic captured;
	 
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
                  output logic                we,
                  output logic [`ADR_LEN-1:0] cycle, ra1,
                  output logic                rd_src1,
                  output logic [1:0]          rd_src2, 
                  output logic                clear,
                  output logic                captureclassification);
	 
	typedef enum logic [5:0] {RESET, 
                              MUL1, WB1, CLR1, 
                              MUL2, WB2, CLR2, 
                              MUL3, DONE} statetype;
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
            RESET: if (!reset)                       nextstate = MUL1;
					   else			                     nextstate = RESET;
				MUL1:  if (cycle == `MULT_INPUT_CYCLES)  nextstate = WB1;
					   else			                     nextstate = MUL1;
				WB1:   			                         nextstate = CLR1;
				CLR1:				                     nextstate = MUL2;
				MUL2:  if (cycle == `MULT_HIDDEN_CYCLES) nextstate = WB2;
					   else			                     nextstate = MUL2;
				WB2:				                     nextstate = CLR2;
				CLR2:				                     nextstate = MUL3;
				MUL3:  if (cycle == `MULT_HIDDEN_CYCLES) nextstate = DONE;
					   else			                     nextstate = MUL3;
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
            default:    cycle <= 0;
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
            DONE:	 controls = 4'b0011;
            default: controls = 4'bxxxx;
        endcase
	end	
	
	
    always_comb begin
        if (state == RESET & nextstate == MUL1) begin // added for synchronous w1rom
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

//
// --- NN Memories ---
//

module inputmem(input  logic                clk, 
                input  logic [`ADR_LEN-1:0] a,
                output logic [`UINT_8-1:0]  rd);

    logic [`UINT_8-1:0] ROM[`INPUT_LAYER_LEN-1:0];
    
    initial
        $readmemh("inputlayer.dat", ROM);
    
    always_ff @(posedge clk)
		rd <= ROM[a[`ADR_LEN-1:0]]; // changed the 2 to 0
endmodule

module w1rom(input  logic                         clk,
             input  logic [`ADR_LEN-1:0]          a,
             output logic [`HIDDEN_LAYER_WID-1:0] rd);

    logic [`HIDDEN_LAYER_WID-1:0] ROM[`INPUT_LAYER_LEN-1:0];
    
    initial
        $readmemh("hiddenweights1.dat", ROM);
    
    always_ff @(posedge clk)
		rd <= ROM[a[`ADR_LEN-1:0]]; // changed the 2 to 0
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
            RAM[0]  <= 16'h1000; // bias
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
  
    assign y = (a * b) << 4; // LSL to get rid of extra integer bits
  
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

