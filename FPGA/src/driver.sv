module driver #(parameter MULTIPLEXING = 8, parameter CHANNELS = 48, parameter DATA_WIDTH = 9)
(
    input wire clk,
    input wire reset,
    output logic[DATA_WIDTH-1:0] data,
    output logic lat
);

endmodule
