/*
* The SPI is used as an interface between the SOM and
* the FPGA in order to (from the point of view of the FPGA):
*   - Receive a new configuration for the drivers
*   - Reset the FPGA
*   - Transmit rotation information given by the Hall effect
*   sensors to the SBC
* 
* Many things thus need to be implemented:
*   - A SPI slave module
*   - An interpreter of the received bytes
*   - A protocol for the commands we want to send
*   needs to be defined and implemented. Thus a frame
*   needs to be defined with for example an instruction part
*   and a data part on a fixed number of bits.
*   The maximum data width is 48 bits, so we can be fine 
*   with 48+8 bits aka 7 bytes.
*/

module spi_slave(
    input  logic sck,
    input  logic nrst,
    
    input  logic ss,
    input  logic mosi,
    output logic miso,

    input logic [15:0] rotation_data,

    output logic [47:0] config_out,
    output logic new_config_available
);

localparam CONFIG_COMMAND = 191;
localparam ROTATION_COMMAND = 76;
localparam DEFAULT_CONFIG_DATA = 'hff;

// ReceiveRegister is a shift register for the received byte
// TransmitRegister is a shift register for the byte to be transmitted
logic [7:0] receive_register, transmit_register;

// shift_counter keeps trace of the number of times the receive_register is
// shifted
logic [3:0] shift_counter;

// Counter that counts the number of configuration bytes received
logic [2:0] config_byte_counter;

// Counter that counts the number of rotation bytes transmitted
logic [1:0] rotation_byte_counter;
logic transmission;

// 48-bit register that stores the received configuration
logic [47:0] configuration;
assign config_out = configuration;

assign miso = ~ss ? transmit_register[7] : '1;

/*
* Process for the receiving part:
* The master sends data through mosi while ss is low
*/
always_ff @(posedge sck or negedge nrst) begin
    if (~nrst) begin
        shift_counter <= 0;
        config_byte_counter <= 0;
        new_config_available <= 0;
    end else begin
        if (~ss) begin
            // Shift the receive register
            receive_register[7:1] <= receive_register[6:0];
            // Store the incoming mosi data in the receive register LSB
            receive_register[0] <= mosi;
            shift_counter <= shift_counter + 1;
        end else begin 
            shift_counter <= 0;
        end
        if (shift_counter == 7) begin
            shift_counter <= 0;
        end
        if (config_byte_counter == 0 && shift_counter == 0 
                && receive_register == CONFIG_COMMAND) begin
            config_byte_counter <= 1;
            configuration[7:0] <= receive_register;
        end
        if (config_byte_counter > 0 && shift_counter == 0) begin
            configuration[(config_byte_counter-1)*8 +: 8] <= receive_register;
            if (config_byte_counter == 6) begin
                // When the whole new configuration is received, reset the
                // configbytecounter
                config_byte_counter <= 0;
                // Signal that a new configuration is available
                new_config_available <= 1;
            end else begin
                // A complete byte has been received
                config_byte_counter <= config_byte_counter + 1;
            end
        end
    end
end

/*
* Process for the transmission part of the spi slave
* The Hall module sends rotation data to this module, then
* it needs to send it back through miso to the SBC.
*/

always_ff @(posedge sck or negedge nrst) begin
    if (~nrst) begin
        transmit_register <= DEFAULT_CONFIG_DATA;
    end else begin 
        if (~ss) begin
            if (shift_counter == 7) begin
                if ({receive_register[6:0], mosi} == ROTATION_COMMAND) begin
                    transmit_register <= rotation_data[7:0];
                    transmission <= 1;
                end else if (transmission) begin
                    transmit_register <= rotation_data[15:8];
                end else begin
                    transmit_register <= DEFAULT_CONFIG_DATA;
                end
            end else begin
                transmit_register <= {transmit_register[6:0],1'b1};
            end
        end
    end
end

endmodule
