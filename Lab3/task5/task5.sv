module task5(
    input  logic        CLOCK_50,
    input  logic [3:0]  KEY,
    input  logic [9:0]  SW,
    output logic [6:0]  HEX0, HEX1, HEX2,
    output logic [6:0]  HEX3, HEX4, HEX5,
    output logic [9:0]  LEDR
);

    localparam Waiting_to_start = 3'd0;
    localparam Waiting_for_rdy  = 3'd1;
    localparam Deassert_en      = 3'd2;
    localparam Cracking         = 3'd3;
    localparam Got_Done_Signal  = 3'd4;

    logic [2:0] top_state;

    logic [7:0] ct_addr;
    logic [7:0] ct_rddata;

    logic       en;
    logic       rdy;

    logic [23:0] key, key_output;
    logic        key_valid;

    logic [4:0] hex_0, hex_1, hex_2, hex_3, hex_4, hex_5;

    logic rst_n;
    assign rst_n = KEY[3];  
	
	
	 logic started_after_reset;

    // CT memory
    ct_mem ct(
        .address(ct_addr),
        .clock  (CLOCK_50),
        .data   (8'd0),
        .wren   (1'b0),
        .q      (ct_rddata)
    );

    doublecrack dc(
        .clk      (CLOCK_50),
        .rst_n    (rst_n),
        .en       (en),
        .rdy      (rdy),
        .key      (key_output),
        .key_valid(key_valid),
        .ct_addr  (ct_addr),
        .ct_rddata(ct_rddata)
    );

    seg7 HEX_0(.HEX(HEX0), .val(hex_0));
    seg7 HEX_1(.HEX(HEX1), .val(hex_1));
    seg7 HEX_2(.HEX(HEX2), .val(hex_2));
    seg7 HEX_3(.HEX(HEX3), .val(hex_3));
    seg7 HEX_4(.HEX(HEX4), .val(hex_4));
    seg7 HEX_5(.HEX(HEX5), .val(hex_5));
	 
	 
	

    // Top-level FSM
    always_ff @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) begin
            top_state <= Waiting_to_start;
            key       <= 24'd0;
				started_after_reset <= 1'b0; 
        end else begin
            case (top_state)
                Waiting_to_start: begin
                    if (!started_after_reset) begin
                        top_state          <= Waiting_for_rdy;
                        started_after_reset <= 1'b1;
                    end
                end

                Waiting_for_rdy: begin
                    key <= 24'd0;
                    if (rdy)
                        top_state <= Deassert_en;
                end

                Deassert_en: begin
                    top_state <= Cracking;
                end

                Cracking: begin
                    if (rdy) begin
                        top_state <= Got_Done_Signal;
                        key       <= key_output;
                    end
                end

                Got_Done_Signal: begin
                    top_state <= Waiting_to_start;
                end
            endcase
        end
    end

    always_comb begin
        en = 1'b0;

        case (top_state)
            Waiting_to_start: begin
                en = 1'b0;
                if (key_valid) begin
                    hex_0 = key[3:0];
                    hex_1 = key[7:4];
                    hex_2 = key[11:8];
                    hex_3 = key[15:12];
                    hex_4 = key[19:16];
                    hex_5 = key[23:20];
                end else begin
                    hex_0 = 5'd16;
                    hex_1 = 5'd16;
                    hex_2 = 5'd16;
                    hex_3 = 5'd16;
                    hex_4 = 5'd16;
                    hex_5 = 5'd16;
                end
            end

            Waiting_for_rdy: begin
                if (rdy)
                    en = 1'b1; // one-cycle pulse
                hex_0 = 5'd17;
                hex_1 = 5'd17;
                hex_2 = 5'd17;
                hex_3 = 5'd17;
                hex_4 = 5'd17;
                hex_5 = 5'd17;
            end

            Deassert_en,
            Cracking: begin
                en    = 1'b0;
                hex_0 = 5'd17;
                hex_1 = 5'd17;
                hex_2 = 5'd17;
                hex_3 = 5'd17;
                hex_4 = 5'd17;
                hex_5 = 5'd17;
            end

            Got_Done_Signal: begin
                en = 1'b0;
                if (key_valid) begin
                    hex_0 = key[3:0];
                    hex_1 = key[7:4];
                    hex_2 = key[11:8];
                    hex_3 = key[15:12];
                    hex_4 = key[19:16];
                    hex_5 = key[23:20];
                end else begin
                    hex_0 = 5'd16;
                    hex_1 = 5'd16;
                    hex_2 = 5'd16;
                    hex_3 = 5'd16;
                    hex_4 = 5'd16;
                    hex_5 = 5'd16;
                end
            end
        endcase
    end

endmodule
