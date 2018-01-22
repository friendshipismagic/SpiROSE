module clock_enable (
    input clk,
    input nrst,
    output clk_enable
);

always_ff @(posedge clk or negedge nrst) 
    if (~nrst) begin
        clk_enable <= '0;
    end else begin
        clk_enable <= ~clk_enable;
    end

endmodule
