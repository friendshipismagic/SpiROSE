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

/*
 * The SPI is used as an interface between the SOM and
 * the FPGA in order to (from the point of view of the FPGA):
 *   - Receive a new configuration for the drivers
 *   - Transmit rotation information given by the Hall effect
 *   sensors to the SBC
 */

`default_nettype none
module spi_decoder #(
    MISO_SIZE=440
) (
    input          nrst,
    input          clk,

    input          valid,
    input [439:0]  data_mosi,
    input [10:0]   data_len_bytes,
    output [MISO_SIZE-1:0] data_miso,

    // Data generated by the Hall sensor module
    input [15:0]   rotation_data,
    input [31:0]   speed_data,
    input [31:0]   debug_data,
    output [47:0]  configuration,

    output         new_config_available,
    output         rgb_enable,

    // Mux manual control
    output [7:0]   mux,
    output         manage_mux,
    output         manage,

    // TLC controller manual control
    output [47:0]  driver_data [29:0],
    output [431:0] debug_driver,
    output         debug_driver_poker_mode,

    // RAM control
    output [23:0]  pixel,
    // Signal the beginning of a pixel line send
    output logic   SOL,
    output [31:0]  ram_raddr,
    output [7:0]   ram_driver,
    output [7:0]   ram_offset,
    input  [23:0]  ram_rdata,

    // Framebuffer control
    input [383:0]  framebuffer_data,
    input integer  framebuffer_column,

    // Reset from the SPI
    output         spi_nrst
);

localparam CONFIG_COMMAND = 'hBF;
localparam ROTATION_COMMAND = 'h4C;
localparam SPEED_COMMAND = 'h4D;
localparam DISABLE_RGB_COMMAND = 'hD0;
localparam ENABLE_RGB_COMMAND = 'hE0;
localparam DEBUG_COMMAND = 'hDE;
localparam ENABLE_MUX_COMMAND = 'hE1;
localparam DISABLE_MUX_COMMAND = 'hD1;
localparam DRIVER_DATA_COMMAND = 'hDD;
localparam DRIVER_COMMAND_RGB = 'hEE;   // Still uses the LUTs
localparam DRIVER_COMMAND_POKER = 'hEF; // Overrides output LUTs
localparam MANAGE_COMMAND = 'hFA;
localparam RELEASE_COMMAND = 'hFE;
localparam GET_PIXEL_COMMAND = 'h20;
localparam SEND_PIXEL_LINE_COMMAND = 'h21;
localparam NRST_COMMAND = 'hA0;
localparam SELECT_FRAMEBUFFER_COLUMN_COMMAND = 'h24;
localparam READ_FRAMEBUFFER_COLUMN_COMMAND = 'h25;

`include "drivers_conf.svh"

logic [439:0] last_cmd_read;
logic [10:0] last_cmd_len_bytes;
logic last_valid;

// Driver selection and state machine for reading
logic ram_is_reading;

logic [383:0] profiled_framebuffer_data;
integer       profiled_framebuffer_column;
always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        profiled_framebuffer_data   <= 0;
    end else begin
        if (framebuffer_column == profiled_framebuffer_column) begin
            profiled_framebuffer_data <= framebuffer_data;
        end
    end

always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        last_cmd_read <= '0;
        last_cmd_len_bytes <= '0;
        last_valid <= '0;
    end else begin
        last_valid <= valid;
        if(valid) begin
            last_cmd_read <= data_mosi;
            last_cmd_len_bytes <= data_len_bytes;
        end
    end

always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        configuration <= serialized_conf;
        new_config_available <= 1;       // This will be high for one cycle (STALL)
        rgb_enable <= 0;
        mux <= '0;
        debug_driver <= '0;
        debug_driver_poker_mode <= '0;
        manage_mux <= '0;
        spi_nrst <= '1;
        ram_raddr <= '0;
        SOL <= '0;
        ram_driver <= '0;
        profiled_framebuffer_column <= 0;
        for (int i=0; i<30; ++i) begin
            driver_data[i] <= '0;
        end
    end else begin
        new_config_available <= '0;
        if (ram_is_reading)
            data_miso[MISO_SIZE-1 -: 24] <= ram_rdata;
        ram_is_reading <= '0;
        manage <= '0;
        SOL <= '0;
        if (last_valid) begin
            if (last_cmd_len_bytes == 7 && last_cmd_read[55:48] == CONFIG_COMMAND) begin
                configuration <= last_cmd_read[47:0];
                new_config_available <= '1;
                data_miso[MISO_SIZE-1 -: 48] <= configuration;
            end

            if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == MANAGE_COMMAND) begin
                manage_mux <= 1;
            end

            if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == RELEASE_COMMAND) begin
                manage_mux <= 0;
            end

            if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == NRST_COMMAND) begin
                spi_nrst <= 0;
            end

            if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == CONFIG_COMMAND) begin
                data_miso[MISO_SIZE-1 -: 48] <= configuration;
            end

            if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == ROTATION_COMMAND) begin
                data_miso[MISO_SIZE-1 -: 16] <= rotation_data;
            end

            if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == SPEED_COMMAND) begin
                data_miso[MISO_SIZE-1 -: 32] <= speed_data;
            end

            if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == DEBUG_COMMAND) begin
                data_miso[MISO_SIZE-1 -: 32] <= debug_data;
            end

            if (last_cmd_len_bytes == 49
                         && last_cmd_read[391:384] == DRIVER_COMMAND_RGB) begin
                debug_driver <= {48'b0, last_cmd_read[383:0]};
                debug_driver_poker_mode <= 0;
            end

            if (last_cmd_len_bytes == 55
                         && last_cmd_read[439:432] == DRIVER_COMMAND_POKER) begin
                debug_driver <= last_cmd_read[431:0];
                debug_driver_poker_mode <= 1;
            end

            if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == ENABLE_RGB_COMMAND) begin
                rgb_enable <= '1;
            end

            if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == DISABLE_RGB_COMMAND) begin
                rgb_enable <= '0;
            end

            if (last_cmd_len_bytes == 2
                         && last_cmd_read[15:8] == ENABLE_MUX_COMMAND) begin
                mux[last_cmd_read[2:0]] <= 1;
            end

            if (last_cmd_len_bytes == 2
                         && last_cmd_read[15:8] == DISABLE_MUX_COMMAND) begin
                mux[last_cmd_read[2:0]] <= 0;
            end

            if (last_cmd_len_bytes == 8
                         && last_cmd_read[63:56] == DRIVER_DATA_COMMAND) begin
                if (last_cmd_read[55:48] < 8'd30)
                    driver_data[last_cmd_read[52:48]] <= last_cmd_read[47:0];
            end

            if (last_cmd_len_bytes == 6
                         && last_cmd_read[47:40] == SEND_PIXEL_LINE_COMMAND) begin
                SOL <= 1;
                ram_driver <= last_cmd_read[39:32];
                ram_offset <= last_cmd_read[31:24];
                pixel      <= last_cmd_read[23:0];
                manage <= 1;
            end

            if (last_cmd_len_bytes == 3
                         && last_cmd_read[23:16] == GET_PIXEL_COMMAND) begin
                ram_raddr <= {24'b0, last_cmd_read[7:0]};
                ram_driver <= last_cmd_read[15:8];
                ram_offset <= last_cmd_read[7:0];
                ram_is_reading <= '1;
            end

            if (last_cmd_len_bytes == 2 && last_cmd_read[15:8] == SELECT_FRAMEBUFFER_COLUMN_COMMAND) begin
                profiled_framebuffer_column <= 32'(last_cmd_read[7:0]);
            end

            if (last_cmd_read[7:0] == 1 && last_cmd_len_bytes == READ_FRAMEBUFFER_COLUMN_COMMAND) begin
                data_miso[MISO_SIZE-1 -: 384] <= profiled_framebuffer_data;
            end
        end
    end

endmodule
