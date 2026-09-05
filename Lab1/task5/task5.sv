// This module contains a Verilog description of the top level module
// Assuming you don't modify the inputs and outputs of the various submodules,
// you should not have to modify anything in this file.

module task5(input logic CLOCK_50, input logic [3:0] KEY, output logic [9:0] LEDR,
            output logic [6:0] HEX5, output logic [6:0] HEX4, output logic [6:0] HEX3,
            output logic [6:0] HEX2, output logic [6:0] HEX1, output logic [6:0] HEX0);

// some local signals 

logic fast_clock, slow_clock, resetb, clock_tick;
logic load_pcard1, load_pcard2, load_pcard3;
logic load_dcard1, load_dcard2, load_dcard3;
logic [3:0] pscore, dscore;
logic [3:0] pcard3;
logic [11:0] fifo_wdata;
logic [11:0] fifo_rdata;
logic fifo_full, fifo_empty;

assign resetb = KEY[3];
assign slow_clock = KEY[0];
assign fast_clock = CLOCK_50;
assign fifo_wdata = {pscore, dscore, pcard3};

// instantiate the datapath

datapath dp(.slow_clock(slow_clock),
            .fast_clock(fast_clock),
            .resetb(resetb),
            .load_pcard1(load_pcard1),
            .load_pcard2(load_pcard2),
            .load_pcard3(load_pcard3),
            .load_dcard1(load_dcard1),
            .load_dcard2(load_dcard2),
            .load_dcard3(load_dcard3),
            .dscore_out(dscore),
            .pscore_out(pscore),
            .pcard3_out(pcard3),
            .HEX5(HEX5),
            .HEX4(HEX4),
            .HEX3(HEX3),
            .HEX2(HEX2),
            .HEX1(HEX1),
            .HEX0(HEX0));

assign LEDR[3:0] = pscore;
assign LEDR[7:4] = dscore;

// instantiate the state machine

statemachine sm(.slow_clock(slow_clock),
                .resetb(resetb),
                .dscore(dscore),
                .pscore(pscore),
                .pcard3(pcard3),
                .load_pcard1(load_pcard1),
                .load_pcard2(load_pcard2),
                .load_pcard3(load_pcard3),						  
                .load_dcard1(load_dcard1),
                .load_dcard2(load_dcard2),
                .load_dcard3(load_dcard3),	
                .player_win_light(LEDR[8]), 
                .dealer_win_light(LEDR[9]));

// Instantiate the debouncer

debouncer db(.clock(fast_clock),
            .slow_clock(slow_clock),
            .resetb(resetb),
            .clock_tick(clock_tick));

// Instantiate the custom Async FIFO
baccarat_async_fifo #(
    .DATA_WIDTH(12),
    .ADDR_WIDTH(3)
) game_buffer (
    .wclk(slow_clock),         
    .wrst_n(resetb),
    .w_en(1'b1),                 
    .wdata(fifo_wdata),
    
    .rclk(fast_clock),           
    .rrst_n(resetb),
    .r_en(!fifo_empty),         
    .rdata(fifo_rdata),
    
    .wfull(fifo_full),
    .rempty(fifo_empty)
);

logic [3:0] fast_pscore, fast_dscore, fast_pcard3;
assign {fast_pscore, fast_dscore, fast_pcard3} = fifo_rdata;

endmodule
