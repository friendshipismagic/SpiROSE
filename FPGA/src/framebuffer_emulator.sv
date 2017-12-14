module framebuffer_emulator #(
    parameter POKER_MODE=9,
    parameter BLANKING_CYCLES=72
)(
    input clk_33,
    input nrst,
    input color_button,
    input switch_demo_button,

    // Data and sync signal for the driver main controller
    output reg [29:0] data,
    output reg        sync
);

logic [10:0] segment_counter;
logic [2:0] mul_counter;
logic blanking;
assign sync = segment_counter >= 512 && mul_counter == 0;
assign blanking = segment_counter < BLANKING_CYCLES;

always_ff @(posedge clk_33 or negedge nrst)
    if(~nrst) begin
        segment_counter <= '0;
        mul_counter <= '0;
    end else begin
        segment_counter <= segment_counter + 1'b1;
        if(segment_counter == 512) begin
            mul_counter <= mul_counter + 1'b1;
            segment_counter <= '0;
        end
    end

logic[31:0] blink_counter;
// Indicates the curretn display color (RGB)
logic[1:0]  color_counter;
// Indicates if the current bit we are sending is red, green or blue
logic[1:0]  color_bit_counter;
/*
 * Because of timing requirement we have 72 blanking cycles, then one blanking
 * cycle every 48 cycles. Thus we have to skip a cycle every 48 cycles when
 * sending data, which is done thanks to the following counter.
 */
logic [5:0] counter_48;
// Indicates to which led we are sending data, modulo 3
logic [1:0] counter_3;
logic switch_demo;
always_ff @(posedge clk_33 or negedge nrst)
	if(~nrst) begin
        color_counter     <= '0;
        color_bit_counter <= '0;
        blink_counter     <= '0;
        counter_48        <= '0;
        switch_demo       <= '0;
        counter_3         <= '0;
	end else begin
        if(~blanking) begin
            // When sending a bit group we send B,G,R,B,G,R...
            color_bit_counter <= color_bit_counter + 1'b1;
            if(color_bit_counter == 2) begin
                color_bit_counter <= '0;
                counter_3 <= counter_3 + 1'b1;
                if(counter_3 == 2) begin
                    counter_3 <= '0;
                end
            end
            if(counter_48 == 0) begin
                // We will send another bit group, we start from blue again
                color_bit_counter <= '0;
                counter_3 <= '0;
            end
            counter_48 <= counter_48 + 1'b1;
            if(counter_48 == 48) begin
                counter_48 <= '0;
            end
        end
        blink_counter <= blink_counter + 1'b1;
        // 700*4096 ~ 0.1s at 33 MHz
        if(blink_counter == 700*4096) begin
            blink_counter <= '0;
            // If the user is pressing the button we change color
            if(color_button) begin
                color_counter <= color_counter + 1'b1;
                if(color_counter == 2) begin
                    color_counter <= '0;
                end
            end
            if(switch_demo_button) begin
                switch_demo <= ~switch_demo;
            end
        end
    end

always_comb begin
    // Demo 1 : all leds are red, blue or green at the same time
    data = '0;
    if(color_bit_counter == color_counter) begin
        data = '1;
    end
    // Demo 2 : leds have the pattern RGBRGB...
    if(switch_demo) begin
        data = '0;
        if(color_bit_counter == (counter_3 + color_counter) % 3) begin
            data = '1;
        end
    end
end

endmodule
