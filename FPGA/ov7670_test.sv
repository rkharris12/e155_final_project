// Richie Harris and Veronica Cortes
// rkharris@g.hmc.edu

`include "nn_15_node_defines.svh"

module ov7670_test(input logic clk,
			     input logic pclk, reset,
				  input logic vsync,
				  input logic href,
				  input logic d0, d1, d2, d3, d4, d5, d6, d7,
				  input logic sck,
				  input logic sdi,
				  output logic sdo,
				  output logic done,
				  output logic xclk);

	assign xclk = clk; // drive camera xclk with 40 Hz from oscillator
				  
	//logic [(8*100-1):0] row;
	logic [2047:0] frame;
				  
	//capture_row cr(pclk, reset, vsync, href, d0, d1, d2, d3, d4, d5, d6, d7, done, row);
	decimate dec(pclk, reset, vsync, href, d0, d1, d2, d3, d4, d5, d6, d7, done, frame);
	spi s(sck, sdi, sdo, done, frame); 
				  
endmodule
		
		
//// capture 100 pixels of grayscale pixels from a single row of a frame
//module capture_row(input logic pclk, reset,
//						 input logic vsync,
//						 input logic href,
//						 input logic d0, d1, d2, d3, d4, d5, d6, d7,
//						 output logic done,
//						 output logic [(8*100-1):0] row); // For now row is 100 pixels.  1 byte per pixel, 640 pixels per row, 480 rows per frame for VGA
//    
//	 logic [9:0] pixelcount;
//	 logic y;
//	 
//    typedef enum {S0, S1, S2, S3, S4} statetype;
//    statetype state, nextstate;
//				  
//
//	always_ff @(posedge pclk, posedge reset) begin
//		if (reset) state <= S0;
//        else       state <= nextstate;
//    end
//        
//    always_comb begin
//        case(state)
//            S0:    if (vsync)  nextstate = S1;
//                   else        nextstate = S0;
//            S1:    if (~vsync) nextstate = S2;
//                   else        nextstate = S1;
//            S2:    if (href)   nextstate = S3;
//                   else        nextstate = S2;
//            S3:    if (pixelcount==10'd99)  nextstate = S4;
//                   else        nextstate = S3;
//            S4:                nextstate = S4;
//            default:           nextstate = S0;
//        endcase
//    end
//    
//    always_ff @(posedge pclk) begin
//		  if (state == S3) begin
//            if (~y)	begin
//					row <= {row[(8*100-1-8):0], {d7, d6, d5, d4, d3, d2, d1, d0}};
//					pixelcount <= pixelcount + 1'b1;
//				end
//				y = y + 1'b1;
//				done <= 1'b0;
//        end
//        else if (state == S4) begin
//            done <= 1'd1;
//        end 
//        else begin
//            row <= '0;
//				done <= 1'b0;
//				pixelcount <= '0;
//				y <= 1'b0;
//        end
//    end   
//	  
//endmodule 



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
			frame <= {frame[1919:0], {a0[17:10], a1[17:10], a2[17:10], a3[17:10], a4[17:10], a5[17:10], a6[17:10], a7[17:10], a8[17:10], a9[17:10], a10[17:10], a11[17:10], a12[17:10], a13[17:10], a14[17:10], a15[17:10]}};
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
			frame <= {frame[1919:0], {a0[17:10], a1[17:10], a2[17:10], a3[17:10], a4[17:10], a5[17:10], a6[17:10], a7[17:10], a8[17:10], a9[17:10], a10[17:10], a11[17:10], a12[17:10], a13[17:10], a14[17:10], a15[17:10]}};
		end
		// assert done
      else if (state == DONE) begin
          done <= 1'd1;
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











