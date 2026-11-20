
// ELEC402 Project 2 -- 800 MHz candidate; timing requires Genus/SDF validation.
// Hand-designed eight-stage signed 16x16 multiplier; one input per fill cycle.
// The external memory and the fill/drain handshake are unchanged.

module mkMultBuff #(parameter N = 32) (
    input logic clk,
    input logic RST_N,
    input logic EN_mult,
    input logic [15:0] mult_input0,
    input logic [15:0] mult_input1,
    output logic RDY_mult,
    input logic EN_blockRead,
    output logic RDY_blockRead,
    output logic VALID_memVal,
    output logic [N-1:0] memVal_data,
    output logic EN_writeMem,
    output logic [5:0] writeMem_addr,
    output logic [N-1:0] writeMem_val,
    output logic EN_readMem,
    output logic [5:0] readMem_addr,
    input logic [N-1:0] readMem_val
);

    localparam integer PIPE_STAGES = 8;
    logic [PIPE_STAGES-1:0] pipeline_valid;
    logic [6:0] accepted_count, landed_count;
    logic [5:0] read_ptr;
    logic draining, accept_mult, accept_read;

    // Carry-save compression: x+y+z = sum3(x,y,z)+carry3(x,y,z),
    // modulo 2^32. Every bit computes locally, without a carry chain.
    function automatic [31:0] sum3(
        input logic [31:0] x, y, z
    );
        sum3 = x ^ y ^ z;
    endfunction

    function automatic [31:0] carry3(
        input logic [31:0] x, y, z
    );
        carry3 = ((x & y) | (x & z) | (y & z)) << 1;
    endfunction

    // A = a0 + (a1<<4) + (a2<<8) + (a3<<12).
    // a0,a1,a2 are unsigned nibbles; a3 is a signed nibble. Likewise B.
    // Five-bit signed extensions preserve both unsigned 0~15 and signed -8~7.
    // Stage 1: sixteen small partial multipliers, never a behavioral 16x16 '*'.
    logic signed [9:0] pp [0:15];
    wire [31:0] row [0:15];
    genvar ai, bi;
    generate
        for (ai = 0; ai < 4; ai = ai + 1) begin : gen_a
            for (bi = 0; bi < 4; bi = bi + 1) begin : gen_b
                localparam integer IDX = 4*ai + bi;
                localparam integer SHIFT = 4*(ai+bi);
                wire signed [4:0] a_digit;
                wire signed [4:0] b_digit;
                if (ai == 3) begin : gen_a_signed
                    assign a_digit = {mult_input0[15], mult_input0[15:12]};
                end else begin : gen_a_unsigned
                    assign a_digit = {1'b0, mult_input0[4*ai +: 4]};
                end
                if (bi == 3) begin : gen_b_signed
                    assign b_digit = {mult_input1[15], mult_input1[15:12]};
                end else begin : gen_b_unsigned
                    assign b_digit = {1'b0, mult_input1[4*bi +: 4]};
                end
                always_ff @(posedge clk) begin
                    if (!RST_N) pp[IDX] <= '0;
                    else        pp[IDX] <= a_digit * b_digit;
                end
                // Sign-extend BEFORE shifting, including negative partials.
                assign row[IDX] = {{22{pp[IDX][9]}}, pp[IDX]} << SHIFT;
            end
        end
    endgenerate

    // Each group of four rows is reduced to two with two compressor levels.
    // Stage 2: 16 rows -> 8 rows. Stage 3: 8 -> 4. Stage 4: 4 -> 2.
    logic [31:0] csa2 [0:7];
    logic [31:0] csa3 [0:3];
    logic [31:0] csa4_sum, csa4_carry;
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : gen_csa2
            wire [31:0] s = sum3(row[4*g], row[4*g+1], row[4*g+2]);
            wire [31:0] c = carry3(row[4*g], row[4*g+1], row[4*g+2]);
            always_ff @(posedge clk) begin
                if (!RST_N) begin
                    csa2[2*g]   <= '0;
                    csa2[2*g+1] <= '0;
                end else begin
                    csa2[2*g]   <= sum3(s, c, row[4*g+3]);
                    csa2[2*g+1] <= carry3(s, c, row[4*g+3]);
                end
            end
        end
        for (g = 0; g < 2; g = g + 1) begin : gen_csa3
            wire [31:0] s = sum3(csa2[4*g], csa2[4*g+1], csa2[4*g+2]);
            wire [31:0] c = carry3(csa2[4*g], csa2[4*g+1], csa2[4*g+2]);
            always_ff @(posedge clk) begin
                if (!RST_N) begin
                    csa3[2*g]   <= '0;
                    csa3[2*g+1] <= '0;
                end else begin
                    csa3[2*g]   <= sum3(s, c, csa2[4*g+3]);
                    csa3[2*g+1] <= carry3(s, c, csa2[4*g+3]);
                end
            end
        end
    endgenerate
    wire [31:0] csa4_s = sum3(csa3[0], csa3[1], csa3[2]);
    wire [31:0] csa4_c = carry3(csa3[0], csa3[1], csa3[2]);
    always_ff @(posedge clk) begin
        if (!RST_N) begin
            csa4_sum   <= '0;
            csa4_carry <= '0;
        end else begin
            csa4_sum   <= sum3(csa4_s, csa4_c, csa3[3]);
            csa4_carry <= carry3(csa4_s, csa4_c, csa3[3]);
        end
    end

    // Stages 5..8: add the final two rows a byte per stage.
    // Unprocessed upper bytes and completed lower bytes travel with the carry.
    logic [23:0] add5_a, add5_b;
    logic [7:0] add5_low;
    logic add5_carry;
    logic [15:0] add6_a, add6_b, add6_low;
    logic add6_carry;
    logic [7:0] add7_a, add7_b;
    logic [23:0] add7_low;
    logic add7_carry;
    logic signed [31:0] product;

    wire [8:0] byte0 = {1'b0, csa4_sum[7:0]} + {1'b0, csa4_carry[7:0]};
    wire [8:0] byte1 = {1'b0, add5_a[7:0]} + {1'b0, add5_b[7:0]} + {8'b0, add5_carry};
    wire [8:0] byte2 = {1'b0, add6_a[7:0]} + {1'b0, add6_b[7:0]} + {8'b0, add6_carry};
    wire [8:0] byte3 = {1'b0, add7_a} + {1'b0, add7_b} + {8'b0, add7_carry};

    always_ff @(posedge clk) begin
        if (!RST_N) begin
            add5_a <= '0; add5_b <= '0; add5_low <= '0; add5_carry <= '0;
            add6_a <= '0; add6_b <= '0; add6_low <= '0; add6_carry <= '0;
            add7_a <= '0; add7_b <= '0; add7_low <= '0; add7_carry <= '0;
            product <= '0;
            pipeline_valid <= '0;
        end else begin
            add5_a     <= csa4_sum[31:8];
            add5_b     <= csa4_carry[31:8];
            add5_low   <= byte0[7:0];
            add5_carry <= byte0[8];

            add6_a     <= add5_a[23:8];
            add6_b     <= add5_b[23:8];
            add6_low   <= {byte1[7:0], add5_low};
            add6_carry <= byte1[8];

            add7_a     <= add6_a[15:8];
            add7_b     <= add6_b[15:8];
            add7_low   <= {byte2[7:0], add6_low};
            add7_carry <= byte2[8];

            product <= {byte3[7:0], add7_low};
            pipeline_valid <= {pipeline_valid[PIPE_STAGES-2:0], accept_mult};
        end
    end

    // Reserve capacity on acceptance, rather than waiting for memory writes.
    // Advance every arithmetic/valid stage even during producer pauses.
    always_comb begin
        RDY_mult      = !draining && (accepted_count < 7'd64);
        RDY_blockRead = draining;
        accept_mult   = RST_N && EN_mult && RDY_mult;
        accept_read   = RST_N && EN_blockRead && RDY_blockRead;
        EN_writeMem   = RST_N && pipeline_valid[PIPE_STAGES-1];
        writeMem_addr = landed_count[5:0];
        writeMem_val  = product;
        EN_readMem    = accept_read;
        readMem_addr  = read_ptr;
        memVal_data   = readMem_val;
    end

    always_ff @(posedge clk) begin
        if (!RST_N) begin
            accepted_count <= '0;
            landed_count   <= '0;
            read_ptr       <= '0;
            draining       <= '0;
            VALID_memVal   <= '0;
        end else begin
            VALID_memVal <= EN_readMem;
            if (accept_mult)
                accepted_count <= accepted_count + 7'd1;
            if (EN_writeMem) begin
                landed_count <= landed_count + 7'd1;
                if (landed_count == 7'd63) draining <= 1'b1;
            end
            if (accept_read) begin
                if (read_ptr == 6'd63) begin
                    accepted_count <= '0;
                    landed_count   <= '0;
                    read_ptr       <= '0;
                    draining       <= 1'b0;
                end else begin
                    read_ptr <= read_ptr + 6'd1;
                end
            end
        end
    end
endmodule : mkMultBuff
