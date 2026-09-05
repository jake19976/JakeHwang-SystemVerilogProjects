module seg7 (input logic [4:0] val, output logic [6:0] HEX);

   always_comb begin
    	case (val)
        	5'h0: HEX = 7'b1000000; // 0
			5'h1: HEX = 7'b1111001; // 1
			5'h2: HEX = 7'b0100100; // 2
			5'h3: HEX = 7'b0110000; // 3
			5'h4: HEX = 7'b0011001; // 4
			5'h5: HEX = 7'b0010010; // 5
			5'h6: HEX = 7'b0000010; // 6
			5'h7: HEX = 7'b1111000; // 7
			5'h8: HEX = 7'b0000000; // 8
			5'h9: HEX = 7'b0010000; // 9
			5'hA: HEX = 7'b0001000; // A
			5'hB: HEX = 7'b0000011; // B
			5'hC: HEX = 7'b1000110; // C
			5'hD: HEX = 7'b0100001; // D
			5'hE: HEX = 7'b0000110; // E
			5'hF: HEX = 7'b0001110; // F
			5'h10: HEX = 7'b0111111; // -
			5'h11: HEX = 7'b1111111; // Blank
			default: HEX = 7'b1111111;
      endcase
   end

endmodule