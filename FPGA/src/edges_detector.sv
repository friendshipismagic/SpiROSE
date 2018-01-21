module edges_detector #(
    parameter RESET_VALUE = 0
)(
    input clk,
    input nrst,
    input din,
    output posedge_out,
    output negedge_out
);

logic last_din;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        last_din <= RESET_VALUE;
    end else begin
        last_din <= din;
    end

assign posedge_out =  din & (din ^ last_din);
assign negedge_out = ~din & (din ^ last_din);

endmodule
