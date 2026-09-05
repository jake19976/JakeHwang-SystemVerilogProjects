module datapath(input logic slow_clock, input logic fast_clock, input logic resetb,
                input logic load_pcard1, input logic load_pcard2, input logic load_pcard3,
                input logic load_dcard1, input logic load_dcard2, input logic load_dcard3,
                output logic [3:0] pcard3_out,
                output logic [3:0] pscore_out, output logic [3:0] dscore_out,
                output logic [6:0] HEX5, output logic [6:0] HEX4, output logic [6:0] HEX3,
                output logic [6:0] HEX2, output logic [6:0] HEX1, output logic [6:0] HEX0);

    logic [3:0] new_card;
    logic [3:0] pcard1, pcard2, pcard3;
    logic [3:0] dcard1, dcard2, dcard3;

    // Card dealer
    dealcard dc(.resetb(resetb), .clock(fast_clock), .new_card(new_card));

    // Player's card registers
    reg4 preg1(.new_card(new_card), .load_card(load_pcard1), .resetb(resetb), .slow_clock(slow_clock), .final_card(pcard1));
    reg4 preg2(.new_card(new_card), .load_card(load_pcard2), .resetb(resetb), .slow_clock(slow_clock), .final_card(pcard2));
    reg4 preg3(.new_card(new_card), .load_card(load_pcard3), .resetb(resetb), .slow_clock(slow_clock), .final_card(pcard3));

    // Dealer's card registers
    reg4 dreg1(.new_card(new_card), .load_card(load_dcard1), .resetb(resetb), .slow_clock(slow_clock), .final_card(dcard1));
    reg4 dreg2(.new_card(new_card), .load_card(load_dcard2), .resetb(resetb), .slow_clock(slow_clock), .final_card(dcard2));
    reg4 dreg3(.new_card(new_card), .load_card(load_dcard3), .resetb(resetb), .slow_clock(slow_clock), .final_card(dcard3));

    // 7-segment display for player's cards
    card7seg pseg1(.card(pcard1), .seg7(HEX0));
    card7seg pseg2(.card(pcard2), .seg7(HEX1));
    card7seg pseg3(.card(pcard3), .seg7(HEX2));

    // 7-segment display for dealer's cards
    card7seg dseg1(.card(dcard1), .seg7(HEX3));
    card7seg dseg2(.card(dcard2), .seg7(HEX4));
    card7seg dseg3(.card(dcard3), .seg7(HEX5));

    // Score calculation
    scorehand pscorehand(.card1(pcard1), .card2(pcard2), .card3(pcard3), .total(pscore_out));
    scorehand dscorehand(.card1(dcard1), .card2(dcard2), .card3(dcard3), .total(dscore_out));

endmodule
