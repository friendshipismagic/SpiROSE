module poker_formatter (
    input [383:0]  data_in,
    output [431:0] data_out
);

always_comb begin
    for(int led=0; led<16; led++) begin
        for(int poker=8; poker>0; --poker) begin
            data_out[poker*48 - 3*(16-led)+:3] = {
                data_in[led*24 + poker - 1],
                data_in[led*24 + 8 + poker - 1],
                data_in[led*24 + 16 + poker - 1]
            };
        end
    end
    data_out[47:0] = '0;
end


endmodule
