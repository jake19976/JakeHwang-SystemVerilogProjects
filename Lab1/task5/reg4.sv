module reg4(input logic [3:0] new_card,
			input logic load_card,
			input logic resetb,
			input logic slow_clock,
			output logic [3:0] final_card);

	always_ff @(posedge slow_clock) begin
		if (!resetb)
			final_card = 4'b0;
		else begin
			if (load_card == 1)
				final_card = new_card;
		end
	end

endmodule