module tb_syn_task3();

// Your testbench goes here. Our toplevel will give up after 1,000,000 ticks.
	
	logic CLOCK_50;
  	logic [3:0] KEY;

	

	task2 dut (
   	.CLOCK_50(CLOCK_50),
    	.KEY(KEY),
    	.SW(SW),
    	.LEDR(LEDR),
    	.HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
    	.HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
    	.VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
    	.VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_CLK(VGA_CLK),
    	.VGA_X(VGA_X), .VGA_Y(VGA_Y),
    	.VGA_COLOUR(VGA_COLOUR), .VGA_PLOT(VGA_PLOT)
  	);
	
	initial CLOCK_50 = 0;
  	always #10 CLOCK_50 = ~CLOCK_50;

	initial begin
		KEY = 4'b0000;
		repeat(1) @(posedge CLOCK_50)
		KEY[3] = 1'b1;
		wait(dut.start === 1'b1);
		$display("start is 1, meaning (!done && !start) was met");
		
		wait (dut.done === 1'b1);
    		$display("done is 1 and start will be zero");
		
		KEY[3] = 1'b0;
		repeat(1) @(posedge CLOCK_50);
		assert(dut.start === 1'b0)
			$display("start is cleared by reset");
		else
			$display("reset failed to clear start, possible malfunction of reset");
	
	end
	

endmodule: tb_syn_task3
