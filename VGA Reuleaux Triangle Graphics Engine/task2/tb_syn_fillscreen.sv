module tb_syn_fillscreen();

 	logic        clk, rst_n, start;
  	logic [2:0]  colour;
  	logic        done;
  	logic [7:0]  vga_x;
  	logic [6:0]  vga_y;
  	logic [2:0]  vga_colour;
  	logic        vga_plot;

 
  	initial clk = 1'b0;
  	always #10 clk = ~clk;

 
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

  	initial begin
    		rst_n  = 1'b0;
    		start  = 1'b0;

    	repeat (1) @(posedge clk);
    	rst_n = 1'b1;
    	start = 1'b1;

   	for (int row = 0; row < 120; row++) begin
     	 	repeat (160) @(posedge clk);
      		assert (vga_x == 8'd159 && vga_y == row) begin
       			$display("vga_x=159, vga_y=%0d", row);
      		end else begin
        		$error("at the end of one cycle, vga_x is 159 and y=%0d, you got x=%0d, y=%0d", row, vga_x, vga_y);
      		end
    	end

    	// One extra cycle for 'done' to assert
    	repeat (1) @(posedge clk);
    	assert (done) begin
      	$display("done=1 after final row, final column");
    	end else begin
      	$error("done should be 1 after the full 19210 cycle");;
   	end

   	// Stop the run cleanly
    	start = 1'b0;
    	@(posedge clk);
    	assert (!start) begin
      		$display("start is zero at the end");
    	end else begin
      		$error("at the end, start should be zero");
    	end
	end
  endmodule: tb_syn_fillscreen
