`default_nettype none
module heartbeat #(parameter COUNTER=0) (
    input clk,
    input nrst,
    output toggle
);

logic [$clog2(COUNTER)+1:0] counter;

logic state;
assign toggle = state;

always @(posedge clk or negedge nrst)
    if (~nrst) begin
        state <= '0;
        counter <= '0;
    end else begin
        if (counter == COUNTER-1) begin
            state <= ~state;
            counter <= '0;
        end else begin
            counter <= counter + 1'b1;
        end
    end


endmodule
