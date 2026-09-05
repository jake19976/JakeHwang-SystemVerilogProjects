module task1(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    // your code here

	logic rst_n;
   	assign rst_n = KEY[3];

	logic en, rdy, wren;
	logic [7:0] addr, wrdata;
	logic [7:0] s_q;    // read data from S memory
	logic started; // to send only ONE en pulse after reset
	logic[7:0] mem_addr;
	
	init dut(
	.clk(CLOCK_50),
	.rst_n(rst_n),
	.en(en),
	.rdy(rdy),
	.addr(addr),
	.wrdata(wrdata),
	.wren(wren)
	);
	
	
	// address mux: when writing, use init's addr; otherwise use switches
    	assign mem_addr = (wren) ? addr : SW[7:0];

    	s_mem s( /* connect ports */
		.address(mem_addr),
		.clock(CLOCK_50),
		.data(wrdata),
		.wren(wren),
		.q(s_q));
	
	
	always_ff@(posedge CLOCK_50 or negedge rst_n) begin
		if(!rst_n) begin
			en <= 1'b0;
			started <= 1'b0;
		end 
		else begin
		if(!started && rdy) begin
			en <= 1'b1;
			started <= 1'b1; //allows the init to be initialized only once
		end
		else 
			en <= 1'b0;
		end
	end				

    // your code here

endmodule: task1
