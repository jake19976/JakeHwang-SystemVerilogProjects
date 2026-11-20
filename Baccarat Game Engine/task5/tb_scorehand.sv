module tb_scorehand();

// Your testbench goes here. Make sure your tests exercise the entire design
// in the .sv file.  Note that in our tests the simulator will exit after
// 10,000 ticks (equivalent to "initial #10000 $finish();").
  logic[3:0] card1, card2, card3, total;
  	
  	//instantiate scorehand variables
  	scorehand result(.card1, .card2, .card3, .total);
  	
  	initial begin 
      //random card values generated, then the first digit of the cards added with each other. Will indicate if the values are correct
  		for (int i = 0; i < 10; i++) begin
  			
        card1 = $urandom_range(9,0);
        card2 = $urandom_range(9,0);
        card3 = $urandom_range(9,0);
  			#1;
  			if ( total==(card1 + card2 + card3)%10 ) begin
          $display("Card numbers added properly"); 
  			end
  			else begin
  				$display("Card numbers failed to add properly");
  			end
  		end
  	end
endmodule
