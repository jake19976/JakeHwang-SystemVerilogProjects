module task3(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    // your code here
    typedef enum logic [2:0] {INIT_RDY, INIT_EN, DECRYPT, DONE} state_t;
	state_t state, next_state;

    logic [7:0] ct_addr, pt_addr;
    logic [7:0] ct_rddata, pt_rddata;
    logic [7:0] pt_wrdata;
    logic rdy, en, pt_wren;

    logic [23:0] key;
    assign key[9:0] = SW[9:0];
    assign key[23:10] = 14'd0;

    ct_mem ct( /* connect ports */ 
        .address(ct_addr),
        .clock(CLOCK_50),
        .q(ct_rddata));

    pt_mem pt( /* connect ports */ 
        .address(pt_addr),
        .clock(CLOCK_50),
        .data(pt_wrdata), 
		.wren(pt_wren),
        .q(pt_rddata));

    arc4 a4( /* connect ports */ 
        .clk(CLOCK_50),
        .rst_n(KEY[3]),
        .en(en),
        .rdy(rdy),
        .key(key), 
		.ct_addr(ct_addr),
        .ct_rddata(ct_rddata),
        .pt_addr(pt_addr), 
		.pt_rddata(pt_rddata),
        .pt_wrdata(pt_wrdata),
        .pt_wren(pt_wren));

    // your code here

    always_ff @(posedge CLOCK_50) begin
        if (!KEY[3])
            state <= INIT_RDY;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        en = 1'b0;
        case (state)
            INIT_RDY: begin
                if (rdy)
                    next_state = INIT_EN;
                else
                    next_state = INIT_RDY;
            end
            INIT_EN: begin
                en = 1;
                next_state = DECRYPT;
            end
            DECRYPT: begin
                if (rdy)
                    next_state = DONE;
            end
            DONE: next_state = DONE;
            default: next_state = INIT_RDY;
        endcase
    end

endmodule: task3
