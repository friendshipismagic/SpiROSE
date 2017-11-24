module driver_main_controller (
   input clk_33,
   input nrst,

   // Framebuffer access, 30b wide
   input [29:0] framebuffer_dat,
   input framebuffer_sync,

   // Drivers direct output
   output driver_sclk,
   output driver_gclk,
   output driver_lat,
   output [29:0] drivers_sin

   // LOD procedure
   input driver_sout,
   output [4:0] driver_sout_mux;
);

/*
 * List of the possible states of the drivers
 * STALL state is the initial state, whe the drivers are not configured
 * CONFIG state is the configuration state
 * STREAM state is the state used to stream LEDs data to the drivers
 * LOD is the LED Open Detection procedure
 */
enum logic[1:0] {STALL, CONFIG, STREAM, LOD} drivers_state;

/*
 * SCLK Data send counter. This counter counts the number of clock cycles
 * after FCWRTEN and LATGS commands.
 * In CONFIG state, it corresponds to the number of bits to write into
 * configuration buffer.
 * In STREAM state, it corresponds to the number of data bits already sent.
 */
logic sclk_data_counter;
always_ff @(posedge clk_33 or negedge nrst)
   if(~nrst) begin
      sclk_data_counter <= '0;
   end else begin
      if(lat_command == FCWRTEN || lat_command == LATGS)
         sclk_data_counter <= '0;
      else
         sclk_data_counter <= sclk_data_counter + 1'b1;
   end

/*
 * Blanking mode. The GCLK must be 512 clock cycles, but we send
 * 9(bits) * 48 (R+G+B channel) = 432 SCLK cycles. Thus we need to wait for
 * 512 - 432 = 80 SCLK cycles. This blanking time should be done at the begining
 * to avoid latching issues.
 * This blanking is necessary only when displaying data, thus in STREAM mode.
 */
localparam blanking_sclk_start = 9*48;
logic blanking_period;
always_ff @(posedge clk_33 or negedge nrst)
   if(~nrst) begin
      blanking_period <= '0;
   end else begin
      if(drivers_state == STREAM) begin
         blanking_period <= sclk_data_counter >= blanking_sclk_start;
      end
   end

/*
 * driver_sclk drives the SCLK of the drivers.
 * There is no difference between the configuration mode and the stream mode.
 * The SCLK is on when device is not in reset and not in blanking mode.
 */
assign driver_sclk = clk_33 & nrst & ~blanking_period;

/*
 * driver_gclk drives the GSCLK of the drivers.
 * The GSCLK clock must be enabled only when the device is in STREAM and LOD
 * modes. The clock must be enabled after the GS data bank have already been
 * written.
 * TODO
 */
assign driver_gclk = clk_33 & nrst;

/*
 * driver_lat drives the LAT of the drivers.
 * The LAT is a command signal for latching. It does the states transitions.
 * It is used by:
 *
 * - FCWRTEN command (15 SCLK rising edges) for enabling configuration mode
 * - WRTFC command (5 SCLK rising edges) for writing in configuration mode
 *
 * - WRTGS command (1 SCLK rising edge) for writing to GS latch
 * - LATGS command (3 SCLK rising edges) for doing a WTYGS, then writing the
 *   first GS bank to the second
 */
enum [2:0] {NO_LAT, FCWRTEN, WRTFC, WRTGS, LATGS} lat_command;
always_ff @(posedge clk_33 or negedge nrst)
   if(~nrst) begin
      driver_lat <= '0;
   end else begin
   end

/*
 * drivers_sin write the LEDs data or the configuration data depending on the
 * current running state
 *
 */
always_ff @(posedge clk_33 or negedge nrst)
   if(~nrst) begin
      drivers_sin <= '0;
   end else begin
   end

endmodule
