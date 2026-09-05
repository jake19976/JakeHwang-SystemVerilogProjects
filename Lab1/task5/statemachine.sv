module statemachine(input logic slow_clock, input logic resetb,
                    input logic [3:0] dscore, input logic [3:0] pscore, input logic [3:0] pcard3,
                    output logic load_pcard1, output logic load_pcard2, output logic load_pcard3,
                    output logic load_dcard1, output logic load_dcard2, output logic load_dcard3,
                    output logic player_win_light, output logic dealer_win_light);

//Define States
    logic [3:0] state, next_state;

    parameter IDLE = 4'b0000;
    parameter P1 = 4'b0001;
    parameter D1 = 4'b0010;
    parameter P2 = 4'b0011;
    parameter D2 = 4'b0100;
    parameter P3 = 4'b0110;
    parameter D3 = 4'b0111;
    parameter OVER = 4'b1000;

    //Register Logic
    always_ff @(posedge slow_clock) begin
        if (!resetb)
            state <= IDLE;
        else
            state <= next_state;
    end

    //State Transition Logic
    always_comb begin
        case (state)
            IDLE: next_state = P1;
            P1: next_state = D1;
            D1: next_state = P2;
            P2: next_state = D2;
            D2: begin
                if (pscore >= 8 || dscore >= 8) //Natural
                    next_state = OVER;
                else //Player scores 0 to 7
                    next_state = P3;
            end
            P3: next_state = D3;
            D3: next_state = OVER;
            OVER: next_state = OVER;
        endcase
    end

    //Machine Output Logic
    always_comb begin
        load_pcard1 = 0;
		load_pcard2 = 0;
		load_pcard3 = 0;
		load_dcard1 = 0;
		load_dcard2 = 0;
		load_dcard3 = 0;
        player_win_light = 0;
        dealer_win_light = 0;
        case(state)
            P1: load_pcard1 = 1;
            D1: load_dcard1 = 1;
            P2: load_pcard2 = 1;
            D2: load_dcard2 = 1;
            P3: begin //Player gets 3rd card condition
                if (pscore >= 0 && pscore <= 5)
                    load_pcard3 = 1;
                else
                    load_pcard3 = 0;
            end
            D3: begin
                if (load_pcard3) begin // Dealer gets 3rd card condition if player gets 3rd card
                    load_dcard3 = 0;
                    case (dscore)
                        7: load_dcard3 = 0;
                        6: begin
                            if (pcard3 == 6 || pcard3 == 7)
                                load_dcard3 = 1;
                        end
                        5: begin
                            if (pcard3 >= 4 && pcard3 <=7)
                                load_dcard3 = 1;
                        end
                        4: begin
                            if (pcard3 >= 2 && pcard3 <=7)
                                load_dcard3 = 1;
                        end
                        3: begin
                                if (pcard3 != 8)
                            load_dcard3 = 1;
                        end
                        default: load_dcard3 = 1;
                    endcase
                end
                else begin //Dealer gets 3rd card condition if player doesnt get 3rd card
                    if (dscore >=0 && dscore <= 5)
                        load_dcard3 = 1;
                end
            end
            OVER: begin //Score calculation
                if (pscore > dscore)
                    player_win_light = 1;
                else if (dscore > pscore)
                    dealer_win_light = 1;
                else if (pscore == dscore) begin
                    dealer_win_light = 1;
                    player_win_light = 1;
                end
            end
            default: begin
                load_pcard1 = 0;
				load_pcard2 = 0;
				load_pcard3 = 0;
				load_dcard1 = 0;
				load_dcard2 = 0;
				load_dcard3 = 0;
                player_win_light = 0;
                dealer_win_light = 0;
            end
        endcase
    end

endmodule