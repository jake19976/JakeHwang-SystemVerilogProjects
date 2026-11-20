module tb_statemachine();

// Your testbench goes here. Make sure your tests exercise the entire design
// in the .sv file.  Note that in our tests the simulator will exit after
// 10,000 ticks (equivalent to "initial #10000 $finish();").

  logic slow_clock, resetb, load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light;
  logic [3:0] dscore, pscore, pcard3;

  // Instantiate 
  statemachine dut (
    .slow_clock(slow_clock),
    .resetb(resetb),
    .dscore(dscore),
    .pscore(pscore),
    .pcard3(pcard3),
    .load_pcard1(load_pcard1),
    .load_pcard2(load_pcard2),
    .load_pcard3(load_pcard3),
    .load_dcard1(load_dcard1),
    .load_dcard2(load_dcard2),
    .load_dcard3(load_dcard3),
    .player_win_light(player_win_light),
    .dealer_win_light(dealer_win_light)
  );

  initial begin //slow clock
  	slow_clock = 1'b0; #50;
  	forever begin
	slow_clock = 1'b1; #50;
	slow_clock = 1'b0; #50;
	end
  end


  // Reset
  initial begin
   
    resetb = 1'b0;    
    dscore = 1'b0;
    pscore = 1'b0;
    pcard3 = 1'b0;

    #200;          
    resetb = 1'b1;    
    #100;          

    #300;

    //player 8, dealer 6
    pscore = 4'd8; 
    dscore = 4'd6;
   //D2 TO DIVERGE
    #100; //1 CLOCK
    

    #100; // Diverge to Over
    
    assert(player_win_light && !dealer_win_light) else
      $error("Error found, player must win");

    // To P3(non-natural), to D3_1
    // Reset, then Diverge
    resetb = 1'b0; #100; 
    resetb = 1'b1; #100; // back to P1

    #100; // To D1
    #100; // To P2
    #100; // To D2

    // Player 4, Dealer 6 (Non-natural)
    pscore = 4'd4;  
    dscore = 4'd6;  
    #100;        //To Diverge
    #100;        // Diverge to P3

    // In P3, player draws if 0..5
    assert(load_pcard3) else
      $error("load_pcard3 should be ON");

    #100; // P3 TO D3_1
    pcard3 = 4'd6;
    #10;
    assert(load_dcard3) else
      $error("load_dcard3 should be ON when dscore=6 when pcard3=6");

    #100; // D3_1 TO OVER
    // (This FSM doesn?t recompute scores after 3rd cards; it uses the inputs directly.)
    if (pscore > dscore) begin
      assert(player_win_light && !dealer_win_light);
    end else if (dscore > pscore) begin
      assert(!player_win_light && dealer_win_light);
    end else begin
      assert(player_win_light && dealer_win_light); // tie
    end

   end

endmodule
