module init(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            output logic [7:0] addr, output logic [7:0] wrdata, output logic wren);

// your code here

	logic[7:0] i;
	typedef enum logic[1:0]{
	IDLE, WRITE, DONE} state_t; state_t state, next_state;

	always_ff@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			state <= IDLE;
			i <= 8'd0;
		end else begin
			state <= next_state;
			case (state)
                IDLE: begin
                if (en && rdy) begin
                    	i <= 8'd0;         // start from 0 on new request
                	end
                end
                WRITE: begin
                	if (i != 8'd255)
                    	i <= i + 8'd1;     // increment until 255
                end
            endcase
		end
	end

	always_comb begin
		rdy = 1'b0;
		wren = 1'b0;
		next_state = IDLE;
		addr = i;
		wrdata = i;
		case(state)
			IDLE: begin
				rdy = 1'b1;
				if(en == 1'b1)
					next_state = WRITE;
			end
			WRITE: begin
				rdy = 1'b0;
				wren = 1'b1;
				if(i == 8'd255)
					next_state = IDLE;
			end
			default: ;
		endcase
	end		 

endmodule: init