module rgb_logic #(
    parameter RAM_ADDR_WIDTH=32,
    parameter RAM_DATA_WIDTH=16
)(
    input rgb_clk,
    input nrst,
    // We won't use every bits of the rgb because of driver bandwidth issue
    /* verilator lint_off UNUSED */
    input [23:0] rgb,
    /* verilator lint_on UNUSED */
    input hsync,
    input vsync,

    output [RAM_ADDR_WIDTH-1:0] ram_addr,
    output [RAM_DATA_WIDTH-1:0] ram_data,
    output logic write_enable
);

localparam IMAGE_SIZE = 80*48;
localparam IMAGE_IN_RAM = 3;

logic blanking;
assign blanking = hsync | vsync;

logic new_frame;
assign new_frame = hsync & vsync;

logic [31:0] pixel_counter;

always_ff @(posedge rgb_clk or negedge nrst)
    if(~nrst) begin
        ram_data <= '0;
    end else begin
        // We don't write anything in blanking area but it is controlled by writeEnable signal
        // We use 5 bits for the red, 6 for the green, and 5 for the blue
        ram_data <= {rgb[23:19], rgb[15:10], rgb[7:3]};
    end

always_ff @(posedge rgb_clk or negedge nrst)
    if(~nrst) begin
        ram_addr <= '0;
    end else begin
        if(new_frame || pixel_counter == IMAGE_SIZE*IMAGE_IN_RAM) begin
            ram_addr <= '0;
        end
        ram_addr <= ram_addr + ~32'(blanking);
    end

always_ff @(posedge rgb_clk or negedge nrst)
    if(~nrst) begin
        write_enable <= '0;
        pixel_counter <= '0;
    end else begin
        write_enable <= ~blanking;
        pixel_counter <= pixel_counter + ~32'(blanking);
        if(pixel_counter == IMAGE_SIZE*IMAGE_IN_RAM) begin
            pixel_counter <= '0;
        end
    end

endmodule

