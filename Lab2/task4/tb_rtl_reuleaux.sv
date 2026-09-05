

module tb_rtl_reuleaux();

  	logic clk;
  	logic rst_n;
  	logic [2:0] colour;
  	logic [7:0] centre_x, diameter;
  	logic [6:0] centre_y;
  	logic start;

  	logic done;                
  	logic [7:0] vga_x;
  	logic [6:0] vga_y;
  	logic [2:0] vga_colour;
  	logic vga_plot;

  
  	reuleaux dut (
    	.clk(clk),
    	.rst_n(rst_n),
    	.colour(colour),
    	.centre_x(centre_x),
    	.centre_y(centre_y),
    	.diameter(diameter),
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
	colour    = 3'b010;
	centre_x  = 8'd80;
    	centre_y  = 7'd60;
    	diameter  = 8'd80;
    	start     = 1'b0;
	end

	initial begin
	force dut.done1 = 1'b0;
	force dut.done2 = 1'b0;
	force dut.done = 1'b0;

	rst_n = 1'b0; //test reset condition
	repeat(2) @(posedge clk);
	assert(dut.state == dut.IDLE)
		$display("state ==IDLE, therefore, passed");
	else
		$error("state != IDLE, failed");
	assert(dut.start2 == 1'b0 && dut.start3 == 1'b0)
		$display("start2 and start3 zero, reset funtioning");
	else
		$error("start2 and start3 not zero after reset, reset possibly malfunctioning");
	
	
	rst_n = 1'b1; //reset is off, will move to C1 after start becomes 1
	repeat(1) @(posedge clk);
	assert(dut.state == dut.IDLE)
		$display("state is in the IDLE, passed");
	else
		$error("state got out of IDLE, fsm malfunctioning");
	
	start = 1'b1; //done is zero and start is 1, after moving to C1, should stay in C1
	repeat(2) @(posedge clk);
	assert(dut.state == dut.C1)
		$display("start=1 but done is 1'b0, so stays in same state, passed");
	else
		$error("done is 1'b0 but state moved, failed");
	

	force dut.done1 = 1'b1; //done1 becomes high, triggers and changes the state to C2
	repeat(2) @(posedge clk);
	force dut.done1 = 1'b0;
	assert(dut.state == dut.C2)
		$display("state is in the C2, passed");
	else
		$error("state is not in the C2, failed fsm");
	assert(dut.start2 == 1'b1 && dut.start3 ==1'b0)
		$display("start2 is on and start3 is off, passed");
	else
		$error("start2 == on && start3 == off condition not met");

	
	force dut.done2 = 1'b1; //state to C3
	repeat(2) @(posedge clk);
	assert(dut.state == dut.C3)
		$display("state is in the C3, passed");
	else
		$error("state is not in the C3, failed fsm");
	assert(dut.start3 == 1'b1)
		$display("start3 is on, passed");
	else
		$error("start3 == off, condition not met");

	
	repeat(2) @(posedge clk); //done==0, stays in same state
	assert(dut.state == dut.C3)
		$display("done == 0, so state stays in C3");
	else
		$error("state moved out from C3 even when done==0, error");


	
	force dut.done = 1'b1; //done set high, state moves from C3 to DONE
	repeat(2) @(posedge clk);
	force dut.done = 1'b0;
	assert(dut.state == dut.DONE)
		$display("done ==1, state moves to C3 to DONE");
	else
		$error("state failed to move to DONE even when done is set high, failed");	
	assert(vga_plot == 1'b0 && vga_colour ==3'd0)
		$display("when in DONE state, vga_plot and vga_colour should be all zero, so passed");
	else
		$error("vga_plot and vga_colour is not zero, failed");

	for (int i = 0; i < 5; i++) begin
      		start = (i % 2); // toggle start(between 0 and 1)
      		repeat(1) @(posedge clk);
      		assert (dut.state == dut.DONE)
			$display("State held in DONE on iteration %0d", i);
        	else 
			$error("State did not hold in DONE on iteration %0d", i);
      		assert (dut.start2 == 1'b0 && dut.start3 == 1'b0)
			$display("start2/start3 successfuly stayed as zero in DONE state(iteration %0d), passed", i);
        	else $error("In DONE, start2/start3 must stay 0 (iteration %0d), so failed", i);
    	end
	end

endmodule: tb_rtl_reuleaux
	
	
	
	

	
	
