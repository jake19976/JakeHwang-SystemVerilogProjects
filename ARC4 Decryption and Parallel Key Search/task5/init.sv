module init(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       en,
    output logic       rdy,
    output logic [7:0] addr,
    output logic [7:0] wrdata,
    output logic       wren
);

    typedef enum logic [1:0] {
        IDLE,
        WRITE,
        DONE
    } state_t;

    state_t state, next_state;
    logic [7:0] i, i_next;

    // Sequential
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            i     <= 8'd0;
        end else begin
            state <= next_state;
            i     <= i_next;
        end
    end

    // Combinational: next state and outputs
    always_comb begin
        // Defaults
        next_state = state;
        i_next     = i;

        rdy    = 1'b0;
        wren   = 1'b0;
        addr   = i;
        wrdata = i;

        case (state)
            //--------------------------------
            IDLE: begin
                rdy = 1'b1;            // ready while idle

                if (en) begin
                    // start a new run
                    i_next     = 8'd0;
                    rdy        = 1'b0; // now busy
                    next_state = WRITE;
                end
            end

            //--------------------------------
            WRITE: begin
                rdy  = 1'b0;
                wren = 1'b1;           // write S[i] = i

                if (i == 8'hFF) begin
                    // finished writing last entry
                    next_state = DONE;
                end else begin
                    i_next = i + 8'd1;
                end
            end

            //--------------------------------
            DONE: begin
                rdy = 1'b1;            // done

                // Wait for en to drop before returning to IDLE
                if (!en) begin
                    next_state = IDLE;
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule : init