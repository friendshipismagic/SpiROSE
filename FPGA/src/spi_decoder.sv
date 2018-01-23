/*
 * The SPI is used as an interface between the SOM and
 * the FPGA in order to (from the point of view of the FPGA):
 *   - Receive a new configuration for the drivers
 *   - Transmit rotation information given by the Hall effect
 *   sensors to the SBC
 */

module spi_decoder (
    input  nrst,
    input  clk,

    input  valid,
    input  [55:0] cmd_read,
    input  [2:0]  cmd_len_bytes,
    output [47:0] cmd_write,

    // Data generated by the Hall sensor module
    input [15:0] rotation_data,
    input [15:0] speed_data,
    output [47:0] configuration,

    output new_config_available,
    output rgb_enable
);

localparam CONFIG_COMMAND = 'hBF;
localparam ROTATION_COMMAND = 'h4C;
localparam SPEED_COMMAND = 'h4D;
localparam DISABLE_RGB_COMMAND = 'hD0;
localparam ENABLE_RGB_COMMAND = 'hE0;

`include "drivers_conf.svh"

logic [55:0] last_cmd_read;
logic [2:0] last_cmd_len_bytes;
logic last_valid;

always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        last_cmd_read <= '0;
        last_cmd_len_bytes <= '0;
        last_valid <= '0;
    end else begin
        last_valid <= valid;
        if(valid) begin
            last_cmd_read <= cmd_read;
            last_cmd_len_bytes <= cmd_len_bytes;
        end
    end

always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        configuration <= serialized_conf;
        new_config_available <= 1;       // This will be high for one cycle (STALL)
        rgb_enable <= 0;
    end else begin
        new_config_available <= '0;
        if (last_valid) begin
            if (last_cmd_len_bytes == 7 && last_cmd_read[55:48] == CONFIG_COMMAND) begin
                configuration <= last_cmd_read[47:0];
                new_config_available <= '1;
                cmd_write <= configuration;
            end else if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == CONFIG_COMMAND) begin
                cmd_write <= configuration;
            end else if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == ROTATION_COMMAND) begin
                cmd_write[47:32] <= rotation_data;
            end else if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == SPEED_COMMAND) begin
                cmd_write[47:32] <= speed_data;
            end else if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == ENABLE_RGB_COMMAND) begin
                rgb_enable <= '1;
            end else if (last_cmd_len_bytes == 1
                         && last_cmd_read[7:0] == DISABLE_RGB_COMMAND) begin
                rgb_enable <= '0;
            end
        end
    end

endmodule