module sync_sig #(
    parameter RESET_VALUE=0
)(
    input nrst,
    input clk,

    input in_sig,
    output out_sig
);

logic reg0;
logic reg1;
logic reg2;

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

assign out_sig = (reg0 && reg1) || (reg1 && reg2) || (reg0 && reg2);

endmodule
