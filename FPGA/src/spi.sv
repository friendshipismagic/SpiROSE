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

module spiSlave(
    input  logic sck,
    input  logic nrst,
    
    input  logic ss,
    input  logic mosi,
    output logic miso,

    input logic newRotationDataAvailable,

    output logic [47:0] configOut,
    output logic newConfigAvailable
);

localparam CONFIG_COMMAND = 191;
localparam ROTATION_COMMAND = 76;
localparam DEFAULT_CONFIG_DATA = 'hff;

// ReceiveRegister is a shift register for the received byte
// TransmitRegister is a shift register for the byte to be transmitted
logic [7:0] receiveRegister, transmitRegister;

// shiftCounter keeps trace of the number of times the receiveRegister is
// shifted
logic [3:0] shiftCounter;

// Counter that counts the number of configuration bytes received
logic [2:0] configByteCounter;

// 48-bit register that stores the received configuration
logic [47:0] configuration;
assign configOut = configuration;

// The MSB of the transmit register is sent when ss is low
assign miso = ~ss ? transmitRegister[7] : '1;



/*
* Process for the receiving part:
* The master sends data through mosi while ss is low
*/
always_ff @(posedge sck or negedge nrst) begin
    if (~nrst) begin
        shiftCounter <= 0;
        configByteCounter <= 0;
        newConfigAvailable <= 0;
    end
    else if (~ss) begin
        // Shift the receive register
        receiveRegister[7:1] <= receiveRegister[6:0];
        // Store the incoming mosi data in the receive register LSB
        receiveRegister[0] <= mosi;
        shiftCounter <= shiftCounter + 1;
    end
    else if (ss) begin
        shiftCounter <= 0;
    end
    if (shiftCounter == 8) begin
        shiftCounter <= 0;
        if (configByteCounter > 0) begin
            configuration[(configByteCounter-1)*8 +: 8] <= receiveRegister;
            if (configByteCounter == 6) begin
                // When the whole new configuration is received, reset the
                // configbytecounter
                configByteCounter <= 0;
                // Signal that a new configuration is available
                newConfigAvailable <= 1;
            end
            else begin
                // A complete byte has been received
                configByteCounter <= configByteCounter + 1;
            end
        end
        else if (configByteCounter == 0 
                && receiveRegister == CONFIG_COMMAND) begin
            configByteCounter <= 1;
            end
    end
end

/*
* Process for the transmission part of the spi slave
* Whenever a Hall effect sensor is triggered, it needs to send through miso
* a special command to the SBC
*/

always_ff @(posedge sck or negedge nrst) begin
    if (~nrst) begin
        transmitRegister <= DEFAULT_CONFIG_DATA;
    end
    else if (~ss) begin
        if (shiftCounter == 0) begin
            if (newRotationDataAvailable) begin
                transmitRegister <= ROTATION_COMMAND;
            end
            else begin
                transmitRegister <= DEFAULT_CONFIG_DATA;
            end
        end
        else begin
            transmitRegister <= {transmitRegister[6:0],1'b1};
        end
    end
end

endmodule
