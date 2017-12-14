module clock_lse_inverse #(
    parameter INVERSE_PHASE=0
)(
    input clk_hse,
    input nrst,
    output logic clk_lse
);

always_ff @(negedge clk_hse or negedge nrst)
    if(~nrst) begin
        clk_lse <= INVERSE_PHASE;
    end else begin
        clk_lse <= ~clk_lse;
    end

endmodule
