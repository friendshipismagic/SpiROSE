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
    output logic write_enable,

    // Signal send by SPI to tell the rgb logic to start writing slices in ram
    input  rgb_enable,
    // Indicates that enough slices have been writing in ram to begin display
    output stream_ready
);

localparam IMAGE_SIZE = 80*48;
localparam IMAGE_IN_RAM = 3;
localparam SLICES_IN_RAM_BEFORE_STREAM=1;

logic blanking;
// hsync and vsync drives low when we are on blanking area
assign blanking = ~hsync | ~vsync;

logic [31:0] pixel_counter;

always_ff @(posedge rgb_clk or negedge nrst)
    if(~nrst) begin
        ram_data <= '0;
    end else begin
        /*
         * We don't write anything in blanking area but it is controlled by
         * writeEnable signal. We use 5 bits for the red, 6 for the green,
         * and 5 for the blue.
         */
        ram_data <= {rgb[23:19], rgb[15:10], rgb[7:3]};
    end

always_ff @(posedge rgb_clk or negedge nrst)
    if(~nrst) begin
        ram_addr <= '0;
    end else begin
        if(pixel_counter == IMAGE_SIZE*IMAGE_IN_RAM) begin
            ram_addr <= '0;
        end
        ram_addr <= ram_addr + ~32'(blanking);
    end

always_ff @(posedge rgb_clk or negedge nrst)
    if(~nrst) begin
        write_enable <= '0;
        pixel_counter <= '0;
           end else begin
        write_enable <= '0;
        pixel_counter <= '0;
        /*
         * when rgb_enable drives high we may be in the middle of a frame, thus
         * when vsync drives low we check pixel_cnt, if it is not IMAGE_SIZE
         * we reset it so we are ready for a real start. stream_ready would
         * not have been sent so we would not have display those unrelevant data
         * we just write.
         */
        if (rgb_enable) begin
            write_enable <= ~blanking;
            pixel_counter <= pixel_counter + ~32'(blanking);
            if(pixel_counter == IMAGE_SIZE*IMAGE_IN_RAM
                || (~vsync && pixel_counter != IMAGE_SIZE)) begin
                pixel_counter <= '0;
            end
        end
    end

always_ff @(posedge rgb_clk or negedge nrst)
    if(~nrst) begin
        stream_ready <= '0;
    end else begin
        stream_ready <= '0;
        // We don't do anything until the SPI tells us to start
        if(rgb_enable) begin
            // stream ready drives high when we have written enough slices in ram
            stream_ready <= stream_ready ? 1'b1 : pixel_counter >= SLICES_IN_RAM_BEFORE_STREAM*IMAGE_SIZE;
        end
    end

endmodule

