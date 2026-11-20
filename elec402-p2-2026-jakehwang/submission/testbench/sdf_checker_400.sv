
// sdf_checker_400.sv -- ELEC 402 2026 Project 2 (REVISED). 400 MHz SDF checker.
// Top module must stay mkMultBuff_sdf_checker_400. Clock fixed at 2.5 ns.
// bob.py passes +sdf_file=submission/outputs/mkMultBuff_400_map.sdf at run time.
// An X on memVal_data after VALID_memVal means a timing violation in your netlist.
//
// Copy to submission/testbench/ and write your gate-level fill/drain checker.
// Tip: launch (drive) your inputs on the rising edge, but sample the outputs on the falling edge instead of the rising edge.

`timescale 1ns/1ps

module mkMultBuff_sdf_checker_400;

    localparam real HALF_NS = 1.25;   // 2.5 ns period -> 400 MHz
    localparam int  N = 32;

    // Added checker state: reference products are computed independently of DUT.
    localparam integer REQUIRED_BATCHES = 4;
    logic [N-1:0] expected [0:63];
    // Diagnostic metadata only; does not affect stimulus or pass/fail criteria.
    logic [15:0] expected_a [0:63], expected_b [0:63];
    realtime accepted_at [0:63];
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
    bit smoke_mode = 0;

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
        .EN_mult(EN_mult), .mult_input0(mult_input0), .mult_input1(mult_input1),
        .RDY_mult(RDY_mult),
        .EN_blockRead(EN_blockRead), .RDY_blockRead(RDY_blockRead),
        .VALID_memVal(VALID_memVal),
        .memVal_data(memVal_data),
        .EN_writeMem(EN_writeMem), .writeMem_addr(writeMem_addr),
        .writeMem_val(writeMem_val),
        .EN_readMem(EN_readMem), .readMem_addr(readMem_addr),
        .readMem_val(readMem_val)
    );

    memory_wrapper_2port #(.DEPTH(64), .LOGDEPTH(6), .WIDTH(N), .MEMTYPE(0)) MEM (
        .clkA(clk), .aA(readMem_addr), .cenA(~EN_readMem), .q(readMem_val),
        .clkB(clk), .aB(writeMem_addr), .cenB(~EN_writeMem), .d(writeMem_val)
    );

    initial clk = 0;
    always #(HALF_NS * 1ns) clk = ~clk;

    initial begin
        string sdf_path;
        if ($value$plusargs("sdf_file=%s", sdf_path))
            $sdf_annotate(sdf_path, DUT, , , "MAXIMUM");
    end

    initial begin
        integer i;
        integer seed;
        integer seed_discard;
        string required_sdf;
        integer sdf_fd;
        RST_N = 0;
        EN_mult = 0;
        EN_blockRead = 0;
        mult_input0 = $urandom;
        mult_input1 = $urandom;
        if ($value$plusargs("seed=%d",seed)) seed_discard = $urandom(seed);
        smoke_mode = $test$plusargs("rtl_smoke");

        if (!smoke_mode) begin
            if (!$value$plusargs("sdf_file=%s",required_sdf))
                fail("SDF run requires +sdf_file=<path>; use +rtl_smoke only for functional debugging");
            sdf_fd = $fopen(required_sdf,"r");
            if (sdf_fd == 0) fail("cannot open SDF file");
            $fclose(sdf_fd);
`ifdef __ICARUS__
            fail("use QuestaSim for actual SDF simulation");
`endif
        end

        checker_started = 1;
        reset_checker();
        // Reset while partial fill has accepted products still outstanding.
        repeat (11) step(1,1,0,$urandom,$urandom);
        reset_checker();
        // Reset during partial drain and then prove a new batch works.
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
                // Extra input offers while full must not become accepted transactions.
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
        if (smoke_mode) $display("RTL SMOKE PASS (NO SDF TIMING CLAIM): %0d responses",responses);
        else $display("ALL PASS: %0d complete batches; %0d checked responses",REQUIRED_BATCHES,responses);
        $finish;
        // TODO: fill/drain the memory under SDF annotation; flag any X on
        //       memVal_data as a timing violation; print "ALL PASS" on success.
        $display("TODO: implement sdf_checker_400");
        $finish;
    end


    // Capture only; no stimulus, timing, or pass/fail changes.
    initial begin
        $dumpfile("sdf_400_trace.vcd");
        $dumpvars(0,DUT);
    end

    task automatic fail(input string reason);
        $error("CHECK FAIL: %s at %0t", reason, $time);
        $fatal(1, "Checker stopped");
    endtask

    // Record exactly the transfers sampled by DUT and memory at this edge.
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
                if ((^{RDY_mult,RDY_blockRead,EN_writeMem,EN_readMem}) === 1'bx) begin
                    $display("CONTROL DEBUG: time=%0t cycle=%0d RST_N=%b EN_mult=%b EN_blockRead=%b",$realtime,cycles,RST_N,EN_mult,EN_blockRead);
                    $display("CONTROL DEBUG: RDY_mult=%b RDY_blockRead=%b EN_writeMem=%b EN_readMem=%b VALID_memVal=%b",RDY_mult,RDY_blockRead,EN_writeMem,EN_readMem,VALID_memVal);
                    $display("CONTROL DEBUG: accepted=%0d written=%0d read_count=%0d completed_batches=%0d",accepted,written,read_count,batches);
                    $dumpflush;
                    fail("unknown handshake or memory enable");
                end
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
                    expected_a[accepted] = mult_input0;
                    expected_b[accepted] = mult_input1;
                    accepted_at[accepted] = $realtime;
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
                    if (writeMem_val !== expected[written]) begin : write_diagnostics
                        integer j;
                        $display("WRITE DEBUG: time=%0t cycle=%0d completed_batches=%0d accepted=%0d written=%0d", $realtime,cycles,batches,accepted,written);
                        $display("WRITE DEBUG: RST_N=%b EN_writeMem=%b address=%0d",RST_N,EN_writeMem,writeMem_addr);
                        $display("WRITE DEBUG: A=%0d (hex %h), B=%0d (hex %h), accepted_at=%0t",$signed(expected_a[written]),expected_a[written],$signed(expected_b[written]),expected_b[written],accepted_at[written]);
                        $display("WRITE DEBUG: expected=%h actual=%h xor=%h actual_has_XZ=%b",expected[written],writeMem_val,(expected[written]^writeMem_val),((^writeMem_val) === 1'bx));
                        for (j=0;j<accepted;j=j+1) begin
                            if ((j >= written-3) && (j <= written+3))
                                $display("WRITE DEBUG: nearby slot=%0d A=%h B=%h product=%h",j,expected_a[j],expected_b[j],expected[j]);
                            if (writeMem_val === expected[j])
                                $display("WRITE DEBUG: actual matches expected slot=%0d",j);
                        end
                        fail("wrong/unknown write product");
                    end
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




endmodule : mkMultBuff_sdf_checker_400




