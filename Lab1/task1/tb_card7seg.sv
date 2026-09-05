module tb_card7seg;
	reg [3:0] SW;  //can change this to simulate_SW or something
	wire [6:0] HEX0; //same with this

	//instantiate module
	card7seg DUT(.SW(SW), .HEX0(HEX0)); 

	//output check
	initial begin
		SW=4'b0000;
		#5
		for(int i=1; i<17; i++) begin  //check all 16 states
			$display ("SW = %b HEX0 = %b", SW, HEX0);
			SW+=i; 
			#5;
		end	
	end


endmodule

