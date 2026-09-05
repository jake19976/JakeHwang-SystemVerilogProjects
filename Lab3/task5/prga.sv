module prga(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);

    typedef enum logic [5:0] {
        IDLE,
        REQ_MSG_LEN,
        GET_MSG_LEN,
        WRITE_PT_0,
        REQ_CT,
        GET_CT,
        UPD_I,
        REQ_S_I,
        GET_S_I,
        S_I,
        UPD_J,
        REQ_S_J,
        GET_S_J,
        S_J,
        WRITE_S_J,
        WRITE_S_I,
        REQ_PAD,
        GET_PAD,
        WRITE_PT,
        LOOP} state_t;

    state_t state, next_state;

    logic [7:0] i, j, k;
    logic [7:0] s_i, s_j;
    logic [7:0] msg_len;
    logic [7:0] pad, ct;

    always_ff @(posedge clk) begin
        if (!rst_n)
            state <= IDLE;
        else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    i <= 0;
                    j <= 0;
                    k <= 1;
                    s_i <= 0;
                    s_j <= 0;
                    msg_len <= 0;
                    pad <= 0;
                    ct <= 0;
                end
                REQ_MSG_LEN: ;
                GET_MSG_LEN: msg_len <= ct_rddata;
                REQ_CT: ;
                GET_CT: ct <= ct_rddata;
                WRITE_PT_0: ;
                UPD_I: i <= i + 1;
                REQ_S_I: ;
                GET_S_I: s_i <= s_rddata;
                S_I: ;
                UPD_J: j <= j + s_i;
                REQ_S_J: ;
                GET_S_J: s_j <= s_rddata;
                S_J: ;
                WRITE_S_J: ;
                WRITE_S_I: ;
                REQ_PAD: ;
                GET_PAD: pad <= s_rddata;
                WRITE_PT: ;
                LOOP: begin
                    if (k <= msg_len)
                        k <= k + 1;
                end
                default: ;
            endcase
        end
    end

    always_comb begin
        next_state = state;
        s_addr = 0;
		s_wrdata = 0;
	    s_wren = 0;		
		pt_addr = 0;
		pt_wrdata = 0;
		pt_wren = 0;			
		ct_addr = 0;
        rdy = 1'b0;
        case (state)
            IDLE: begin
                if (en) begin
                    rdy = 0;
                    next_state = REQ_MSG_LEN;
                end
                else begin
                    rdy = 1;
                    next_state = IDLE;
                end
            end
            REQ_MSG_LEN: next_state = GET_MSG_LEN;
            GET_MSG_LEN: next_state = WRITE_PT_0;
            WRITE_PT_0: begin
                pt_wren = 1'b1;
                pt_wrdata = msg_len;
                next_state = REQ_CT;
            end
            REQ_CT: begin
                ct_addr = k;
                next_state = GET_CT;
            end
            GET_CT: next_state = UPD_I;
            UPD_I: next_state = REQ_S_I;
            REQ_S_I: begin
                s_addr = i;
                next_state = GET_S_I;
            end
            GET_S_I: next_state = S_I;
            S_I: next_state = UPD_J;
            UPD_J: next_state = REQ_S_J;
            REQ_S_J: begin
                s_addr = j;
                next_state = GET_S_J;
            end
            GET_S_J: next_state = S_J;
            S_J: next_state = WRITE_S_J;
            WRITE_S_J: begin
                s_wren = 1'b1;
                s_addr = j;
				s_wrdata = s_i;
                next_state = WRITE_S_I;
            end
            WRITE_S_I: begin
                s_wren = 1'b1;
                s_addr = i;
                s_wrdata = s_j;
                next_state = REQ_PAD;
            end
            REQ_PAD: begin
                s_addr = s_i + s_j;
                next_state = GET_PAD;
            end
            GET_PAD: next_state = WRITE_PT;
            WRITE_PT: begin
                pt_wren = 1;
                pt_addr = k;
				pt_wrdata = (pad ^ ct);
                next_state = LOOP;
            end
            LOOP: begin
                if (k <= msg_len)
                    next_state = REQ_CT;
                else
                    next_state = IDLE;
            end
            default: ;
        endcase
    end

endmodule: prga