/*
 * The SPI is used as an interface between the SOM and
 * the FPGA in order to (from the point of view of the FPGA):
 *   - Receive a new configuration for the drivers
 *   - Transmit rotation information given by the Hall effect
 *   sensors to the SBC
 */

module spi_slave(
    input  nrst,

    input  spi_clk,
    input  spi_ss,
    input  spi_mosi,
    output spi_miso,

    // Data generated by the Hall sensor module
    input [15:0] rotation_data,

    output [47:0] config_out,
    output new_config_available
);

localparam CONFIG_COMMAND = 191;
localparam ROTATION_COMMAND = 76;
localparam DEFAULT_CONFIG_DATA = 'hff;

/*
 * ReceiveRegister is a shift register for the received byte
 * TransmitRegister is a shift register for the byte to be transmitted
 */
logic [6:0] received_bits;
logic [7:0] transmit_register;

logic [7:0] current_register;
assign current_register = {received_bits, spi_mosi};

/*
 * shift_counter keeps trace of the number of times the received_bits is
 * shifted
 */
logic [2:0] shift_counter;

// Counter that counts the number of configuration bytes received
logic [2:0] config_byte_counter;

/*
 * State and counter for the transmission,
 */
enum logic [1:0] {NO_TRANSMISSION, FIRST_BYTE, SECOND_BYTE} transmission_step;

// 48-bit register that stores the received configuration
/* verilator lint_off UNUSED */
logic [47:0] configuration;
/* verilatro lint_off WIDTH */
assign config_out = configuration;

// Send bit of the transmission shift register when in transmission mode
assign spi_miso = transmission_step == NO_TRANSMISSION ? 1'b1 : transmit_register[7];

/*
 * Process for the receiving part:
 * The master sends data through spi_mosi while ss is low,
 * it is stored in the received_bits, which is then
 * shifted.
 */
always_ff @(posedge spi_clk or negedge nrst) begin
    if (~nrst) begin
        shift_counter <= '0;
    end else begin
        shift_counter <= '0;
        if (~spi_ss) begin
            // Shift the receive register
            received_bits[6:1] <= received_bits[5:0];
            received_bits[0] <= spi_mosi;
            shift_counter <= shift_counter + 1'b1;
        end
    end
end


logic should_run_configure;
assign should_run_configure =
    config_byte_counter == 0
 && shift_counter == 7
 && current_register == CONFIG_COMMAND;

logic next_config_byte_is_ready;
assign next_config_byte_is_ready =
    config_byte_counter > 0
 && shift_counter == 7;

logic [5:0] current_configuration_addr;
assign current_configuration_addr = 48 - config_byte_counter*8;

/*
 * Process for the receiver logic.
 * It outputs the received bytes in the right order
 * in the output configuration.
 */
always_ff @(posedge spi_clk or negedge nrst) begin
    if (~nrst) begin
        config_byte_counter <= 0;
        new_config_available <= 0;
    end else begin

        /*
         * If we are ready to process a configure command
         * initialize the appropriate counter
        */
        if (should_run_configure) begin
            config_byte_counter <= 1;
        end

        /*
         * Otherwise, we are ready to process values as soon as they are ready
        */
        if (next_config_byte_is_ready) begin
            config_byte_counter <= config_byte_counter + 1;
            configuration[current_configuration_addr +: 8] <= current_register;

            /*
             * Signal that a new configuration is available and start waiting
             * for a new configuration
             */
            if (config_byte_counter == 6) begin
                config_byte_counter <= 0;
                new_config_available <= 1;
            end
        end else begin
            new_config_available <= 0;
        end
    end
end

/*
 * Process for the transmission part of the spi slave
 * The Hall module sends rotation data to this module, then
 * it needs to send it back through spi_miso to the SBC.
 */

logic should_run_rotation;
assign should_run_rotation =
    current_register == ROTATION_COMMAND
 && transmission_step == NO_TRANSMISSION;

always_ff @(posedge spi_clk or negedge nrst) begin
    if (~nrst) begin
        transmit_register <= DEFAULT_CONFIG_DATA;
        transmission_step <= NO_TRANSMISSION;
    end else begin
        if (~spi_ss) begin
            if (shift_counter == 7) begin
                if (current_register == ROTATION_COMMAND) begin
                    transmit_register <= rotation_data[7:0];
                    transmission_step <= FIRST_BYTE;
                end else if (transmission_step == 1) begin
                    transmit_register <= rotation_data[15:8];
                    transmission_step <= SECOND_BYTE;
                end else if (transmission_step == 2) begin
                    transmission_step <= NO_TRANSMISSION;
                end
            end else begin
                transmit_register <= {transmit_register[6:0],1'b1};
            end
        end else begin
            transmit_register[7] <= 1;
        end
    end
end

endmodule
