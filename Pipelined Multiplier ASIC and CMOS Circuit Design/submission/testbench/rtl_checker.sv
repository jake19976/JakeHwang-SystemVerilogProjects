// rtl_checker.sv -- ELEC 402 2026 Project 2. Top: mkMultBuff_tb. Copy to submission/testbench/.
// The harness below wires the DUT to the memory and makes a clock (CLK_HALF_NS 1.25 = 400 MHz, 0.625 = 800 MHz).
// Drive fill/drain, scoreboard every product read out. See README "Testbench requirements" for what to cover.

`timescale 1ns/1ps

module mkMultBuff_tb #(
    parameter real CLK_HALF_NS = 1.25, //currently 400MHZ, change it to 1.25 for 800MHZ
    parameter int  N = 32
);

    // Added checker state: reference products are computed independently of DUT.
    localparam integer REQUIRED_BATCHES = 8;
    logic [N-1:0] expected [0:63];
    integer accepted = 0, written = 0, read_count = 0;
    integer responses = 0, batches = 0, cycles = 0;
    integer producer_pauses = 0, consumer_pauses = 0, full_offers = 0;
    bit response_due = 0;
    logic [N-1:0] response_expected;
    bit checker_started = 0;
    bit reset_sampled = 1;
    // Ignore the simulator's possible X-to-0 clock transition at time zero.
    bit sampled_clock_edge = 0;
    bit [4:0] boundary_seen = 0;

    logic clk, RST_N;

    logic EN_mult;
    logic [15:0] mult_input0, mult_input1;
    logic RDY_mult;

    logic EN_blockRead;
    logic RDY_blockRead;
    logic VALID_memVal;
    logic [N-1:0] memVal_data;

    logic EN_writeMem, EN_readMem;
    logic [5:0] writeMem_addr, readMem_addr;
    logic [N-1:0] writeMem_val, readMem_val;

    mkMultBuff #(.N(N)) DUT (
        .clk(clk), .RST_N(RST_N),
        .EN_mult(EN_mult),
        .mult_input0(mult_input0), .mult_input1(mult_input1),
        .RDY_mult(RDY_mult),
        .EN_blockRead(EN_blockRead), .RDY_blockRead(RDY_blockRead),
        .VALID_memVal(VALID_memVal), .memVal_data(memVal_data),
        .EN_writeMem(EN_writeMem), .writeMem_addr(writeMem_addr),
        .writeMem_val(writeMem_val),
        .EN_readMem(EN_readMem), .readMem_addr(readMem_addr),
        .readMem_val(readMem_val)
    );

    // The memory belongs to the testbench, not to mkMultBuff.
    memory_wrapper_2port #(
        .DEPTH(64), .LOGDEPTH(6), .WIDTH(N), .MEMTYPE(0)
    ) MEM (
        .clkA(clk), .aA(readMem_addr), .cenA(~EN_readMem), .q(readMem_val),
        .clkB(clk), .aB(writeMem_addr), .cenB(~EN_writeMem), .d(writeMem_val)
    );

    initial clk = 0;
    always #(CLK_HALF_NS * 1ns) clk = ~clk;

    initial begin
        string sdf_path;
        if ($value$plusargs("sdf_file=%s", sdf_path))
            $sdf_annotate(sdf_path, DUT, , , "MAXIMUM");
    end

    initial begin
        integer i;
        integer seed;
        integer seed_discard;
        RST_N = 0;
        EN_mult = 0;
        EN_blockRead = 0;
        mult_input0 = $urandom;
        mult_input1 = $urandom;
        if ($value$plusargs("seed=%d",seed)) seed_discard = $urandom(seed);

        checker_started = 1;
        reset_checker();
        // Reset while partial fill has accepted products still outstanding.
        repeat (11) step(1,1,0,$urandom,$urandom);
        reset_checker();
        // Reset during partial drain and then prove a fresh batch works.
        begin : fill_before_reset
            logic [15:0] a,b;
            bit send;
            integer tick;
            bit pauses;
            pauses = 1'b1;
            tick = 0;
            while (accepted < 64) begin
                a = $urandom; b = $urandom;
                case (accepted)
                    0: begin a=16'h8000; b=16'h8000; end
                    1: begin a=16'hffff; b=16'h0001; end
                    2: begin a=16'h0000; b=16'h7fff; end
                    3: begin a=16'h7fff; b=16'h7fff; end
                    4: begin a=16'hffff; b=16'hffff; end
                endcase
                send = !pauses || ((tick % 7 != 0) && ($urandom_range(0,3) != 0));
                step(1,send,1,a,b); // Read offers during fill must be ignored.
                tick = tick + 1;
            end
            // Stop producer and require all outstanding pipeline work to finish.
            step(1,0,0,0,0);
            while (written < 64) step(1,0,0,0,0);
            // Extra input offers while full must not become accepted transactions.
            repeat (5) step(1,1,0,$urandom,$urandom);
            step(1,0,0,0,0);
        end
        repeat (13) step(1,0,1,0,0);
        reset_checker();
        for (i=0; i<REQUIRED_BATCHES; i=i+1) begin
            begin : fill_full_batch
                logic [15:0] a,b;
                bit send;
                integer tick;
                bit pauses;
                pauses = (i != 0);
                tick = 0;
                while (accepted < 64) begin
                    a = $urandom; b = $urandom;
                    case (accepted)
                        0: begin a=16'h8000; b=16'h8000; end
                        1: begin a=16'hffff; b=16'h0001; end
                        2: begin a=16'h0000; b=16'h7fff; end
                        3: begin a=16'h7fff; b=16'h7fff; end
                        4: begin a=16'hffff; b=16'hffff; end
                    endcase
                    send = !pauses || ((tick % 7 != 0) && ($urandom_range(0,3) != 0));
                    step(1,send,1,a,b); // Read offers during fill must be ignored.
                    tick = tick + 1;
                end
                // Stop producer and require all outstanding pipeline work to finish.
                step(1,0,0,0,0);
                while (written < 64) step(1,0,0,0,0);
                // Extra input offers while full must not become accepted.
                repeat (5) step(1,1,0,$urandom,$urandom);
                step(1,0,0,0,0);
            end
            begin : drain_full_batch
                integer target, tick;
                bit take;
                bit pauses;
                pauses = (i != 0);
                target = batches + 1;
                tick = 0;
                while (batches < target) begin
                    take = !pauses || ((tick % 5 != 0) && ($urandom_range(0,3) != 0));
                    step(1,(read_count < 60),take,$urandom,$urandom);
                    tick = tick + 1;
                end
                // Includes last response after the DUT returns to filling.
                step(1,0,0,0,0);
                repeat (3) step(1,0,0,0,0);
            end
        end
        if (boundary_seen !== 5'b11111) fail("missing signed boundary coverage");
        if (batches != REQUIRED_BATCHES || responses < REQUIRED_BATCHES*64) fail("incomplete batch/response coverage");
        if (producer_pauses == 0 || consumer_pauses == 0 || full_offers == 0)
            fail("missing pause/full coverage");
        $display("ALL PASS: %0d complete batches; %0d checked responses",REQUIRED_BATCHES,responses);
        $finish;
        // TODO: reset, fill the memory with signed products, drain and check,
        //       print "ALL PASS" on success. bob.py greps for "ALL PASS".
        $display("TODO: implement rtl_checker");
        $finish;
    end


    task automatic fail(input string reason);
        $error("CHECK FAIL: %s at %0t", reason, $time);
        $fatal(1, "Checker stopped");
    endtask

    // Record exactly the transfers sampled by DUT and memory at this edge.
    // Drive uses NBA assignments, so these are the previous cycle's inputs.
    always @(posedge clk) begin
        sampled_clock_edge = 1;
        reset_sampled = (RST_N === 1'b0);
        cycles = cycles + 1;
        if (cycles > 200000) fail("watchdog timeout");
        if (checker_started) begin
            if (RST_N === 1'b0) begin
                accepted = 0;
                written = 0;
                read_count = 0;
                response_due = 0;
            end else if (RST_N === 1'b1) begin
                if ((^{RDY_mult,RDY_blockRead,EN_writeMem,EN_readMem}) === 1'bx)
                    fail("unknown handshake or memory enable");
                if (RDY_mult !== ((accepted < 64) && (written < 64)))
                    fail("multiply readiness/capacity");
                if (RDY_blockRead !== (written == 64))
                    fail("read readiness before/after full batch");
                if (EN_readMem !== (EN_blockRead && RDY_blockRead))
                    fail("read request does not match handshake");
                if (EN_writeMem && EN_readMem) fail("read/write overlap");
                if (EN_mult && !RDY_mult) full_offers = full_offers + 1;
                if (!EN_mult && RDY_mult) producer_pauses = producer_pauses + 1;
                if (!EN_blockRead && RDY_blockRead) consumer_pauses = consumer_pauses + 1;
                if (EN_mult && RDY_mult) begin
                    if (accepted >= 64) fail("accepted beyond capacity");
                    expected[accepted] = $signed(mult_input0) * $signed(mult_input1);
                    case ({mult_input0,mult_input1})
                        32'h80008000: boundary_seen[0] = 1;
                        32'hffff0001: boundary_seen[1] = 1;
                        32'h00007fff: boundary_seen[2] = 1;
                        32'h7fff7fff: boundary_seen[3] = 1;
                        32'hffffffff: boundary_seen[4] = 1;
                    endcase
                    accepted = accepted + 1;
                end
                if (EN_writeMem) begin
                    if (written >= accepted || written >= 64) fail("unexpected memory write");
                    if (writeMem_addr !== written[5:0]) fail("write address/order");
                    if (writeMem_val !== expected[written]) fail("wrong/unknown write product");
                    written = written + 1;
                end
                response_due = EN_readMem;
                if (EN_readMem) begin
                    if (written != 64 || read_count >= 64) fail("premature/extra read");
                    if (readMem_addr !== read_count[5:0]) fail("read address/order");
                    response_expected = expected[read_count];
                    read_count = read_count + 1;
                    if (read_count == 64) begin
                        accepted = 0;
                        written = 0;
                        read_count = 0;
                        batches = batches + 1;
                    end
                end
            end else fail("unknown reset");
        end
    end

    // Registered memory response and validity have half a clock to settle.
    always @(negedge clk) begin
        if (checker_started && sampled_clock_edge) begin
            if (reset_sampled) begin
                if ({RDY_mult,RDY_blockRead,EN_writeMem,EN_readMem,VALID_memVal} !== 5'b10000)
                    fail("reset did not restore idle outputs");
                if (writeMem_addr !== 6'd0) fail("reset write address");
            end
            if (VALID_memVal !== response_due) fail("missing/extra/unknown response validity");
            if (response_due) begin
                if (memVal_data !== response_expected) fail("wrong/unknown read product");
                responses = responses + 1;
            end
        end
    end

    // Every step launches on a rising edge and returns after the monitor.
    task automatic step(input bit reset_n, input bit send, input bit take,
                        input logic [15:0] a, input logic [15:0] b);
        @(posedge clk);
        RST_N <= reset_n;
        EN_mult <= send;
        EN_blockRead <= take;
        mult_input0 <= send ? a : $urandom;
        mult_input1 <= send ? b : $urandom;
        @(negedge clk);
        #1ps;
    endtask

    task automatic reset_checker;
        // Reset is synchronous in DUT, but its external transitions need not
        // coincide with clk. Change it after the falling-edge monitor finishes
        // to avoid injecting an ideal, zero-clock-to-Q reset at the active edge.
        @(negedge clk);
        #1ps;
        RST_N <= 1'b0;
        EN_mult <= 1'b0;
        EN_blockRead <= 1'b0;
        step(0,0,0,0,0);
        step(0,0,0,0,0);
        step(0,0,0,0,0);
        // step returns just after a falling edge; release reset here too.
        RST_N <= 1'b1;
        step(1,0,0,0,0);
        step(1,0,0,0,0);
    endtask




endmodule

