module scorehand(input logic [3:0] card1,
                input logic [3:0] card2,
                input logic [3:0] card3,
                output logic [3:0] total);

    logic [3:0] val1, val2, val3;

    always_comb begin
        val1 = card1;
        val2 = card2;
        val3 = card3;

        if (card1 >= 10)
            val1 = 0;
        if (card2 >= 10)
            val2 = 0;
        if (card3 >= 10)
            val3 = 0;
    end

    assign total = (val1 + val2 + val3) % 10;

endmodule
