// Richie Harris and Veronica Cortes
// rkharris@g.hmc.edu


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



module decimate(input logic pclk, reset,
						 input logic vsync,
						 input logic href,
						 input logic d0, d1, d2, d3, d4, d5, d6, d7,
						 output logic done,
						 output logic [2047:0] frame);
						 
			
	logic y;
	logic [19:0] a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15;
	//logic [7:0] avg0, avg1, avg2, avg3, avg4, avg5, avg6, avg7, avg8, avg9, avg10, avg11, avg12, avg13, avg14, avg15;
	logic [9:0] rowcount;
	logic [9:0] colcount;
	
	logic [7:0] min;
	logic [11:0] vsync_count;
	
   typedef enum {S0, S1, S2, S3, S4, S5, S6, S7, S8, SC} statetype;
   statetype state, nextstate;
				  

	always_ff @(posedge pclk, posedge reset) begin
		if (reset)	state <= S0;
      else        state <= nextstate;
    end
        
    always_comb begin
        case(state)
            S0:    if (vsync)  nextstate = SC; //maybe count to make sure it is a real vsync
                   else        nextstate = S0;
				SC:	 if (~vsync)			nextstate = S0;
						 else if (vsync_count == 12'd2000)	nextstate = S1;
						 else nextstate = SC;
            S1:    if (~vsync) nextstate = S2;
                   else        nextstate = S1;
            S2:    if (href)   nextstate = S3;
						 //else if(vsync)	nextstate = S1;
                   else        nextstate = S2;
            S3:    if (~href)  nextstate = S4;
						 //else if(vsync)	nextstate = S1;
                   else        nextstate = S3;
				S4:	 if(vsync)	nextstate = SC;
						 else if (colcount == 10'd30)		 		 nextstate = S6;
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
						 //else if(vsync)	nextstate = S0;
						 else			 nextstate = S5;
				S6:					 //if(vsync)	nextstate = S1;
										 //else nextstate = S5;
										 nextstate = S5;
				S7:					 //if(vsync)	nextstate = S1;
										 //else nextstate = S8;
										 if (min > 8'd100)	nextstate = S0;
										 else nextstate = S8;
										 //nextstate = S8;
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
				//frame <= {frame[1919:0], {avg15, avg14, avg13, avg12, avg11, avg10, avg9, avg8, avg7, avg6, avg5, avg4, avg3, avg2, avg1, avg0}};
				frame <= {frame[1919:0], {a0[17:10], a1[17:10], a2[17:10], a3[17:10], a4[17:10], a5[17:10], a6[17:10], a7[17:10], a8[17:10], a9[17:10], a10[17:10], a11[17:10], a12[17:10], a13[17:10], a14[17:10], a15[17:10]}};
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
				if (a0[17:10] < min)			min <= a0[17:10];
				else if (a1[17:10] < min)	min <= a1[17:10];
				else if (a2[17:10] < min)	min <= a2[17:10];
				else if (a3[17:10] < min)	min <= a3[17:10];
				else if (a4[17:10] < min)	min <= a4[17:10];
				else if (a5[17:10] < min)	min <= a5[17:10];
				else if (a6[17:10] < min)	min <= a6[17:10];
				else if (a7[17:10] < min)	min <= a7[17:10];
				else if (a8[17:10] < min)	min <= a8[17:10];
				else if (a9[17:10] < min)	min <= a9[17:10];
				else if (a10[17:10] < min)	min <= a10[17:10];
				else if (a11[17:10] < min)	min <= a11[17:10];
				else if (a12[17:10] < min)	min <= a12[17:10];
				else if (a13[17:10] < min)	min <= a13[17:10];
				else if (a14[17:10] < min)	min <= a14[17:10];
				else if (a15[17:10] < min)	min <= a15[17:10];
		  end
		  else if (state == S7) begin
				//frame <= {frame[1919:0], {avg15, avg14, avg13, avg12, avg11, avg10, avg9, avg8, avg7, avg6, avg5, avg4, avg3, avg2, avg1, avg0}};
				frame <= {frame[1919:0], {a0[17:10], a1[17:10], a2[17:10], a3[17:10], a4[17:10], a5[17:10], a6[17:10], a7[17:10], a8[17:10], a9[17:10], a10[17:10], a11[17:10], a12[17:10], a13[17:10], a14[17:10], a15[17:10]}};
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
				
				min <= 8'b11111111;
				vsync_count <= 12'b0;
        end
		  else if (state == S1) begin
				done <= 1'b0;
				rowcount <= '0;
				y <= 1'b0;
        end
		  else if (state == SC)	begin
				vsync_count = vsync_count + 1'b1;
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











