//
// Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément Decoodt,
// Alexandre Janniaux, Adrien Marcenat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

`default_nettype none
module spi_iff #(
    parameter MISO_SIZE=432
)(
    input  nrst,
    input  clk,

    input  spi_clk,
    input  spi_ss,
    input  spi_mosi,
    output spi_miso,

    output [439:0] data_mosi,
    output [10:0] data_len_bytes,
    input  [MISO_SIZE-1:0] data_miso,

    output valid
);

logic [439:0] in_reg;
logic [MISO_SIZE-1:0] out_reg;
logic [20:0] cmd_len_bits;

logic sync_mosi, sync_sck, sync_ss;
logic last_sck, last_ss;
logic posedge_sck, negedge_sck, posedge_ss, negedge_ss;

assign posedge_sck = ~last_sck & sync_sck;
assign negedge_sck = last_sck & ~sync_sck;
assign posedge_ss = ~last_ss & sync_ss;
assign negedge_ss = last_ss & ~sync_ss;

assign spi_miso = sync_ss ? 'z : out_reg[MISO_SIZE-1];
assign data_len_bytes = cmd_len_bits[13:3];

/*
* Synchronize input signal from SPI
*/
sync_sig sync_sig_mosi (
    .clk(clk),
    .nrst(nrst),
    .in_sig(spi_mosi),
    .out_sig(sync_mosi)
);

sync_sig sync_sig_clk (
    .clk(clk),
    .nrst(nrst),
    .in_sig(spi_clk),
    .out_sig(sync_sck)
);

sync_sig sync_sig_ss (
    .clk(clk),
    .nrst(nrst),
    .in_sig(spi_ss),
    .out_sig(sync_ss)
);

/*
*  Synchronize last sck state to detect posedge
*/
always @(posedge clk or negedge nrst)
    if(~nrst) begin
        last_sck <= '0;
    end else begin
        last_sck <= sync_sck;
    end

/*
*  Synchronize last ss state to detect edges
*/
always @(posedge clk or negedge nrst)
    if(~nrst) begin
        last_ss <= '1;
    end else begin
        last_ss <= sync_ss;
    end

/*
*  Read mosi each time a clock is detected
*/
always @(posedge clk or negedge nrst)
    if(~nrst) begin
        in_reg <= '0;
        cmd_len_bits <= '0;
    end else begin
        if(posedge_sck) begin
            in_reg <= { in_reg[438:0], sync_mosi };
            cmd_len_bits <= cmd_len_bits + 1;
        end
        if(negedge_ss) begin
            in_reg <= '0;
            cmd_len_bits <= '0;
        end
    end

/*
*  Shift register to master each time a clock is detected
*/
always @(posedge clk or negedge nrst)
    if(~nrst) begin
        out_reg <= '0;
    end else begin
        if(negedge_ss) begin
            out_reg <= data_miso;
        end else if (posedge_ss) begin
            out_reg <= '0;
        end else if (~sync_ss && negedge_sck) begin
            out_reg <= { out_reg[MISO_SIZE-2:0], 1'b0 };
        end
    end

/*
*  Save our data when ss is lost
*/
always @(posedge clk or negedge nrst)
    if(~nrst) begin
        data_mosi <= '0;
        valid <= '0;
    end else begin
        valid <= '0;
        if (posedge_ss) begin
            data_mosi <= in_reg;
            valid <= cmd_len_bits[2:0] == '0;
        end
    end

endmodule
