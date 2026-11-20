module tb_task5();

// Your testbench goes here. Make sure your tests exercise the entire design
// in the .sv file.  Note that in our tests the simulator will exit after
// 100,000 ticks (equivalent to "initial #100000 $finish();").


	logic CLOCK_50;
	logic[3:0] KEY;
	logic[9:0] LEDR;
	logic[6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

	task5 test5(.CLOCK_50(CLOCK_50), .KEY(KEY), .LEDR(LEDR), .HEX5(HEX5), .HEX4(HEX4), .HEX3(HEX3), .HEX2(HEX2), .HEX1(HEX1), .HEX0(HEX0));
		
		initial begin  //FAST CLOCK
			CLOCK_50 = 1'b0; 
			#10;
			forever begin
			CLOCK_50 = 1'b1;
			#10;
			CLOCK_50 = 1'b0;
			#10;
			end
		end

		initial begin //SLOW CLOCK(USER INPUT)
			KEY[0] = 1'b0; 
			#1000;
			forever begin
			KEY[0] = 1'b1;
			#1000;
			KEY[0] = 1'b0;
			#1000;
			end
		end
		
		initial begin //RESET(USER INPUT)
			KEY[3] = 1'b0;
			#1000;
			KEY[3] = 1'b1;
			#998000;
			KEY[3] = 1'b0;
			#1000;
		end

//IN SIMULATION, CHECK INPUT VS FINAL OUTPUT, internal logic verified in tb_scorehand, tb_datapath, tb_card7seg, tb_statemachine. This tb only uses 
//actual user input: KEY[0] AND KEY[3]


endmodule
