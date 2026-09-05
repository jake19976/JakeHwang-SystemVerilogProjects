module fillscreen(input logic clk, input logic rst_n, input logic [2:0] colour,
                  input logic start, output logic done,
                  output logic [7:0] vga_x, output logic [6:0] vga_y,
                  output logic [2:0] vga_colour, output logic vga_plot);
     // fill the screen

	logic [7:0] x_state, x_next_state;
	logic [6:0] y_state, y_next_state;
	logic plot, next_plot;
	logic done1, next_done;
		
		always_comb begin
			x_next_state = x_state;
			y_next_state = y_state;
			next_plot = 1'b0;
			next_done = 1'b0;
		
			if(start) begin
				next_done = 1'b0;
				next_plot = 1'b1;
				
				if(x_state==8'd159) begin  // when x reaches 159, next x goes to 0, and if y is 119(all filled),
					x_next_state = 8'd0;  //then done becomes 1 and plot becomes 0. If y is not 119, then 
					if(y_state==7'd119) begin // y is incremented by 1(move on to the next row)
						y_next_state = 7'd119;
						next_done = 1'b1;
						next_plot = 1'b0;
					end 
					else
						y_next_state = y_state+1'b1;
				end 
				else //if x haven't reached 159, x is incremented by 1(will do this until x reaches 159)
					x_next_state = x_state+1'b1;
			end
			else begin //if start is 0, filling process stops and everything goes back to zero
				x_next_state = 8'd0;
				y_next_state = 7'd0;
				next_plot = 1'b0;
				next_done = 1'b0;
			end
		end

		always_ff @(posedge clk) begin
			if(!rst_n) begin
				x_state <= 8'd0;
				y_state <= 7'd0;
				plot <= 1'b0;
				done1 <= 1'b0;
			end
			else begin
				x_state <= x_next_state;
				y_state <= y_next_state;
				plot <= next_plot;
				done1 <= next_done;
			end
		end
		
		assign vga_x = x_state;
		assign vga_y = y_state;
		assign vga_colour = x_state %8;
		assign vga_plot = plot;
		assign done = done1;
endmodule
			

