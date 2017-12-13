module clock_lse #(
    parameter INVERSE_PHASE=0
)(
    input clk_hse,
    input nrst,
    output logic clk_lse
);

always_ff @(posedge clk_hse or negedge nrst)
    if(~nrst) begin
        clk_lse <= INVERSE_PHASE;
    end else begin
        clk_lse <= ~clk_lse;
    end

endmodule
