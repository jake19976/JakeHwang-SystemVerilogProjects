module doublecrack(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        en,
    output logic        rdy,
    output logic [23:0] key,
    output logic        key_valid,
    output logic [7:0]  ct_addr,
    input  logic [7:0]  ct_rddata
);

    // Shared PT memory (must hold plaintext when key_valid == 1)
    logic [7:0] shared_pt_addr, shared_pt_wrdata;
    logic       shared_pt_wren;
    logic [7:0] shared_pt_rddata;

    pt_mem3 pt3(
        .address(shared_pt_addr),
        .clock  (clk),
        .data   (shared_pt_wrdata),
        .wren   (shared_pt_wren),
        .q      (shared_pt_rddata)
    );

    // crack1 signals
    logic        rdy1;
    logic [23:0] key1;
    logic        key_valid1;
    logic [7:0]  ct_addr1;

    logic [7:0]  sh_addr1, sh_data1;
    logic        sh_wren1;

    // crack2 signals
    logic        rdy2;
    logic [23:0] key2;
    logic        key_valid2;
    logic [7:0]  ct_addr2;

    logic [7:0]  sh_addr2, sh_data2;
    logic        sh_wren2;

    // Instantiate two crack cores
    crack1 c1(
        .clk            (clk),
        .rst_n          (rst_n),
        .en             (en),
        .rdy            (rdy1),
        .key            (key1),
        .key_valid      (key_valid1),
        .ct_addr        (ct_addr1),   // see note below
        .ct_rddata      (ct_rddata),  // both see same CT
        .shared_pt_addr (sh_addr1),
        .shared_pt_wrdata(sh_data1),
        .shared_pt_wren (sh_wren1)
    );

    crack2 c2(
        .clk            (clk),
        .rst_n          (rst_n),
        .en             (en),
        .rdy            (rdy2),
        .key            (key2),
        .key_valid      (key_valid2),
        .ct_addr        (ct_addr2),
        .ct_rddata      (ct_rddata),  // same CT bus
        .shared_pt_addr (sh_addr2),
        .shared_pt_wrdata(sh_data2),
        .shared_pt_wren (sh_wren2)
    );

    // For the external CT port, just pick one core's ct_addr.
    // In a correct design both should be equal at all times.
    assign ct_addr = ct_addr1;

    // Decide which core wins
    logic winner_is_1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            winner_is_1 <= 1'b0;
        end else begin
            // latch first winner
            if (key_valid1 && !key_valid2)
                winner_is_1 <= 1'b1;
            else if (key_valid2 && !key_valid1)
                winner_is_1 <= 1'b0;
            // if both 0 or both 1, keep previous or default
        end
    end

    // Combined outputs
    always_comb begin
        key_valid = key_valid1 | key_valid2;

        if (key_valid1)
            key = key1;
        else if (key_valid2)
            key = key2;
        else
            key = 24'd0;

        // rdy: either a key is found, or both cores are done/idle
        rdy = (key_valid1 | key_valid2) | (rdy1 & rdy2);
    end

    // Shared PT write arbitration
    always_comb begin
        shared_pt_addr   = 8'd0;
        shared_pt_wrdata = 8'd0;
        shared_pt_wren   = 1'b0;

        if (!(key_valid1 | key_valid2)) begin
            // No winner yet: accept whichever core is writing this cycle.
            if (sh_wren1) begin
                shared_pt_addr   = sh_addr1;
                shared_pt_wrdata = sh_data1;
                shared_pt_wren   = 1'b1;
            end else if (sh_wren2) begin
                shared_pt_addr   = sh_addr2;
                shared_pt_wrdata = sh_data2;
                shared_pt_wren   = 1'b1;
            end
        end else begin
            // Winner has been determined: only mirror winner's writes
            if (winner_is_1 && sh_wren1) begin
                shared_pt_addr   = sh_addr1;
                shared_pt_wrdata = sh_data1;
                shared_pt_wren   = 1'b1;
            end else if (!winner_is_1 && sh_wren2) begin
                shared_pt_addr   = sh_addr2;
                shared_pt_wrdata = sh_data2;
                shared_pt_wren   = 1'b1;
            end
        end
    end

endmodule
