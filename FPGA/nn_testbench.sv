 

module nn_testbench();

	logic clk, reset;
	
	logic done;
	
	logic [15*16-1:0] classification;
	
	
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
	
	
endmodule 
	