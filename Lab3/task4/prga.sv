module prga(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key, // key is not used in this module, but kept for interface consistency
            output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);

    typedef enum logic [4:0] {
        IDLE,
        READ_LEN,
        WRITE_LEN,
        LOOP_START,
        UPDATE_I,
        READ_S_I,
        UPDATE_J,
        READ_S_J,
        WRITE_S_I,
        WRITE_S_J,
        REQ_PAD,
        READ_PAD,
        READ_CT_K,
        WRITE_PT,
        DONE
    } state_t;

    state_t state, next_state;

    logic [7:0] i, j;
    logic [8:0] k;
    logic [7:0] s_i, s_j;
    logic [7:0] msg;
    logic [7:0] pad;

    logic [7:0] i_next, j_next;
    logic [8:0] k_next;
    logic [7:0] s_i_next, s_j_next;
    logic [7:0] msg_next;
    logic [7:0] pad_next;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            i <= 8'd0;
            j <= 8'd0;
            k <= 8'd0;
            s_i <= 8'd0;
            s_j <= 8'd0;
            msg <= 8'd0;
            pad <= 8'd0;
        end
        else begin
            state <= next_state;
            i <= i_next;
            j <= j_next;
            k <= k_next;
            s_i <= s_i_next;
            s_j <= s_j_next;
            msg <= msg_next;
            pad <= pad_next;
        end
    end

    // Next state logic and signal assignments
    always_comb begin
        next_state = state;
        i_next = i;
        j_next = j;
        k_next = k;
        s_i_next = s_i;
        s_j_next = s_j;
        msg_next = msg;
        pad_next = pad;

        rdy = 1'b0;
        s_addr = 8'd0;
        s_wrdata = 8'd0;
        s_wren = 1'b0;
        ct_addr = 8'd0;
        pt_addr = 8'd0;
        pt_wrdata = 8'd0;
        pt_wren = 1'b0;

        case (state)
            IDLE: begin
                rdy = 1'b1;
                if (en) begin
                    i_next = 8'd0;
                    j_next = 8'd0;
                    k_next = 8'd1;
                    next_state = READ_LEN;
                end
            end

            READ_LEN: begin
                ct_addr = 8'd0;
                next_state = WRITE_LEN;
            end

            WRITE_LEN: begin
                msg_next = ct_rddata;
                pt_addr = 8'd0;
                pt_wrdata = ct_rddata;
                pt_wren = 1'b1;
                next_state = LOOP_START;
            end

            LOOP_START: begin
                if (k > msg) begin
                    next_state = DONE;
                end else begin
                    next_state = UPDATE_I;
                end
            end

            UPDATE_I: begin
                i_next = (i + 8'b1) % 256;
                s_addr = i_next;
                next_state = READ_S_I;
            end

            READ_S_I: begin
                s_i_next = s_rddata;
                next_state = UPDATE_J;
            end

            UPDATE_J: begin
                j_next = (j + s_i) % 256;
                s_addr = j_next;
                next_state = READ_S_J;
            end

            READ_S_J: begin
                s_j_next = s_rddata;
                next_state = WRITE_S_I;
            end

            WRITE_S_I: begin
                s_addr = i;
                s_wrdata = s_j;
                s_wren = 1'b1;
                next_state = WRITE_S_J;
            end

            WRITE_S_J: begin
                s_addr = j;
                s_wrdata = s_i;
                s_wren = 1'b1;
                next_state = REQ_PAD;
            end

            REQ_PAD: begin
                s_addr = (s_i + s_j)  % 256;
                next_state = READ_PAD;
            end

            READ_PAD: begin
                pad_next = s_rddata;
                next_state = READ_CT_K;
            end

            READ_CT_K: begin
                ct_addr = k;
                next_state = WRITE_PT;
            end

            WRITE_PT: begin
                pt_addr = k;
                pt_wrdata = pad ^ ct_rddata;
                pt_wren = 1'b1;
                k_next = k + 9'b1;
                next_state = LOOP_START;
            end

            DONE: begin
                rdy = 1'b1;
                next_state = DONE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule: prga
