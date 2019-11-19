`include "nn_15_node_defines.svh"


// Why is classificatoin a matrix? Shouldn't it just be a number?
module top(input  logic clk, reset,
           // TODO: add input for image from decimators
           output logic [9:0] classification);
    logic [`UINT_8-1:0] img_byte;
    logic [`ADR_LEN-1:0] cycle;
    
    // adhoc input layer RAM
    // TODO: add input for image from decimators
    inputmem irom(clk, cycle, img_byte);

    nn feedforward(clk, reset, img_byte, cycle, classification);

endmodule

module nn(input  logic                clk, reset,
          input  logic [`UINT_8-1:0]  img_byte,
          output logic [`ADR_LEN-1:0] cycle,
          output logic [9:0] classification);

    // wires
    logic                         we, clear; // controls for RAM
    logic                         rd_src1;
    logic [1:0]                   rd_src2;
    logic [`HIDDEN_LAYER_WID-1:0] rd1, rd2, rd3; // rd from weights ROMs
    logic [`RESULT_WD_WID-1:0]    result;
    logic [`RESULT_RD_WID-1:0]    prev_out;
    
    // weight memories
    // 257 rows of 15 int16s
    w1rom h1_weights(clk, cycle, rd1);
    // 16 rows of 15 int16s
    w2rom h2_weights(clk, cycle, rd2);
    w3rom h3_weights(clk, cycle, rd3);
    
    // output layer mem
    oram result_ram(clk, we, cycle, result, prev_out);
    
    // controller
    controller c(clk, reset, we, cycle, rd_src1, rd_src2, clear);
    
    // datapath
    datapath d(clk, rd_src1, rd_src2, clear, img_byte, rd1, rd2, rd3, prev_out, result, classification);
    
    
endmodule

// where is the bias set?
module datapath(input  logic                         clk,
                input  logic                         rd_src1,
                input  logic [1:0]                   rd_src2,
                input  logic                         clear,
                input  logic [`UINT_8-1:0]           img_byte,
                input  logic [`HIDDEN_LAYER_WID-1:0] rd1, rd2, rd3, prev_out,
                output logic [`RESULT_WD_WID-1:0]    result,
                output logic [9:0]         classification);
    
    logic [`INT_16-1:0] img_int16;
    logic signed [`INT_16-1:0] src1;
    logic signed [`HIDDEN_LAYER_WID-1:0] src2;
    
    // extend incoming image to int16, convert to Q15
    assign img_int16 = {1'b0, img_byte, 7'b0}; // already effectively shifts by 8, between 0 and 1
    //assign img_int16_div = img_int16 >> 8; // TODO: change divisor
    
    // select read sources
    /*  src1 | src2
     *  -----------
     *  img  | rd1
     *  out  | rd2
     *  ...
     *  out  | rdN
     */ 
     mux2 #(`INT_16) src1mux(img_int16, prev_out, rd_src1, src1);
     mux3 #(`HIDDEN_LAYER_WID) src2mux(rd1, rd2, rd3, rd_src2, src2);
    
    // generate datapath wires
    genvar gi;
    generate 
        for (gi=1 ; gi<`NUM_MULTS+1; gi++) begin : gw // generate wires
            logic signed [`INT_16-1:0] src2b; // added signed
            assign src2b = src2[(`INT_16*gi-1) -: `INT_16];
           // assign rd2b = rd2[(8*gi-1) -: 8];
        end
    endgenerate
    
    /*
    genvar gj;
    generate 
        for (gj=0; gj<`NUM_MULTS; gj++) begin : dpsl // generate datapath slice
            // wires
            //logic [`INT_32-1:0] trunc_prod;
				logic signed [`INT_32-1:0] sum, activ_sum; // added signed
            logic signed [`INT_32-1:0] prod; // changed to INT_32

            // mux for picking image or rd1, rd1 or rd2
            //mux2 #(8) mul_sel0(gw[gj+1].rd1b, img_byte, rd_src, a_mul);
            //mux2 #(8) mul_sel1(gw[gj+1].rd2b, gw[gj+1].rd1b, rd_src, b_mul);
             
            // mul
            assign prod = src1 * gw[gj+1].src2b;
            //assign trunc_prod = prod[31:16];
            
            // acc
            acc #(`INT_32) lc(clk, clear, prod, sum); // changed to INT_32
            
            // neg_comp
            neg_comp #(`INT_32) relu(sum, activ_sum); // changed to INT_32
        end
    endgenerate */
	 
	 logic [`INT_32-1:0] activ_sum1;
	 logic [`INT_32-1:0] activ_sum2;
	 logic [`INT_32-1:0] activ_sum3;
	 logic [`INT_32-1:0] activ_sum4;
	 logic [`INT_32-1:0] activ_sum5;
	 logic [`INT_32-1:0] activ_sum6;
	 logic [`INT_32-1:0] activ_sum7;
	 logic [`INT_32-1:0] activ_sum8;
	 logic [`INT_32-1:0] activ_sum9;
	 logic [`INT_32-1:0] activ_sum10;
	 logic [`INT_32-1:0] activ_sum11;
	 logic [`INT_32-1:0] activ_sum12;
	 logic [`INT_32-1:0] activ_sum13;
	 logic [`INT_32-1:0] activ_sum14;
	 logic [`INT_32-1:0] activ_sum15;
	 
	 dpsl d1(clk, clear, src1, gw[1].src2b, activ_sum1);
	 dpsl d2(clk, clear, src1, gw[2].src2b, activ_sum2);
	 dpsl d3(clk, clear, src1, gw[3].src2b, activ_sum3);
	 dpsl d4(clk, clear, src1, gw[4].src2b, activ_sum4);
	 dpsl d5(clk, clear, src1, gw[5].src2b, activ_sum5);
	 dpsl d6(clk, clear, src1, gw[6].src2b, activ_sum6);
	 dpsl d7(clk, clear, src1, gw[7].src2b, activ_sum7);
	 dpsl d8(clk, clear, src1, gw[8].src2b, activ_sum8);
	 dpsl d9(clk, clear, src1, gw[9].src2b, activ_sum9);
	 dpsl d10(clk, clear, src1, gw[10].src2b, activ_sum10);
	 dpsl d11(clk, clear, src1, gw[11].src2b, activ_sum11);
	 dpsl d12(clk, clear, src1, gw[12].src2b, activ_sum12);
	 dpsl d13(clk, clear, src1, gw[13].src2b, activ_sum13);
	 dpsl d14(clk, clear, src1, gw[14].src2b, activ_sum14);
	 dpsl d15(clk, clear, src1, gw[15].src2b, activ_sum15);
	 
	 // TODO: Add bias
	 assign result = {activ_sum15[15:0], 
                     activ_sum14[15:0], 
                     activ_sum13[15:0],
                     activ_sum12[15:0], 
                     activ_sum11[15:0], 
                     activ_sum10[15:0],
                     activ_sum9[15:0], 
                     activ_sum8[15:0], 
                     activ_sum7[15:0], 
                     activ_sum6[15:0], 
                     activ_sum5[15:0], 
                     activ_sum4[15:0], 
                     activ_sum3[15:0], 
                     activ_sum2[15:0], 
                     activ_sum1[15:0]};
    
	 /*
    assign result = {dpsl[15].activ_sum, 
                     dpsl[14].activ_sum, 
                     dpsl[13].activ_sum,
                     dpsl[12].activ_sum, 
                     dpsl[11].activ_sum, 
                     dpsl[10].activ_sum,
                     dpsl[9].activ_sum, 
                     dpsl[8].activ_sum, 
                     dpsl[7].activ_sum, 
                     dpsl[6].activ_sum, 
                     dpsl[5].activ_sum, 
                     dpsl[4].activ_sum, 
                     dpsl[3].activ_sum, 
                     dpsl[2].activ_sum, 
                     dpsl[1].activ_sum, 
                     dpsl[0].activ_sum}; */
    
	 // TODO: assign classification
    assign classification = 10'b0;
       
endmodule

module dpsl(input logic clk, clear,
				input logic signed [`INT_16-1:0] src1,
				input logic signed [`INT_16-1:0] src2,
				output logic signed [`INT_32-1:0] activ_sum);


				logic signed [`INT_32-1:0] sum; // added signed
            logic signed [`INT_32-1:0] prod; // changed to INT_32

            // mux for picking image or rd1, rd1 or rd2
            //mux2 #(8) mul_sel0(gw[gj+1].rd1b, img_byte, rd_src, a_mul);
            //mux2 #(8) mul_sel1(gw[gj+1].rd2b, gw[gj+1].rd1b, rd_src, b_mul);
             
            // mul
            assign prod = src1 * src2;
            //assign trunc_prod = prod[31:16];
            
            // acc
            acc #(`INT_32) lc(clk, clear, prod, sum); // changed to INT_32
            
            // neg_comp
            neg_comp #(`INT_32) relu(sum, activ_sum); // changed to INT_32
				

endmodule

//TODO: Make this an FSM.  Cycle should stay at zero for 1 more clk cycle after reset
module controller(input  logic                clk, reset,
                  output logic                we,
                  output logic [`ADR_LEN-1:0] cycle,
                  output logic                rd_src1,
                  output logic [1:0]          rd_src2, 
                  output logic                clear);

    //typedef enum {RESET, MULTIPLY, TRANSITION, DONE} statetype;
    //statetype state, nextstate;
    
    // flags
    logic input_layer_done, hidden_layer_done;
    logic [1:0] layers_done_count;
      
    always_ff @(posedge clk, posedge reset)
        if (reset) begin
            cycle <= 0;
            we <= 0;
            clear <= 1;
            input_layer_done <= 0;
            hidden_layer_done <= 0;
            layers_done_count <= 0;
        end
        else if (layers_done_count == `NUM_LAYERS) begin
            cycle <= 0;
            clear <= 1;
        end
        // reset when cycle == 256 for input layer
        else if (cycle == `MULT_INPUT_CYCLES) begin 
            cycle <= 0;
            we <= 1;
            input_layer_done <= 1;
            layers_done_count <= layers_done_count + 1'b1;
        end
        else if (input_layer_done) begin 
            cycle <= 0; // delay to calculate final sum
            we <= 0;
            clear <= 1;
        end        
        // reset when cycle == 9 for hidden layer
        else if ((cycle == `MULT_HIDDEN_CYCLES) & input_layer_done) begin
            cycle <= 0;
            we <= 1;
            hidden_layer_done <= 1;
            layers_done_count <= layers_done_count + 1'b1;
        end
        else if (hidden_layer_done) begin 
            cycle <= 0; // delay to calculate final sum
            we <= 0;
            clear <= 1;
            hidden_layer_done <= 0;
        end   
        else begin       
            cycle <= cycle + 1'b1;   
            clear <= 0;
        end
        
    assign rd_src1 = input_layer_done; //TODO: make better choice
    assign rd_src2 = layers_done_count;
    
endmodule

//
// --- NN Memories ---
//

// need to make the specific memories
// initial   $readmemh("sbox.txt", sbox); // use each .dat from py script

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

/*
module w4rom(input  logic                         clk,
             input  logic [`ADR_LEN-1:0]          a, // TODO: remove this hack
             output logic [`HIDDEN_LAYER_WID-1:0] rd);

  logic [`HIDDEN_LAYER_WID-1:0] ROM[`HIDDEN_LAYER_LEN-1:0];

  initial
    $readmemh("hiddenweights4.dat", ROM);
  
  assign rd = ROM[a[`ADR_LEN-1:0]]; // changed the 2 to 0
endmodule */

module oram(input  logic                      clk, we,
            input  logic [`ADR_LEN-1:0]       a,
            input  logic [`RESULT_WD_WID-1:0] wd,
            output logic [`RESULT_RD_WID-1:0] rd);

  logic [`RESULT_RD_WID-1:0] RAM[`RESULT_LEN-1:0];

  assign rd = RAM[a[`ADR_LEN-1:0]]; // changed the 2 to 0
  
  always_ff @(posedge clk)
    if (we) begin
        RAM[0]  <= 16'h0; 
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
            (input  logic [WIDTH-1:0] a, b,
             output logic [2*WIDTH-1:0] y);

  assign y = a * b;
endmodule

// added signed
module acc #(parameter WIDTH = 8)
            (input  logic            clk, reset,
             input  logic signed [WIDTH-1:0] d, 
             output logic signed [WIDTH-1:0] sum);

  always_ff @(posedge clk, posedge reset)
    if (reset) sum <= 0;
    else       sum <= sum + d;
endmodule

// added signed
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