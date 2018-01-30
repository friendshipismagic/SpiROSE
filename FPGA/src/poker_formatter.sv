`default_nettype none
module poker_formatter (
    input [383:0]  data_in,
    output [431:0] data_out
);

always_comb begin
   data_out = '0;
   for(int bit_idx=1; bit_idx<9; bit_idx++) begin
      for(int led=0; led<16; led++) begin
         data_out[48*bit_idx + 3*led + 0] = data_in[24*led + (bit_idx - 1) + 0];
         data_out[48*bit_idx + 3*led + 1] = data_in[24*led + (bit_idx - 1) + 8];
         data_out[48*bit_idx + 3*led + 2] = data_in[24*led + (bit_idx - 1) + 16];
      end
   end
end

endmodule
