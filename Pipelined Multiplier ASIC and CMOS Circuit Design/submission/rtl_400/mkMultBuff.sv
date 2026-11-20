// mkMultBuff.sv -- ELEC 402 2026 Project 2: fill/drain signed 16x16 multiplier buffer.
// Stores products into 64-entry memory (RDY_mult low when full); EN_blockRead & RDY_blockRead drain all 64 in order.
// Active-low synchronous reset (RST_N); latency-insensitive, any multiplier pipeline depth OK.

module mkMultBuff #(parameter N = 32) (
    input logic clk,
    input logic RST_N, // active-low synchronous reset

    // Multiplier / write side
    input logic EN_mult,
    input logic [15:0] mult_input0, // signed operand A (two's complement)
    input logic [15:0] mult_input1, // signed operand B (two's complement)
    output logic RDY_mult,

    // Read / drain side
    input logic EN_blockRead,
    output logic RDY_blockRead,
    output logic VALID_memVal,
    output logic [N-1:0] memVal_data,

    // Memory write port
    output logic EN_writeMem,
    output logic [5:0] writeMem_addr,
    output logic [N-1:0] writeMem_val,

    // Memory read port
    output logic EN_readMem,
    output logic [5:0] readMem_addr,
    input logic [N-1:0] readMem_val
);

    // TODO: implement the fill/drain control logic and instantiate your
    //       pipelined signed multiplier here.

//partial product LL, LH, HL, HH
logic [15:0] pp_ll;
logic signed [17:0] pp_hl, pp_lh;
logic signed [15:0] pp_hh;


logic signed [31:0] sum_lo, sum_hi;

//final product
logic signed [31:0] product;
logic [2:0] pipeline_valid;

//count that's been landed, count that's initiated but still in progress
logic [6:0] accepted_count, landed_count;

//read pointer, draining indicator, 
logic [5:0] read_ptr;
logic draining;
logic accept_mult, accept_read;

always_comb begin //only the values and pipeline change on clock edge, otherwise, wire them
	RDY_mult = !draining && (accepted_count < 7'd64);
	RDY_blockRead = draining;
	accept_mult = RST_N && EN_mult && RDY_mult;
	accept_read = RST_N && EN_blockRead && RDY_blockRead;

	//data stays aligned until memory samples them
	EN_writeMem = pipeline_valid[2] && RST_N; 
	writeMem_addr = landed_count[5:0]; //Landed_count = 0 to 64 accordingly
	writeMem_val  = product;
	EN_readMem    = accept_read; //accept_read not needed, used just for clearer vision 
	readMem_addr  = read_ptr;
	memVal_data = readMem_val;
end

	//Pipeline advances every clock(still advances even when no pair incoming)
	always_ff @(posedge clk) begin
		if(!RST_N) begin
			pp_ll <= 0;
			pp_hl <= 0;
			pp_lh <= 0;
			pp_hh <= 0;
			sum_lo <= 0;
			sum_hi <= 0;
			product <= 0;
			pipeline_valid <= 0;
		end else begin
			
			pp_ll <= mult_input0[7:0] * mult_input1[7:0];
			pp_hl <= $signed({mult_input0[15], mult_input0[15:8]}) * $signed({1'b0, mult_input1[7:0]});
			pp_lh <= $signed({1'b0, mult_input0[7:0]}) * $signed({mult_input1[15], mult_input1[15:8]});
			pp_hh <= $signed(mult_input0[15:8]) * $signed(mult_input1[15:8]);

			sum_lo <= $signed({16'b0, pp_ll}) + ($signed({{14{pp_hl[17]}}, pp_hl}) << 8);
			sum_hi <= ($signed({{14{pp_lh[17]}}, pp_lh}) << 8) + ($signed({{16{pp_hh[15]}}, pp_hh}) << 16);
			product <= sum_lo + sum_hi;
			pipeline_valid <= {pipeline_valid[1:0], accept_mult};
		end
	end

	// Control: fill -> wait for all reserved products -> drain -> fill.
	always_ff @(posedge clk) begin
        	if (!RST_N) begin
            		accepted_count <= 0;
            		landed_count   <= 0;
            		read_ptr       <= 0;
            		draining       <= 0;
            		VALID_memVal   <= 0;
		end else begin
			// Samples the same read request that the memory samples.
        		VALID_memVal <= EN_readMem;

            		if (accept_mult)
                		accepted_count <= accepted_count + 7'd1; //prevent truncated

            		if (EN_writeMem) begin
                		landed_count <= landed_count + 7'd1;
                		// This edge writes address 63. Only now may reads start.
                		if (landed_count == 7'd63)
                    			draining <= 1;
            		end

            		if (accept_read) begin
                		if (read_ptr == 6'd63) begin
                    		// Last read data is returned by the memory on this edge.
                  		accepted_count <= 0;
                    		landed_count   <= 0;
                    		read_ptr       <= 0;
                    		draining       <= 0;
                		end else begin
                    			read_ptr <= read_ptr + 6'd1;
                		end
            		end
		end
	end

endmodule : mkMultBuff
