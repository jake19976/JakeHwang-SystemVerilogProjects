module baccarat_async_fifo #(
    parameter DATA_WIDTH = 12, 
    parameter ADDR_WIDTH = 3   
)(
    
    input  logic                    wclk,      
    input  logic                    wrst_n,    
    input  logic                    w_en,      
    input  logic [DATA_WIDTH-1:0]   wdata,     
    
    // Read Domain (Driven by the system / CLOCK_50)
    input  logic                    rclk,    
    input  logic                    rrst_n,   
    input  logic                    r_en,     
    output logic [DATA_WIDTH-1:0]   rdata,    
    
    output logic                    wfull,     
    output logic                    rempty   
);

    localparam DEPTH = 1 << ADDR_WIDTH;
    logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];

   
    logic [ADDR_WIDTH:0] wptr_bin, wptr_gray;
    logic [ADDR_WIDTH:0] rptr_bin, rptr_gray;
    
    logic [ADDR_WIDTH:0] wptr_gray_sync1, wptr_gray_sync2;
    logic [ADDR_WIDTH:0] rptr_gray_sync1, rptr_gray_sync2;


    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin  <= '0;
            wptr_gray <= '0;
        end else if (w_en && !wfull) begin
            wptr_bin  <= wptr_bin + 1'b1;
            wptr_gray <= (wptr_bin + 1'b1) ^ ((wptr_bin + 1'b1) >> 1);
        end
    end


    always_ff @(posedge wclk) begin
        if (w_en && !wfull) begin
            mem[wptr_bin[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync1 <= '0;
            rptr_gray_sync2 <= '0;
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    // FIFO Full condition using Gray code
    assign wfull = (wptr_gray == {~rptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rptr_gray_sync2[ADDR_WIDTH-2:0]});

  
    // READ DOMAIN (fast_clock / CLOCK_50)
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin  <= '0;
            rptr_gray <= '0;
        end else if (r_en && !rempty) begin
            rptr_bin  <= rptr_bin + 1'b1;
            rptr_gray <= (rptr_bin + 1'b1) ^ ((rptr_bin + 1'b1) >> 1);
        end
    end


    assign rdata = mem[rptr_bin[ADDR_WIDTH-1:0]];

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync1 <= '0;
            wptr_gray_sync2 <= '0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    assign rempty = (rptr_gray == wptr_gray_sync2);

endmodule
