
module tb_rtl_fillscreen;

    logic clk, rst_n, start;
    logic [2:0] colour;
    logic done;
    logic [7:0] vga_x;
    logic [6:0] vga_y;
    logic [2:0] vga_colour;
    logic vga_plot;

    fillscreen dut (
        .clk(clk),
        .rst_n(rst_n),
        .colour(colour),
        .start(start),
        .done(done),
        .vga_x(vga_x),
        .vga_y(vga_y),
        .vga_colour(vga_colour),
        .vga_plot(vga_plot)
    );

	initial clk = 0;
	always #10 clk = ~clk;


	initial begin
		rst_n = 0;
		start = 0;
		repeat(3) @(posedge clk);
		rst_n = 1'b1;
		start = 1'b1;
		
		for (int row = 0; row < 120; row++) begin
			repeat(160) @(posedge clk); //1 cycle
			assert(vga_x==8'd159 &&  vga_y==row)
				$display("vga_x=159, vga_y=%0d", row); 
			 else 
				$error("at the end of one cycle, vga_x is 159 and y=%0d, you got x=%0d, y=%0d", row, vga_x, vga_y);
		end
		repeat(1) @(posedge clk); //added since need a time for done to be 1 after the for loop
		assert(done) 
			$display("done=1");	
		else
			$error("done should be 1 after the full 19210 cycle");
	
		repeat(1) @(posedge clk); //after filling the screen, start should be zero
		start = 1'b0;
		assert(!start) 
			$display("start is zero at the end");
		else
			$error("at the end, start should be zero");
	end
				
endmodule: tb_rtl_fillscreen
