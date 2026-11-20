module task4(input logic CLOCK_50, input logic [3:0] KEY,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5);

    typedef enum logic [2:0] {INIT_RDY, INIT_EN, ARC4, DONE} state_t;
    state_t state, next_state;

    logic [7:0] ct_addr;
    logic [7:0] ct_rddata;
    logic [23:0] c_key, key;

    logic [4:0] h0;
	logic [4:0] h1;
	logic [4:0] h2;
	logic [4:0] h3;
	logic [4:0] h4;
	logic [4:0] h5;

    logic en, rdy, key_valid;

    seg7 H0(.val(h0), .HEX(HEX0));
    seg7 H1(.val(h1), .HEX(HEX1));
    seg7 H2(.val(h2), .HEX(HEX2));
    seg7 H3(.val(h3), .HEX(HEX3));
    seg7 H4(.val(h4), .HEX(HEX4));
    seg7 H5(.val(h5), .HEX(HEX5));

    ct_mem ct(
        .address(ct_addr),
        .clock(CLOCK_50),
        .q(ct_rddata)
    );

    crack c(
        .clk(CLOCK_50),
        .rst_n(KEY[3]),
        .en(en),
        .rdy(rdy),
        .key(c_key),
        .key_valid(key_valid),
        .ct_addr(ct_addr),
        .ct_rddata(ct_rddata)
    );

    //Sequential Logic
    always_ff @(posedge CLOCK_50) begin
        if (!KEY[3])
            state <= INIT_RDY;
        else begin
            state <= next_state;
            case (state)
                INIT_EN: key <= 0;
                ARC4: begin
                    if (rdy)
                        key <= c_key;
                end
                default: ;
            endcase
        end
    end

    always_comb begin
        next_state = state;
        en = 1'b0;
        h0 = 5'h11;
        h1 = 5'h11;
        h2 = 5'h11;
        h3 = 5'h11;
        h4 = 5'h11;
        h5 = 5'h11;
        case (state)
            INIT_RDY: begin
                if (rdy)
                    next_state = INIT_EN;
                else
                    next_state = INIT_RDY;
            end
            INIT_EN: begin
                en = 1'b1;
                next_state = ARC4;
            end
            ARC4: begin
                if (rdy)
                    next_state = DONE;
                h0 = 5'h11;
                h1 = 5'h11;
                h2 = 5'h11;
                h3 = 5'h11;
                h4 = 5'h11;
                h5 = 5'h11;
            end
            DONE: begin
                if (key_valid) begin
                    h0 = key[3:0];
	                h1 = key[7:4];
					h2 = key[11:8];
					h3 = key[15:12];
					h4 = key[19:16];
					h5 = key[23:20];
                end
                else begin
                    h0 = 5'h10;
                    h1 = 5'h10;
                    h2 = 5'h10;
                    h3 = 5'h10;
                    h4 = 5'h10;
                    h5 = 5'h10;
                end
                next_state = DONE;
            end
            default: next_state = INIT_RDY;
        endcase
    end

endmodule: task4
