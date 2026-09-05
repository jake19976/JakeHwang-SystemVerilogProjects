`timescale 1ns/1ps

//Randomizaition check macro
`define SV_RAND_CHECK(r) \
	do begin \
		if (!(r)) begin \
			$display("%s: %0d: Randomization failed \"%s\"", \
			`__FILE__, `__LINE__, `"r`");\
			$finish;\
		end \
	end while (0)

//Defining a clocking block
interface MyBus (input logic slow_clock);
    logic resetb;
    logic [3:0] dscore, pscore, pcard3;
    logic load_pcard1, load_pcard2, load_pcard3;
    logic load_dcard1, load_dcard2, load_dcard3;
    logic player_win_light, dealer_win_light;

    //For this clocking block, we are driving dscore, pscore, pcard3 and resetb
    //We take the value of other inputs
    clocking cb @(posedge slow_clock);

        default input #1step output #1step; //Clock skew
        //input in clocking block means output produced from the DUT
        input load_pcard1, load_pcard2, load_pcard3;
        input load_dcard1, load_dcard2, load_dcard3;
        input player_win_light, dealer_win_light;

        //output in clocking block means input given to the DUT
        output resetb, dscore, pscore, pcard3;
    endclocking
endinterface

// Generates Transaction about last number of card for player/dealer
class RoundTrans;
    rand bit [3:0] pscore;
    rand bit [3:0] dscore;
    rand bit [3:0] pcard3;

    //Constraint about the score of player/dealer: 0~9
    constraint c_range{
        pscore inside {[0:9]};
        dscore inside {[0:9]};
        pcard3 inside {[0:9]};
    }

    function void display(string tag = "tr");
        $display("[%0t] %s pscore = %0d dscore = %0d pcard3 = %0d", $time, tag, pscore, dscore, pcard3);
    endfunction
endclass

//Generate how many tests shouloadd be covered (default 10)
//During each round generate different handle tr and put into mailbox
//Which will be further delivered to Driver
class Generator;
    mailbox #(RoundTrans) gen2drv;

    function new (mailbox #(RoundTrans) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    task run(int rounds = 10);
        RoundTrans tr;
        repeat (rounds) begin
            tr = new();
            `SV_RAND_CHECK(tr.randomize());
            tr.display("GN");
            gen2drv.put(tr);
        end
    endtask
endclass

//Driver get data generated from Generator (type RoundTrans)
//Put data into clocking block to drive them through DUT
class Driver;
    virtual MyBus bus;
    mailbox #(RoundTrans) gen2drv;
    mailbox #(RoundTrans) drv_snap;

    function new (virtual MyBus bus, mailbox #(RoundTrans) gen2drv, mailbox #(RoundTrans) drv_snap);
        this.bus = bus;
        this.gen2drv = gen2drv;
        this.drv_snap = drv_snap;
    endfunction

    task run_a_round(RoundTrans tr);
        bus.cb.pscore <= tr.pscore;
        bus.cb.dscore <= tr.dscore;
        bus.cb.pcard3 <= tr.pcard3;

        bus.resetb <= 0;
        repeat (2) @(bus.cb);
        bus.resetb <= 1;

        repeat (9) @(bus.cb);
    endtask

    task run();
        RoundTrans tr;
        forever begin
            gen2drv.get(tr);
            tr.display("DR");
            drv_snap.put(tr);
            run_a_round(tr);
        end
    endtask
endclass

//Monitor structure to take DUT output and ready to put into mailbox
//Complete output signal of the DUT
typedef struct packed {
    int state;
    bit load_p1, load_p2, load_p3;
    bit load_d1, load_d2, load_d3;
    bit player_win_light, dealer_win_light;
} out_sample_t;

//Observe output signal from DUT
class Monitor;
    virtual MyBus bus;
    mailbox #(out_sample_t) mon2sb;

    int state_in_round;
    bit in_round;

    bit arm_start;

    function new (virtual MyBus bus, mailbox #(out_sample_t) mon2sb);
        this.bus = bus;
        this.mon2sb = mon2sb;
        this.state_in_round = 0;
        this.in_round = 0;
    endfunction

    task run();
        forever begin
            //Observe the resetb from DUT to determine the testing round start
            @(bus.cb);
            if (bus.resetb == 1 && !in_round && !arm_start)
                arm_start = 1;
            else if (arm_start) begin
                in_round = 1;
                state_in_round = 0;
                arm_start = 0;
            end

            //Store DUT output to out_sample_t type, put into mailbox and forward to scoreboard
            if (in_round) begin
                out_sample_t s;
                state_in_round++;
                s.state = state_in_round;
                s.load_p1 = bus.cb.load_pcard1;
                s.load_p2 = bus.cb.load_pcard2;
                s.load_p3 = bus.cb.load_pcard3;
                s.load_d1 = bus.cb.load_dcard1;
                s.load_d2 = bus.cb.load_dcard2;
                s.load_d3 = bus.cb.load_dcard3;
                s.player_win_light = bus.cb.player_win_light;
                s.dealer_win_light = bus.cb.dealer_win_light;
                mon2sb.put(s);

                if (state_in_round >= 9) begin
                    in_round = 0;
                end
            end
        end
    endtask
endclass

//Scoreboard act as a final judge of the legitimacy of DUT
class Scoreboard;
    mailbox #(out_sample_t) mon2sb;
    mailbox #(RoundTrans) drv_snap;

    //Obtain monitor (real output from DUT) and driver (Original Input Stimuli) from mailbox
    function new (mailbox #(out_sample_t) mon2sb, mailbox #(RoundTrans) drv_snap);
        this.mon2sb = mon2sb;
        this.drv_snap = drv_snap;
    endfunction

    //Check which state should the DUT be in right now
    function string state_of_cycle (int k, RoundTrans tr);
        // k=1->P1, 2->D1, 3->P2, 4->D2, 5->P3/OVER, 6->D3/OVER, 7->OVER
        if (k == 1) return "P1";
        if (k == 2) return "D1";
        if (k == 3) return "P2";
        if (k == 4) return "D2";
        if (k == 5) begin
        if (tr.pscore >= 8 || tr.dscore >= 8) return "OVER"; // Natural Card
            else return "P3";
        end
        if (k == 6) begin
            if (tr.pscore >= 8 || tr.dscore >= 8) return "OVER";
            else return "D3";
            end
        if (k >= 7) return "OVER";
        return "N/A";
    endfunction

    function void expected_at_cycle (int k, RoundTrans tr,
                                output bit loadp1, loadp2, loadp3,
                                output bit loadd1, loadd2, loadd3,
                                output bit player_win_light, dealer_win_light);
        string st = state_of_cycle (k, tr);
        loadp1 = 0; loadp2 = 0; loadp3 = 0;
        loadd1 = 0; loadd2 = 0; loadd3 = 0;
        player_win_light = 0; dealer_win_light = 0;
        if (st == "P1") loadp1 = 1;
        else if (st == "D1") loadd1 = 1;
        else if (st == "P2") loadp2 = 1;
        else if (st == "D2") loadd2 = 1;
        else if (st == "P3") loadp3 = (tr.pscore<=5);
        else if (st == "D3") begin
            bit pcard3 = (tr.pscore <= 5);
            if (pcard3) begin
                case (tr.dscore)
                    7: loadd3 = 0;
                    6: loadd3 = (tr.pcard3 == 6 || tr.pcard3 == 7);
                    5: loadd3 = (tr.pcard3 >= 4 && tr.pcard3 <= 7);
                    4: loadd3 = (tr.pcard3 >= 2 && tr.pcard3 <= 7);
                    3: loadd3 = (tr.pcard3 != 8);
                    default: loadd3 = 1;
                endcase
            end
            else begin
                loadd3 = (tr.dscore <= 5);
            end
        end
        else if (st == "OVER") begin
            if (tr.pscore > tr.dscore) player_win_light = 1;
            else if (tr.dscore > tr.pscore) dealer_win_light = 1;
            else begin player_win_light = 1; dealer_win_light = 1; end
        end
    endfunction

    task check_one_round (RoundTrans tr);
        out_sample_t s;

        for (int i = 1; i <= 9; i++) begin
            bit loadp1, loadp2, loadp3, loadd1, loadd2, loadd3, player_win_light, dealer_win_light;
            expected_at_cycle (i, tr, loadp1, loadp2, loadp3, loadd1, loadd2, loadd3, player_win_light, dealer_win_light);

            mon2sb.get(s);

            if (s.load_p1!==loadp1 || s.load_p2!==loadp2 || s.load_p3!==loadp3 ||
                s.load_d1!==loadd1 || s.load_d2!==loadd2 || s.load_d3!==loadd3 ||
                s.player_win_light !== player_win_light || s.dealer_win_light !== dealer_win_light) begin
                    $error("[%0t][SB] Cycle %0d mismatch! exp(loadp1=%0b loadp2=%0b loadp3=%0b loadd1=%0b loadd2=%0b loadd3=%0b pl=%0b dl=%0b) got(loadp1=%0b loadp2=%0b loadp3=%0b loadd1=%0b loadd2=%0b loadd3=%0b pl=%0b dl=%0b)",
                    $time, i, loadp1,loadp2,loadp3,loadd1,loadd2,loadd3,player_win_light,dealer_win_light,
                    s.load_p1,s.load_p2,s.load_p3,s.load_d1,s.load_d2,s.load_d3,s.player_win_light,s.dealer_win_light);
            end
            else begin
                $display("[%0t][SB] Cycle %0d OK (state=%s)", $time, i, state_of_cycle(i,tr));
            end
        end
    endtask
    

    task run (int round = 10);
        RoundTrans tr;
        repeat (round) begin
            drv_snap.get(tr);
            tr.display("SB");
            check_one_round(tr);
        end
        $display("[%0t][SB] All rounds checked.", $time);
        $finish;
    endtask
endclass

module tb;

    logic slow_clock = 0;
    always #5 slow_clock = ~slow_clock;

    MyBus bus (.slow_clock(slow_clock));
    statemachine dut (
        .slow_clock(slow_clock),
        .resetb(bus.resetb),
        .dscore(bus.dscore),
        .pscore(bus.pscore),
        .pcard3(bus.pcard3),
        .load_pcard1(bus.load_pcard1),
        .load_pcard2(bus.load_pcard2),
        .load_pcard3(bus.load_pcard3),
        .load_dcard1(bus.load_dcard1),
        .load_dcard2(bus.load_dcard2),
        .load_dcard3(bus.load_dcard3),
        .player_win_light(bus.player_win_light),
        .dealer_win_light(bus.dealer_win_light)
    );

    mailbox #(RoundTrans) gen2drv = new();
    mailbox #(out_sample_t) mon2sb = new();
    mailbox #(RoundTrans) drv2sb = new();

    Generator gen;
    Driver drv;
    Monitor mon;
    Scoreboard sb;

    initial begin
        gen = new(gen2drv);
        drv = new(bus, gen2drv, drv2sb);
        mon = new(bus, mon2sb);
        sb = new(mon2sb, drv2sb);

        bus.resetb <= 0;
        bus.cb.pscore <= 0;
        bus.cb.dscore <= 0;
        bus.cb.pcard3 <= 0;

        fork 
            gen.run(10);
            drv.run();
            mon.run();
            sb.run(10);
        join
	    
        #50 $display("[%0t] TB finished", $time);
        $finish;
    end
endmodule