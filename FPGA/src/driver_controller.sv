module driver_controller #(parameter MULTIPLEXING = 8,
                           parameter POKER_MODE = 9,
                           parameter DATA_WIDTH = 48)
(
    input wire clk,
    input wire nrst,
    input logic bit_in,
    output logic bit_out,
    output logic lat
);

logic[$clog2(DATA_WIDTH)-1:0] bit_count;
logic[$clog2(POKER_MODE)-1:0] bit_group_count;
logic[$clog2(MULTIPLEXING)-1:0] multiplex_count;

always_ff@(posedge clk or negedge nrst)
    if(!nrst)
    begin
        bit_out <= '0;
        bit_count <= '0;
        bit_group_count <= '0;
        multiplex_count <= '0;
    end
    else
    begin
        // Write bit_in in the common shift register
        bit_out <= bit_in;
        bit_count <= bit_count+1'b1;
        // We have written 48 bits in the common shift register
        if(bit_count == DATA_WIDTH-1)
        begin
            bit_count <= '0;
            bit_group_count <= bit_group_count+1'b1;
            // We have sent all the bits to each LED
            if(bit_group_count == POKER_MODE-1)
            begin
                bit_group_count <= '0;
                multiplex_count <= multiplex_count+1'b1;
            end
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
        /* verilator lint_off WIDTH */
        if((bit_count >= DATA_WIDTH-2)
            || (bit_group_count == POKER_MODE-1 && bit_count >= DATA_WIDTH-4)
            || (multiplex_count == MULTIPLEXING-1 && bit_count >= DATA_WIDTH-8))
            lat <= 1'b1;
        /* verilator lint_on WIDTH */
    end

endmodule
