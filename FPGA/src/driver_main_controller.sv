module driver_main_controller (
   input clk_50,
   input clk_33,
   input nrst,

   // Framebuffer access, 30b wide
   input [29:0] framebuffer_dat,
   input [29:0] framebuffer_adr,

   // Drivers direct output
   output driver_sclk,
   output driver_gclk,
   output driver_lat,
   output [29:0] drivers_sin
)

/*
 * List of the possible states of the drivers
 * STALL state is the initial state, whe the drivers are not confiured
 * CONFIG state is the configuration state
 * STREAM state is the state used to stream LEDs data to the drivers
 * LOD is the LED Open Detection procedure
 */
enum logic[1:0] {STALL, CONFIG, STREAM, LOD} drivers_state;

/*
 * driver_sclk drives the SCLK of the drivers.
 * There is no difference between the configuration mode and the stream mode.
 * The SCLK is always on when device is not in reset.
 */
assign driver_sclk = clk_33 & nrst;

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
 * - LATGS command (3 SCLK rising edges) for writing the first GS bank to the
 *   second and doing a WRTGS at the same time
 */
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

endmodule
