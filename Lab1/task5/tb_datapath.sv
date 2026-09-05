module tb_datapath();

// Your testbench goes here. Make sure your tests exercise the entire design
// in the .sv file.  Note that in our tests the simulator will exit after
// 10,000 ticks (equivalent to "initial #10000 $finish();").
	logic slow_clock, fast_clock, resetb, load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3;
	logic [3:0] pcard3_out, pscore_out, dscore_out;
	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	
	//insantiation of datapath.sv
datapath dp(.slow_clock(slow_clock), .fast_clock(fast_clock), .resetb(resetb),

.load_pcard1(load_pcard1), .load_pcard2(load_pcard2), .load_pcard3(load_pcard3), .load_dcard1(load_dcard1), .load_dcard2(load_dcard2), .load_dcard3(load_dcard3),

.dscore_out(dscore_out), .pscore_out(pscore_out), .pcard3_out(pcard3_out),

.HEX5(HEX5), .HEX4(HEX4), .HEX3(HEX3), .HEX2(HEX2), .HEX1(HEX1), .HEX0(HEX0));

assign HEX = {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0};

//slock clock signal
	initial begin
		slow_clock = 1'b0;
		#50;
		forever begin
		slow_clock = 1'b1;
		#50;
		slow_clock = 1'b0;
		#50;
		end
	end
//faset clock signal
	initial begin
		fast_clock = 1'b0;
		#10;
		forever begin
		fast_clock = 1'b1;
		#10;
		fast_clock = 1'b0;
		#10;
		end
	end

//declared.sv to HEX display(if number generated, pass, if not, fail)
	initial begin
		resetb=1'b0;
		load_pcard1=1'b0;
		load_pcard2=1'b0;
		load_pcard3=1'b0;
		load_dcard1=1'b0;
		load_dcard2=1'b0;
		load_dcard3=1'b0;
		#100;
		resetb = 1'b1;
		#10
		load_pcard1=1'b1;
		#100;
		if(HEX0!=7'b1111111) begin
			$display("HEX0 WORKING");
		end
		else begin
			$display("HEX0 NOT WORKING");
		end
		
		load_pcard2=1'b1;	
		#100;
		if(HEX1!=7'b1111111) begin
			$display("HEX1 WORKING");
		end
		else begin
			$display("HEX1 NOT WORKING");
		end
		
		load_pcard3=1'b1;
		#100;
		if(HEX2!=7'b1111111) begin
			$display("HEX2 WORKING");
		end
		else begin
			$display("HEX2 NOT WORKING");
		end
		
		load_dcard1=1'b1;
		#100;
		if(HEX3!=7'b1111111) begin
			$display("HEX3 WORKING");
		end
		else begin
			$display("HEX3 NOT WORKING");
		end
		
		load_dcard2=1'b1;
		#100;
		if(HEX4!=7'b1111111) begin
			$display("HEX4 WORKING");
		end
		else begin
			$display("HEX4 NOT WORKING");
		end
		
		load_dcard3=1'b1;
		#100;
		if(HEX5!=7'b1111111) begin
			$display("HEX5 WORKING");
		end
		else begin
			$display("HEX5 NOT WORKING");
		end
		
		resetb=1'b0;
		#100;
		if(HEX == 42'b1) begin
			$display("RESET WORKING");
		end
		else begin
			$display("RESET NOT WORKING");
		end
	end
endmodule
