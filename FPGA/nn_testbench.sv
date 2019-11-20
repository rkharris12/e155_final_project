`include "nn_15_node_defines.svh" 

module nn_testbench();

	logic clk, reset, done;
	
	logic [0:9] classification;
	
	
	// instantiate device under test
	top dut(clk, reset, classification, done);
	
	//generate clock
	always
		begin
			clk = 1; #5; clk = 0; #5;
		end
		
	// at start of test, pulse reset
	
	initial
		begin
			reset = 1; #22; reset = 0;
		end
        
    // check results
    always @(negedge clk) begin
        if(done) begin
            $display("Simulation succeeded");
            $stop;
        end
    end	
	
endmodule 
	