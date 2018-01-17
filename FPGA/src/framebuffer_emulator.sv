module framebuffer_emulator #(
    parameter POKER_MODE=9,
    parameter BLANKING_CYCLES=72
)(
    input clk_33,
    input nrst,

    // Data signal for the driver main controller
    output [29:0] data,

    // Sync signals
    input driver_ready,
    input new_configuration_ready
);

logic [3:0] led_cnt;
logic [3:0] bit_cnt;
logic [2:0] color_cnt;

always_ff @(posedge clk_33 or negedge nrst)
    if(~nrst) begin
        led_cnt <= '0;
        bit_cnt <= '0;
        color_cnt <= '0;
    end else begin
        if(new_configuration_ready) begin
            led_cnt <= '0;
            bit_cnt <= '0;
            color_cnt <= '0;
        end else if(driver_ready) begin
            color_cnt <= color_cnt + 1'b1;
            if(color_cnt == 2) begin
                color_cnt <= 0;
                led_cnt <= led_cnt + 1'b1;
                if(led_cnt == 15) begin
                    led_cnt <= 0;
                    bit_cnt <= bit_cnt + 1'b1;
                    if(bit_cnt == 9) begin
                        bit_cnt <= '0;
                    end
                end
            end
        end
    end

always_ff @(posedge clk_33 or negedge nrst)
    if(~nrst) begin
        data <= '0;
    end else begin
        data <= color_cnt == (led_cnt % 3) && driver_ready;
		  //data <= '1;
    end


endmodule
