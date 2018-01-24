module sync_sig #(
    parameter RESET_VALUE=0,
    parameter SIZE=1
)(
    input nrst,
    input clk,

    input logic  [SIZE - 1:0] in_sig,
    output logic [SIZE - 1:0] out_sig
);

logic [SIZE - 1:0] reg0;
logic [SIZE - 1:0] reg1;
logic [SIZE - 1:0] reg2;

always @(posedge clk or negedge nrst)
    if(~nrst) begin
        reg0 <= RESET_VALUE;
        reg1 <= RESET_VALUE;
        reg2 <= RESET_VALUE;
    end else begin
        reg0 <= in_sig;
        reg1 <= reg0;
        reg2 <= reg1;
    end

assign out_sig = (reg0 & reg1) | (reg1 & reg2) | (reg0 & reg2);

endmodule
