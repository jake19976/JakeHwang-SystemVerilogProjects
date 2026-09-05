// To reduce risk for physical button to generate bouncing signals
// To avoid CDC risk between fast and slow clock
// Very few possibility happening (BUT still happens)

module debouncer(input logic clock,
               input logic slow_clock,
               input logic resetb,
               output logic clock_tick);

   logic key_1, key_2, db_output;
   logic [23:0] db_counter;

   always_ff @(posedge clock) begin // Signal Debouncer
      if (!resetb) begin
         db_counter <= 24'b0;
         db_output <= 1'b0;
      end
      else begin
         if (slow_clock != db_counter) begin
            db_counter <= db_counter + 1'b1;
            if (db_counter == 24'hFFFFF) begin //Wait for ≈21ms
               db_output <= slow_clock;
               db_counter <= 24'b0;
            end
         end
         else begin
            db_counter <= 24'b0;
         end
      end
   end

   always_ff @(posedge clock) begin // Edge Detector
      if (!resetb) begin
         key_1 <= 1;
         key_2 <= 1;
      end
      else if (slow_clock) begin
         key_1 <= db_output;
         key_2 <= key_1;
      end
   end

	assign clock_tick = key_1 && !key_2;

endmodule
