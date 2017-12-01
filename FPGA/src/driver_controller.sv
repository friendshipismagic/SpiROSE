/*
 * TODO List:
 *  - Implement LOD
 *  - Add LINE_RESET operation
 */

module driver_controller #(parameter BLANKING_TIME = 512 - 9*48
)(
   input clk_33,
   input nrst,

   // Framebuffer access, 30b wide
   input [29:0] framebuffer_dat,
   // Indicate the beginning of a new slice
   input framebuffer_sync,

   // Drivers direct output
   output reg driver_sclk,
   output reg driver_gclk,
   output reg driver_lat,
   output reg [29:0] drivers_sin,

   // LOD procedure
   input driver_sout,
   output reg [4:0] driver_sout_mux,

   // Default configuration structure
   input [47:0] serialized_conf
);

/*
 * List of the possible states of the drivers
 * STALL state is the initial state, whe the drivers are not configured
 * PREPARE_CONFIG state is the stae where we send FCWRTEN command
 * CONFIG state is the configuration state
 * STREAM state is the state used to stream LEDs data to the drivers
 * LOD is the LED Open Detection procedure
 *
 * The STREAM state considers the framebuffer_dat to be already synchronised,
 * it is necessary to synchronise it before the transition to this state.
 *
 * Boot-time transition is:
 * STALL for 1 clock cycle
 * PREPARE_CONFIG fo 15 cycles
 * CONFIG for 48 clock cycles
 * LOD for 1 clock cycle (TODO), then waits for framebuffer sync signal
 * STREAM until reset
 */
enum logic[2:0] {STALL, PREPARE_CONFIG, CONFIG, STREAM, LOD} driver_state;
logic [7:0] driver_state_counter;
always_ff @(posedge clk_33)
    if(~nrst) begin
        driver_state <= STALL;
        driver_state_counter <= '0;
    end else begin
        case(driver_state)
            STALL: begin
                driver_state <= PREPARE_CONFIG;
            end

            PREPARE_CONFIG: begin
                driver_state_counter <= driver_state_counter + 1'b1;
                if(driver_state_counter == 14) begin
                    driver_state <= CONFIG;
                    driver_state_counter <= '0;
                end
            end

            CONFIG: begin
                driver_state_counter <= driver_state_counter + 1'b1;
                if(driver_state_counter == 47) begin
                    driver_state <= LOD;
                    driver_state_counter <= '0;
                end
            end

            LOD: begin
                // TODO
                if(framebuffer_sync) begin
                    driver_state <= STREAM;
                end
            end

            STREAM: begin
                // Final state, nothing to do
            end

            default: begin
                driver_state <= STALL;
                driver_state_counter <= '0;
            end
        endcase
    end

/*
 * TODO
 * SCLK Data send counter. This counter counts the number of clock cycles
 * after FCWRTEN and LATGS commands.
 * In CONFIG state, it corresponds to the number of bits to write into
 * configuration buffer.
 * In STREAM state, it corresponds to the number of data bits already sent.
 */
logic [9:0] segment_counter;
always_ff @(posedge clk_33)
    if(~nrst) begin
        segment_counter <= '0;
    end else begin
        case(driver_state)
            STREAM: begin
                segment_counter <= segment_counter + 1'b1;
                if(segment_counter == 512 - 1)
                    segment_counter <= '0;
            end
            default: segment_counter <= '0;
        endcase
    end

/*
 * Blanking mode. The GCLK must be 512 clock cycles, but we send
 * 9(bits) * 48 (R+G+B channel) = 432 SCLK cycles. Thus we need to wait for
 * 512 - 432 = 80 SCLK cycles. This blanking time should be done at the begining
 * to avoid latching issues.
 * This blanking is necessary only when displaying data, thus in STREAM mode.
 */
wire blanking_period;
assign blanking_period = nrst & (segment_counter < BLANKING_TIME);

/*
 *
 */
logic [7:0] shift_register_counter;
always_ff @(posedge clk_33)
    if(~nrst) begin
        shift_register_counter <= '0;
    end else begin
        case(driver_state)
            CONFIG: begin
                shift_register_counter <= shift_register_counter + 1'b1;
                if(shift_register_counter == 47) begin
                    shift_register_counter <= '0;
                end
            end

            LOD: begin
                // TODO
				shift_register_counter <= '0;
            end

            STREAM: begin
                // Final state
				shift_register_counter <= '0;
				if(~blanking_period) begin
					shift_register_counter <= shift_register_counter + 1'b1;
					if(shift_register_counter == 47) begin
						shift_register_counter <= '0;
					end
				end
            end

            default: begin
                shift_register_counter <= '0;
            end
        endcase
    end

/*
 * driver_sclk drives the SCLK of the drivers.
 * There is no difference between the configuration mode and the stream mode.
 * The SCLK is on when device is not in reset and not in blanking mode.
 */
assign driver_sclk = clk_33 & nrst;

/*
 * driver_gclk drives the GSCLK of the drivers.
 * The GSCLK clock must be enabled only when the device is in STREAM and LOD
 * modes. The clock must be enabled after the GS data bank have already been
 * written.
 * TODO check GS data default value (SLVUAF0 p.16)
 */
assign driver_gclk = clk_33 & nrst
                     & (driver_state == STREAM || driver_state == LOD);

/*
 * driver_lat drives the LAT of the drivers.
 * The LAT is a command signal for latching. It does the states transitions.
 * It is used by:
 *
 * - FCWRTEN command (15 SCLK rising edges) for enabling configuration mode
 * - WRTFC command (5 SCLK rising edges) for writing in configuration mode
 *
 * - WRTGS command (1 SCLK rising edge) for writing to GS latch
 * - LATGS command (3 SCLK rising edges) for doing a WRTGS, then writing the
 *   first GS bank to the second
 *
 * Sends FCWRTEN on PREPARE_CONFIG state, WRTFC on CONFIG state, and WRTGS and
 * LATGS on STREAM state (TODO for LOD state)
 */
localparam FCWRTEN=15, WRTFC=5, WRTGS=1, LATGS=3, NO_LAT=0;
always_comb begin
    case(driver_state)
        STALL: begin
            driver_lat = '0;
        end

        PREPARE_CONFIG: begin
            driver_lat = 1'b1;
        end

        CONFIG: begin
            driver_lat = 1'b0;
            // Send the WRTFC during the 5 last bits to trigger latch at EOT
            if(shift_register_counter >= 48 - WRTFC) begin
                driver_lat = 1'b1;
            end
        end

        STREAM: begin
            driver_lat = 1'b0;
            // Send 8 WRTGS, 1 every 48 SCLK cycles, except for the last one
            // Send 1 LATGS, at the end
            // TODO: LINERESET
            if((shift_register_counter >= 48 - WRTGS)
                || (segment_counter >= 512 - LATGS)) begin
                driver_lat = 1'b1;
            end
        end

        LOD: begin
            driver_lat = 1'b0;
            // TODO
        end

        default: driver_lat = 1'b0;
    endcase
end

/*
 * drivers_sin write the LEDs data or the configuration data depending on the
 * current running state.
 */
always_comb begin
    case(driver_state)
        CONFIG: begin
            for(int i = 0; i < 30; i++) begin
                drivers_sin[i] = serialized_conf[47 - shift_register_counter];
                driver_sout_mux = '0;
            end
        end
        STREAM: begin
            drivers_sin = framebuffer_dat;
            driver_sout_mux = '0;
        end
        LOD: begin
            drivers_sin = '0;
            // TODO: LOD procedure
            driver_sout_mux = 5'(driver_sout);
        end
        default: begin
            drivers_sin = '0;
            driver_sout_mux = '0;
        end
    endcase
end

endmodule
