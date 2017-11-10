module driver_controller #(parameter MULTIPLEXING = 8,
                           parameter POKER_MODE = 9,
                           parameter DATA_WIDTH = 48)
(
    input wire clk,
    input wire nrst,
    input logic bit_in,
    output logic sin,
    output logic lat,
    output logic gclk,
    output logic sclk
);

// The driver's clock gclk must be used by segment of width 2^N
localparam gclk_segment = $clog2(DATA_WIDTH*POKER_MODE);
localparam subperiod_total_length = 2**gclk_segment;
localparam multiplex_width = $clog2(MULTIPLEXING);

logic[gclk_segment-1:0] bit_count;
logic[$clog2(DATA_WIDTH)-1:0] bit_group_count;
logic[multiplex_width-1:0] multiplex_count;
logic internal_blanking;

// gclk must be input continuously
assign gclk = clk;

/*
 * After sending all the bit of one line of LED we need to wait for the end
 * of the gclk segment.
 */
assign internal_blanking = bit_count >= DATA_WIDTH*POKER_MODE;

/*
 * We must disable sclk in the blanking otherwise it will shift the common
 * shift register and we will lose data.
 */
assign sclk = clk & ~internal_blanking;

always_ff@(posedge clk or negedge nrst)
    if(!nrst)
    begin
        sin <= '0;
        bit_count <= '0;
        bit_group_count <= '0;
        multiplex_count <= '0;
    end
    else
    begin
        // Write bit_in in the common shift register if not in blanking area
        if(~internal_blanking)
        begin
            sin <= bit_in;
            bit_group_count <= bit_group_count+1'b1;
            // We have written DATA_WIDTH bits in the common shift register
            if(bit_group_count == DATA_WIDTH-1)
                bit_group_count <= '0;
        end
        bit_count <= bit_count+1'b1;
        // We have sent all the bits to each LED
        if(bit_count == subperiod_total_length-1)
        begin
            bit_count <= '0;
            multiplex_count <= multiplex_count+1'b1;
        end
    end

always_ff@(posedge clk or negedge nrst)
    if(!nrst)
        lat <= '0;
    else
    begin
        lat <= '0;
        /*
         * - One cycle with LAT high write the common shift register into the
         *   first GS data latch (WRTGS command)
         * - Three cycles high also write the first GS data latch into the
         *   second one (LATGS command),
         * - Seven cycles high also reset the line counter (LINERESET command)
         */
        if((bit_group_count >= DATA_WIDTH-2)
            || (bit_count >= subperiod_total_length-4)
            || (multiplex_count == (multiplex_width)'(MULTIPLEXING-1) && bit_count >= subperiod_total_length-8))
            lat <= 1'b1;
    end

endmodule
