`default_nettype none
module hall_counter(
  input clk,
  input nrst,
  input hall,
  output logic detected,
  output logic [31:0] speed_data);

logic [31:0] counter;
logic prev_hall;

assign detected = prev_hall && ~hall;

always_ff @(posedge clk or negedge nrst) begin
  if (~nrst) begin
    counter <= '0;
    speed_data <= '0;
    prev_hall <= '1;
  end else begin 
    if (detected) begin
      speed_data <= counter;
      counter <= '1;
    end else begin
      counter <= counter + 1;
    end
    prev_hall <= hall;
  end
end

endmodule
