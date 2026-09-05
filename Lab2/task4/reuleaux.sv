module reuleaux(input logic clk, input logic rst_n, input logic [2:0] colour,
                input logic [7:0] centre_x, input logic [6:0] centre_y, input logic [7:0] diameter,
                input logic start, output logic done,
                output logic [7:0] vga_x, output logic [6:0] vga_y,
                output logic [2:0] vga_colour, output logic vga_plot);

    parameter CONST = 11'd1732;
    logic [7:0] centre_x1, centre_x2, centre_x3;
    logic [6:0] centre_y1, centre_y2, centre_y3;
    logic [7:0] vga_x1, vga_x2, vga_x3;
    logic [6:0] vga_y1, vga_y2, vga_y3;
    logic [2:0] vga_colour1, vga_colour2, vga_colour3;
    logic done1, done2, start2, start3;
    logic vga_plot1, vga_plot2, vga_plot3;

    assign centre_x1 = centre_x + diameter / 2;
    assign centre_x2 = centre_x - diameter / 2;
    assign centre_x3 = centre_x;

    assign centre_y1 = centre_y + diameter * CONST / 6000;
    assign centre_y2 = centre_y + diameter * CONST / 6000;
    assign centre_y3 = centre_y - diameter * CONST / 3000;

    enum logic [3:0] {IDLE, C1, C2, C3, DONE} state, next_state;

    always_ff @(posedge clk) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin //State Transition Logic
        start2 = 0;
        start3 = 0;
        case (state)
            IDLE: begin
                if (start)
                    next_state = C1;
                else
                    next_state = IDLE;
            end
            C1: begin
                if (done1)
                    next_state = C2;
                else
                    next_state = C1;
            end
            C2: begin
                start2 = 1;
                if (done2)
                    next_state = C3;
                else
                    next_state = C2;
            end
            C3: begin
                start3 = 1;
                if (done)
                    next_state = DONE;
                else
                    next_state = C3;
            end
            DONE: begin
                start2 = 0;
                start3 = 0;
                next_state = DONE;
            end
            default: next_state = IDLE;
        endcase
    end

    always_comb begin //State Output Logic
        vga_x = 0;
        vga_y = 0;
        vga_colour = 0;
        vga_plot = 0;
        case (state)
            C1: begin
                vga_x = vga_x1;
                vga_y = vga_y1;
                vga_colour = vga_colour1;
                if (vga_x1 >= centre_x2 && vga_x1 <= centre_x3 && vga_y1 >= centre_y3 && vga_y1 <= centre_y1)
                    vga_plot = vga_plot1;
            end
            C2: begin
                vga_x = vga_x2;
                vga_y = vga_y2;
                vga_colour = vga_colour2;
                if (vga_x2 >= centre_x3 && vga_x2 <= centre_x1 && vga_y2 >= centre_y3 && vga_y2 <= centre_y1)
                    vga_plot = vga_plot2;
            end
            C3: begin
                    vga_x = vga_x3;
                    vga_y = vga_y3;
                    vga_colour = vga_colour3;
                if (vga_x3 >= centre_x2 && vga_x3 <= centre_x1 && vga_y3 >= centre_y1)
                    vga_plot = vga_plot3;
            end
            default: begin
                vga_x = 0;
                vga_y = 0;
                vga_colour = 0;
                vga_plot = 0;
            end
        endcase
    end

    circle cr1(.clk(clk), .rst_n(rst_n), .colour(colour), .centre_x(centre_x1), .centre_y(centre_y1),
                .radius(diameter), .start(start), .done(done1), .vga_x(vga_x1), .vga_y(vga_y1), .vga_colour(vga_colour1), .vga_plot(vga_plot1)); //Right Bottom Circle
    circle cr2(.clk(clk), .rst_n(rst_n), .colour(colour), .centre_x(centre_x2), .centre_y(centre_y2),
                .radius(diameter), .start(start2), .done(done2), .vga_x(vga_x2), .vga_y(vga_y2), .vga_colour(vga_colour2), .vga_plot(vga_plot2)); //Left Bottom Circle
    circle cr3(.clk(clk), .rst_n(rst_n), .colour(colour), .centre_x(centre_x3), .centre_y(centre_y3),
                .radius(diameter), .start(start3), .done(done), .vga_x(vga_x3), .vga_y(vga_y3), .vga_colour(vga_colour3), .vga_plot(vga_plot3)); //Top Circle

endmodule
