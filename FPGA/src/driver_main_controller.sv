module driver_main_controller #(parameter BLANKING_TIME = 512 - 9*48
)(
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
 * Default configuration for drivers
 * To change the default configuration, please go to drivers_conf.sv
 */
`include "drivers_conf.sv"

/*
 * List of the possible states of the drivers
 * STALL state is the initial state, whe the drivers are not configured
 * CONFIG state is the configuration state
 * STREAM state is the state used to stream LEDs data to the drivers
 * LOD is the LED Open Detection procedure
 *
 * The STREAM state considers the framebuffer_dat to be already synchronised,
 * it is necessary to synchronise it before the transition to this state.
 */
enum logic[1:0] {STALL, CONFIG, STREAM, LOD} drivers_state;
always_ff @(posegde clk_33 or negedge nrst)
   if(~nrst) begin
   end else begin
   end

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
logic blanking_period;
always_ff @(posedge clk_33 or negedge nrst)
   if(~nrst) begin
      blanking_period <= '0;
   end else begin
      if(drivers_state == STREAM) begin
         blanking_period <= sclk_data_counter < BLANKING_TIME;
      end else begin
         blanking_period <= 1'b0;
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
 * TODO check GS data default value (SLVUAF0 p.16)
 */
assign driver_gclk = clk_33 & nrst &
   (drivers_state == STREAM || drivers_state == LOD);

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
 *
 *   To send a LAT command, write the command in lat_command when the
 *   lat_command is in NO_LAT.
 */
enum [2:0] {NO_LAT, FCWRTEN, WRTFC, WRTGS, LATGS} lat_command;
logic lat_internal_counter;
always_ff @(posedge clk_33 or negedge nrst)
   if(~nrst) begin
      driver_lat <= '0;
      lat_internal_counter <= '0;
   end else begin
      case(lat_command)
         NO_LAT: begin
            driver_lat <= 1'b0;
            lat_internal_counter <= 1'b0;
         end

         FCWRTEN: begin
            driver_lat <= 1'b1;
            lat_internal_counter <= lat_internal_counter + 1;
            // 1 clock shift
            if(lat_internal_counter == 15 - 1)
               lat_command <= NO_LAT;
         end

         WRTFC: begin
            driver_lat <= 1'b1;
            lat_internal_counter <= lat_internal_counter + 1;
            // 1 clock shift
            if(lat_internal_counter == 5 - 1)
               lat_command <= NO_LAT;
         end

         WRTGS: begin
            driver_lat <= 1'b1;
         end

         LATGS: begin
            driver_lat <= 1'b1;
            lat_internal_counter <= lat_internal_counter + 1;
            if(lat_internal_counter == 3 - 1)
               lat_command <= NO_LAT;
         end

         default: driver_lat <= '0;
      endcase
   end

/*
 * LAT Commands sender. Sends FCWRTEN and WRTFC on CONFIG state, and WRTGS and
 * LATGS on STREAM state (TODO for LOD state)
 *
 * begin_config is a micro-state used to send the initialization command to
 * switch drivers to configuration mode.
 */
logic begin_config;
always_ff @(posedge clk_33 or negedge nrst)
   if(~nrst) begin
      lat_command <= NO_LAT;
      begin_config <= 1'b1;
   end else begin
      case(drivers_state)
         STALL: begin
            // If driver is stalled, there is nothing to send
         end

         CONFIG: begin
            begin_config <= 1'b0;
            if(begin_config) begin
               lat_command <= FCWRTEN;
            end
            // Send the WRTFC during the 5 last bits to trigger latch at EOT
            if(sclk_data_counter >= 47 - 5) begin
               lat_command <= WRTFC;
            end
         end

         STREAM: begin
            // Send 8 WRTGS, 1 every 48 SCLK cycles, except for the last one
            // Send 1 LATGS, at the end
            if((sclk_data_counter % 48 == 47) &&
               (sclk_data_counter != 9*48 - 1)) begin
               lat_command <= WRTGS;
            end else if(sclk_data_counter == 9*48 - 3) begin
               lat_command <= LATGS;
            end
         end

         LOD: begin
            // TODO
         end

         default: lat_command <= NO_LAT;
      endcase
   end

/*
 * drivers_sin write the LEDs data or the configuration data depending on the
 * current running state
 *
 */
logic [9:0] drivers_conf_internal_counter;
always_ff @(posedge clk_33 or negedge nrst)
   if(~nrst) begin
      drivers_sin <= '0;
   end else begin
      case(drivers_state)
         STALL: begin
            drivers_sin <= 30'b0;
            drivers_conf_internal_counter <= '0;
         end
         CONFIG: begin
            drivers_sin <= serialized_conf[47 - drivers_conf_internal_counter];
            drivers_conf_internal_counter <= drivers_conf_internal_counter + 1;
         end
         STREAM: begin
            drivers_sin <= framebuffer_dat;
         end
         LOD: begin
            // TODO
         end
         default:
      endcase
   end

endmodule
