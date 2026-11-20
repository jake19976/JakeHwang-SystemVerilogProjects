module arc4(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);

    // your code here
    typedef enum logic [3:0] {INIT_RDY, INIT_EN, INIT, KSA_RDY, KSA_EN, KSA, PRGA_RDY, PRGA_EN, PRGA, DONE} state_t;
	state_t state, next_state;

    logic [7:0] s_addr;
    logic [7:0] s_data_in;
    logic [7:0] s_data_out;
    logic s_wren;

    s_mem s ( /* connect ports */ 
		.address (s_addr),
        .clock   (clk),
        .data    (s_data_in),
        .wren    (s_wren),
        .q       (s_data_out));

    logic init_en, init_rdy;
    logic [7:0] init_addr, init_wrdata;
    logic init_wren;

    init i( /* connect ports */ 
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (init_en),
        .rdy    (init_rdy),
        .addr   (init_addr),
        .wrdata (init_wrdata),
        .wren   (init_wren));

    ksa k ( /* connect ports */ 
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (ksa_en),
        .rdy    (ksa_rdy),
        .key    (key),
        .addr   (ksa_addr),
        .rddata (s_data_out),
        .wrdata (ksa_wrdata),
        .wren   (ksa_wren));

    logic ksa_en, ksa_rdy;
    logic [7:0] ksa_addr, ksa_wrdata;
    logic ksa_wren;

    logic prga_en, prga_rdy, s_wren_prga;
    logic [7:0] s_address_prga;
    logic [7:0] s_rddata_prga, s_wrdata_prga;

    prga p( /* connect ports */ 
        .clk(clk),
        .rst_n(rst_n),
        .en(prga_en),
        .rdy(prga_rdy),
        .key(key),
        .s_addr(s_address_prga),
        .s_rddata(s_rddata_prga), 
		.s_wrdata(s_wrdata_prga),
        .s_wren(s_wren_prga),
        .ct_addr(ct_addr),
        .ct_rddata(ct_rddata),
        .pt_addr(pt_addr),
        .pt_rddata(pt_rddata), 
		.pt_wrdata(pt_wrdata),
        .pt_wren(pt_wren));

    // your code here
    always_ff @(posedge clk) begin
        if (!rst_n)
            state <= INIT_RDY;
        else
            state <= next_state;
    end

    always_comb begin
		next_state = state;
		init_en = 1'b0;
        ksa_en  = 1'b0;
        prga_en = 1'b0;
		s_addr  = 8'd0;
        s_data_in = 8'd0;
        s_wren  = 1'b0;
        s_rddata_prga = 8'd0;
        rdy = 1'b0;

		case (state)
            INIT_RDY: begin
            	rdy = 1'b1;
					if (en) 
                	next_state = INIT_EN;	
            end

            INIT_EN: begin
                init_en = 1'b1;
                next_state = INIT;	
            end
            INIT: begin
                // S memory driven by init
                s_addr    = init_addr;
                s_data_in = init_wrdata;
            	s_wren    = init_wren;

            	if (init_rdy) 
                	next_state = KSA_RDY;	
            end
			KSA_RDY: begin
            	if (ksa_rdy) 
            		next_state = KSA_EN;
            end
            KSA_EN: begin
            	ksa_en = 1'b1;
            	next_state = KSA;
            end
            KSA: begin
            	// S memory driven by ksa
            	s_addr    = ksa_addr;
            	s_data_in = ksa_wrdata;
            	s_wren    = ksa_wren;

            	if (ksa_rdy)
            		next_state = PRGA_RDY;
            end
            PRGA_RDY: begin
                if (prga_rdy)
                    next_state = PRGA_EN;
            end
            PRGA_EN: begin
                prga_en = 1'b1;
                next_state = PRGA;
            end
            PRGA: begin
                // S memory driven by prga
                s_addr = s_address_prga;
                s_data_in = s_wrdata_prga;
                s_rddata_prga = s_data_out;
                s_wren = s_wren_prga;

                if (prga_rdy)
                    next_state = DONE;
            end
			DONE: begin
				rdy = 1;
				if (en)
				next_state = INIT_EN;   // start a new run for a new key
				else
				next_state = DONE; 
				end

			default: next_state = INIT;
        endcase
	end

endmodule: arc4
