module sync_sig #(
    parameter RESET_VALUE=0
)(
    input nrst,
    input clk,

    input in_sig,
    output out_sig
);

logic reg1;
logic reg2;

always @(posedge clk or negedge nrst)
    if(~nrst) begin
        reg1 = RESET_VALUE;
        reg2 <= RESET_VALUE;
    end else begin
        reg1 <= in_sig;
		  reg2 <= reg1;
    end
	 
assign out_sig = (in_sig && reg1) || (reg1 && reg2) || (in_sig && reg2);

endmodule
