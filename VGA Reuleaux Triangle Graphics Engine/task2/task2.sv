module task2(input logic CLOCK_50, input logic [3:0] KEY,
             input logic [9:0] SW, output logic [9:0] LEDR,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [7:0] VGA_R, output logic [7:0] VGA_G, output logic [7:0] VGA_B,
             output logic VGA_HS, output logic VGA_VS, output logic VGA_CLK,
             output logic [7:0] VGA_X, output logic [6:0] VGA_Y,
             output logic [2:0] VGA_COLOUR, output logic VGA_PLOT);

    // instantiate and connect the VGA adapter and your module
	logic [7:0] x;
	logic [6:0] y;
	logic [2:0] colour;
	logic done;
	logic plot;
	logic start;
	
	fillscreen fs(.clk(CLOCK_50), .rst_n(KEY[3]), .start(start), .done(done), .vga_x(x), .vga_y(y), 
	.vga_colour(colour), .vga_plot(plot));	
	
	vga_adapter adapter(.resetn(KEY[3]), .clock(CLOCK_50), .colour(colour), .x(x), .y(y), .plot(plot), .VGA_R(VGA_R),
	.VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK(VGA_BLANK), .VGA_SYNC(VGA_SYNC), .VGA_CLK(VGA_CLK));

	always_ff @(posedge CLOCK_50) begin
        if(!KEY[3])
            start <= 1'b0;
        else begin
        if(!done && !start)
	start <= 1'b1;
	if (done)
	start <= 1'b0;
	end
end
		

endmodule: task2
