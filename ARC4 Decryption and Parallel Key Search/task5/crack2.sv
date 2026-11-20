module crack2(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata, 
				 output logic [7:0] shared_pt_addr, output logic [7:0]  shared_pt_wrdata,
				output logic shared_pt_wren);

    // State machine definition
    typedef enum logic [4:0] {IDLE, ARC4_RDY, ARC4_EN, ARC4, MSG_LEN_REQ, MSG_LEN_GET, MSG_REQ, MSG_GET, MSG_ASCII, LOOP, CHECK_YES, CHECK_NO, DONE} state_t;
	state_t state, next_state;
    // your code here
    logic [7:0] arc4_ct_addr, arc4_pt_addr;
    logic [7:0] arc4_ct_rddata, arc4_pt_rddata;
    logic [7:0] arc4_pt_wrdata;
    logic arc4_rdy, arc4_pt_wren, arc4_en;

    logic [7:0] pt_addr;
    logic [7:0] pt_rddata;
    logic [7:0] pt_wrdata;
    logic pt_wren;

    logic [7:0] msg_len, msg, i;

    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem2 pt2(
        .address(pt_addr),
        .clock(clk),
        .data(pt_wrdata), 
		.wren(pt_wren),
        .q(pt_rddata));

    arc4 a4(
        .clk(clk),
        .rst_n(rst_n),
        .en(arc4_en),
        .rdy(arc4_rdy),
        .key(key), 
		.ct_addr(arc4_ct_addr),
        .ct_rddata(arc4_ct_rddata),
        .pt_addr(arc4_pt_addr), 
		.pt_rddata(arc4_pt_rddata),
        .pt_wrdata(arc4_pt_wrdata),
        .pt_wren(arc4_pt_wren));

    //Sequential Logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
				i        <= 8'd0;
				msg_len  <= 8'd0;
				msg      <= 8'd0;
				key      <= 24'd0;
				rdy      <= 1'b1;
				key_valid<= 1'b0;
			end
        else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    i <= 0;
                    msg_len <= 0;
                    msg <= 0;
                    key <= 24'd1;
                    if (en)
                        rdy <= 0;
                    else
                        rdy <= 1;
                end
                ARC4_RDY: ;
                ARC4_EN: key_valid <= 0;
                ARC4: ;
                MSG_LEN_REQ: ;
                MSG_LEN_GET: begin
							msg_len <= pt_rddata;
							i       <= 8'd1;
					 end
                MSG_REQ: ;
                MSG_GET: msg <= pt_rddata;
                MSG_ASCII: begin 
                    if ((msg >= 8'h20) && (msg <= 8'h7E)) begin
                        if (i < msg_len)
                            i <= i + 8'd1;
                    end
                    else
                        i <= 8'd0;
                end
                LOOP: begin
                    if (key < 24'hFFFFFF)
                        key <= key + 24'd2;
                end
                CHECK_YES: begin
                    key_valid <= 1'b1;
                    rdy <= 1;
                end
                CHECK_NO: begin
                    key_valid <= 1'b0;
                    rdy <= 1;
                end
                DONE: ;
                default: ;
            endcase
        end
    end

    always_comb begin
        next_state = state;
        arc4_en = 1'b0;
        ct_addr = 8'b0;
        pt_addr = 8'b0;
        pt_wrdata = 8'b0;
        pt_wren = 1'b0;
        arc4_pt_rddata = 8'b0;
        arc4_ct_rddata = 8'b0;
		  shared_pt_addr   = 8'd0;
		  shared_pt_wrdata = 8'd0;
		  shared_pt_wren   = 1'b0;
        case (state)
            IDLE: begin
                if (en)
                    next_state = ARC4_RDY;
                else
                    next_state = IDLE;
            end
            ARC4_RDY: begin
                if (arc4_rdy)
                    next_state = ARC4_EN;
                else
                    next_state = ARC4_RDY;
            end
            ARC4_EN: begin
                arc4_en = 1'b1;
                next_state = ARC4;
            end
            ARC4: begin
                ct_addr = arc4_ct_addr;
		    	pt_addr = arc4_pt_addr;
		        pt_wrdata = arc4_pt_wrdata;
				pt_wren = arc4_pt_wren;
			    arc4_pt_rddata = pt_rddata;
			    arc4_ct_rddata = ct_rddata;
				 shared_pt_addr   = arc4_pt_addr;
				shared_pt_wrdata = arc4_pt_wrdata;
				shared_pt_wren   = arc4_pt_wren;
                if (arc4_rdy)
                    next_state = MSG_LEN_REQ;
					 else
							next_state = ARC4;
            end
            MSG_LEN_REQ: begin
					pt_addr    = 8'd0;
					next_state = MSG_LEN_GET;
				end
            MSG_LEN_GET: next_state = MSG_REQ;
            MSG_REQ: begin
                pt_addr = i;
                next_state = MSG_GET;
            end
            MSG_GET: next_state = MSG_ASCII;
            MSG_ASCII: begin
                    if ((msg >= 8'h20) && (msg <= 8'h7E)) begin
                    if (i == msg_len)
                        next_state = CHECK_YES;
                    else begin
                        next_state = MSG_REQ;
                    end
                end
                else
                    next_state = LOOP;
            end
            LOOP: begin
                if (key < 24'hFFFFFF)
                    next_state = ARC4_RDY;
                else
                    next_state = CHECK_NO;
            end
            CHECK_YES: next_state = DONE;
            CHECK_NO: next_state = DONE;
            DONE: next_state = DONE;
            default: next_state = IDLE;
        endcase
    end

endmodule: crack2