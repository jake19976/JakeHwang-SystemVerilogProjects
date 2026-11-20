module task2(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

	logic rst_n;
    assign rst_n = KEY[3];

	logic [7:0] s_addr;
    logic [7:0] s_data_in;
    logic [7:0] s_data_out;
    logic s_wren;
    
	s_mem s ( /* connect ports */ 
		.address (s_addr),
        .clock   (CLOCK_50),
        .data    (s_data_in),
        .wren    (s_wren),
        .q       (s_data_out));

    // your code here
	logic init_en, init_rdy;
    logic [7:0] init_addr, init_wrdata;
    logic init_wren;

	init i (
        .clk    (CLOCK_50),
        .rst_n  (rst_n),
        .en     (init_en),
        .rdy    (init_rdy),
        .addr   (init_addr),
        .wrdata (init_wrdata),
        .wren   (init_wren));

	logic ksa_en, ksa_rdy;
    logic [7:0] ksa_addr, ksa_wrdata;
    logic ksa_wren;
	logic [23:0] ksa_key;

	assign ksa_key[9:0] = SW[9:0];
    assign ksa_key[23:10] = 14'd0;

	ksa k (
        .clk    (CLOCK_50),
        .rst_n  (rst_n),
        .en     (ksa_en),
        .rdy    (ksa_rdy),
        .key    (ksa_key),
        .addr   (ksa_addr),
        .rddata (s_data_out),
        .wrdata (ksa_wrdata),
        .wren   (ksa_wren));

	typedef enum logic [1:0] {INIT, KSA, DONE} state_t;
	state_t state, next_state;
	
	always_ff @(posedge CLOCK_50) begin
        if (!rst_n)
            state <= INIT;
        else
            state <= next_state;
    	end

	always_comb begin
		next_state = state;
		init_en = 1'b0;
        ksa_en  = 1'b0;
		 // Default S memory is idle
		s_addr  = 8'd0;
        s_data_in = 8'd0;
        s_wren  = 1'b0;

		case (state)
            INIT: begin
                init_en = 1'b1;

                // S memory driven by init
                s_addr    = init_addr;
                s_data_in = init_wrdata;
            	s_wren    = init_wren;

            	if (init_rdy) 
                	next_state = KSA;	
            end

			KSA: begin
            	ksa_en = 1'b1;

            	// S memory driven by ksa
            	s_addr    = ksa_addr;
            	s_data_in = ksa_wrdata;
            	s_wren    = ksa_wren;

            	if (ksa_rdy) 
            		next_state = DONE;
            	end
			DONE: ;

			default: next_state = INIT;
        endcase
	end


endmodule: task2
