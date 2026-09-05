module tb_rtl_circle();
	//input
	logic clk;
  	logic rst_n;
  	logic start;
  	logic [7:0] centre_x;
	logic[6:0] centre_y;
  	logic [7:0] offset_x, offset_y;
	logic[7:0] radius;
	logic[2:0] colour;
	//output
	logic [7:0]  vx, vy;
  	logic done;
	logic[2:0] vga_colour;
	logic[7:0] vga_x;
	logic[6:0] vga_y;
	logic vga_plot;

	
	
	circle dut (
	.clk(clk),
	.rst_n(rst_n),
	.start(start),
	.centre_x(centre_x),
	.centre_y(centre_y),
	.done(done),
	.colour(colour),
	.radius(radius),
	.vga_x(vga_x),
	.vga_y(vga_y),
	.vga_colour(vga_colour),
	.vga_plot(vga_plot)
  	);

	always #10 clk = ~clk;

	logic [5:0] seq1[0:8];
	
	initial begin
	
	clk = 1'b0;
	rst_n = 1'b0;
	start = 1'b0;
	centre_x = 8'd80;
	centre_y = 7'd60;
	dut.offset_x = 8'b0;
	dut.offset_y = 8'b0;
	seq1[0] = dut.O1;
	seq1[1] = dut.O2;
	seq1[2] = dut.O4;
	seq1[3] = dut.O3;
	seq1[4] = dut.O5;
	seq1[5] = dut.O6;
	seq1[6] = dut.O8;
	seq1[7] = dut.O7;
	seq1[8] = dut.CALC;

	
	repeat (1) @(posedge clk);
	rst_n = 1'b1;
	repeat (1) @(posedge clk); //reset done
	
	assert(dut.state == dut.IDLE) //after reset, state==IDLE
		$display("state == IDLE, so pass");
	else
		$error("After reset, state != idle");
	
	repeat (1) @(posedge clk);
	start = 1'b1;  //start held at high
	repeat (1) @(posedge clk);
	dut.offset_x = 8'd40;

	
	//check if state moves properly from 01 to CALC
	for (int i=0; i<9; i++) begin
		repeat (1) @(posedge clk);
		assert(dut.state == seq1[i])
		$display("state successfully moved to next stage(%0d), so passed", i);
		else
		$error("state failed to move to next stage(%0d), so failed", i);
	end
	
	end
	

endmodule: tb_rtl_circle
