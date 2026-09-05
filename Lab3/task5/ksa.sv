module ksa(input logic clk, input logic rst_n,
           input logic en, output logic rdy,
           input logic [23:0] key,
           output logic [7:0] addr, input logic [7:0] rddata, output logic [7:0] wrdata, output logic wren);

    // your code here
	logic [7:0] j, i, s_i, s_j, i_next, j_next, s_i_next, s_j_next;
	typedef enum logic[3:0]{
	IDLE, request_s_i, get_s_i, request_s_j, 
	get_s_j, write_s_i, write_s_j, update_j, update_i, DONE} state_t; state_t state, next_state;
	
	 always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            i       <= 8'd0;
            j       <= 8'd0;
            s_i     <= 8'd0;
            s_j     <= 8'd0;
        end else begin
            state   <= next_state;
            i       <= i_next;
            j       <= j_next;
            s_i     <= s_i_next;
            s_j     <= s_j_next;
        end
    end

	always_comb begin
		next_state = state;
		i_next = i;
		j_next = j;
		s_i_next = s_i;
		s_j_next = s_j;
		addr = 0;
		wrdata = 0;
		wren = 0;
		rdy = 0;
		case(state) 
			IDLE: begin
				rdy = 1'b1;

				if(en==1) begin
					i_next = 0;
					j_next = 0;
					s_i_next = 0;
					s_j_next = 0;
					rdy = 0;
					next_state = request_s_i;	
				end
				else begin
					next_state = IDLE;
					rdy = 1;
				end
			end
			request_s_i: begin
				addr = i;
				next_state = get_s_i;
			end
			get_s_i: begin
				s_i_next = rddata; //read from s
				next_state = update_j;
			end

			update_j: begin
				next_state = request_s_j;
				if(i%3 == 2)
					j_next = (j + s_i + key[7:0]) % 256;	
				else if(i%3 ==1)
					j_next = (j + s_i + key[15:8]) % 256;
				else if(i%3 ==0)
					j_next = (j + s_i + key[23:16]) % 256;
			end
			request_s_j: begin
				next_state = get_s_j;	
				addr = j;
			end
			get_s_j: begin
				s_j_next = rddata; //read from s
				next_state = write_s_i;
			end
			write_s_i: begin
				next_state = write_s_j;
				addr = i;
				wrdata = s_j;
				wren = 1;
			end
			write_s_j: begin
				next_state = update_i;
				addr = j;
				wrdata = s_i;
				wren = 1;
			end
			update_i: begin
				if (i < 255) begin
					i_next = i + 1;
					next_state = request_s_i;
				end
				else
					next_state = DONE;
			end
			DONE: begin
				rdy = 1;
				if (!en)
                    			next_state = IDLE;
			end
			default: begin
                		next_state = IDLE;
            		end
		endcase
	end
	
	
endmodule: ksa