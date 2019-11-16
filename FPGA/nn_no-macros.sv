module top(input  logic clk, reset,
           output logic [7:0] classification[9:0]

);
    logic [7:0] dummy;
    // adhoc input layer RAM
    mem #(8, 257) input_layer(clk, 0, cycle, dummy, img_byte); // TODO: remove we, wd
    nn ffnn(clk, reset, img_byte, cycle, classification);

endmodule

module nn(input  logic        clk, reset,
          input  logic [7:0]  img_byte,
          output logic [10:0] cycle,
          output logic [7:0]  classification[9:0]
);

    // wires
    logic we, rd_src, acc_clr;
    logic [240-1:0] dummy;
    
    // weight memories
    // 257 rows of 30, 8b numbers
    mem #(240, 257) input_weights(clk, 0, cycle, dummy, rd1); // TODO: implement write to mem
    // 10 rows of 30, 8b numbers
    mem #(240, 10) output_weights(clk, 0, cycle, dummy, rd2);
    
    // controller
    controller c(clk, reset, cycle, we, acc_src, acc_clr, a);
    
    // datapath
    datapath d(clk, rd_src, acc_clr, img_byte, rd1, rd2, wd, classification);
    
    
endmodule

module datapath(input  logic                        clk,
                input  logic                        rd_src, acc_clr,
                input  logic [7:0]                  img_byte,
                input  logic [240-1:0] rd1, rd2,
                output logic [240-1:0] wd,
                output logic [7:0]                  classification[9:0]
);

    genvar gi;
    generate 
        for (gi=1; gi<31; gi++) begin : gw // generate wires
            logic [7:0] rd1b, rd2b;
            assign rd1b = rd1[(8*gi-1) -: 8];
            assign rd2b = rd2[(8*gi-1) -: 8];
        end
    endgenerate
    
    genvar gj;
    generate 
        for (gj=0; gj<30; gj++) begin : dp // generate datapath
            // wires
            logic [7:0] a_mul, b_mul, sum, act_sum;
            logic [15:0] prod;
            // mux for picking image or rd1, rd1 or rd2
            mux2 #(8) mul_sel0(gw[gj+1].rd1b, img_byte, rd_src, a_mul);
            mux2 #(8) mul_sel1(gw[gj+1].rd2b, gw[gj+1].rd1b, rd_src, b_mul);
            // mul
            //mul #(8) matmul(a_mul, b_mul, prod); // TODO: fix mult?
            assign prod = a_mul * b_mul;
            // acc
            acc #(8) lc(clk, acc_clr, prod[7:0], sum); // TODO: fix mult
            // neg_comp
            neg_comp #(8) relu(sum, act_sum);
        end
    endgenerate
    
    //TODO: implement wd from act_sum
    
    assign classification = {dp[9].act_sum, dp[8].act_sum, dp[7].act_sum, dp[6].act_sum, dp[5].act_sum, dp[4].act_sum, dp[3].act_sum, dp[2].act_sum, dp[1].act_sum, dp[0].act_sum}; 
    

endmodule

module controller(input  logic                        clk, reset,
                  output logic [10:0]                 cycle,
                  output logic                        we, rd_src, acc_clr,
                  output logic [240-1:0] a // TODO: remove cycle or a
);

    logic input_layer_done, hidden_layer_done;  
      
    always_ff @(posedge clk, posedge reset)
        if (reset) 
            cycle <= 0;
        // reset when cycle == 256 for input layer
        else if (cycle == 11'd256) begin 
            cycle <= 0;
            input_layer_done <= 1;
        end
        // reset when cycle == 9 for hidden layer
        else if ((cycle == 11'd9) & input_layer_done) begin
            cycle <= 0;
            hidden_layer_done <= 1;
        end
        // TODO: state for done?
        else       
            cycle <= cycle + 1;   
        
    always_comb begin
        we = cycle == 11'd256;
        a = cycle; // TODO: pad with zeros to right length
        rd_src = ~input_layer_done; //TODO: make better choice
        acc_clr = ((cycle == 11'd256) | ((cycle == 11'd9) & input_layer_done));
    end
    
endmodule

//
// --- NN-specific Gates ---
//

// need to make the specific memories
// initial   $readmemh("sbox.txt", sbox); // use each .dat from py script

module mem #(parameter WIDTH = 8, LENGTH = 8)
            (input  logic              clk, we,
             input  logic [LENGTH-1:0] a, // TODO: remove this hack
             input  logic [WIDTH-1:0]  wd,
             output logic [WIDTH-1:0]  rd
);

  logic [WIDTH-1:0] RAM[LENGTH-1:0];

  assign rd = RAM[a[WIDTH-1:0]]; // changed the 2 to 0

  always_ff @(posedge clk)
    if (we) RAM[a[WIDTH-1:0]] <= wd;
endmodule

module mul #(parameter WIDTH = 8)
            (input  logic [WIDTH-1:0] a, b,
             output logic [2*WIDTH-1:0] y
);

  assign y = a * b;
endmodule

module acc #(parameter WIDTH = 8)
            (input  logic             clk, reset,
             input  logic [WIDTH-1:0] d, 
             output logic [WIDTH-1:0] sum);

  always_ff @(posedge clk, posedge reset)
    if (reset) sum <= 0;
    else       sum <= sum + d;
endmodule

module neg_comp #(parameter WIDTH = 8)
                 (input  logic [WIDTH-1:0] x,
                  output logic [WIDTH-1:0] y);

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