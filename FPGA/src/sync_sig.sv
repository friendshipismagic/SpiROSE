module sync_sig #(
    parameter RESET_VALUE=0
)(
    input nrst,
    input clk,

    input in_sig,
    output out_sig
);

logic defer_sig;

always @(posedge clk or negedge nrst)
    if(~nrst) begin
        defer_sig = RESET_VALUE;
        out_sig <= RESET_VALUE;
    end else begin
        defer_sig <= in_sig;
        out_sig <= defer_sig;
    end

endmodule
