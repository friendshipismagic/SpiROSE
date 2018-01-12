module driver_controller #(
    parameter BLANKING_TIME=72
)(
    input clk_hse,
    input clk_lse,
    input nrst,

    // Framebuffer access, 30b wide
    input [29:0] framebuffer_dat,

    // Drivers direct output
    output driver_sclk,
    output driver_gclk,
    output driver_lat,
    output [29:0] drivers_sin,

    // LOD procedure
    input driver_sout,
    output [4:0] driver_sout_mux,

    // Default configuration structure
    input [47:0] serialized_conf,

    // Indicates that the position has changed
    input position_sync,
    // Tells the column_mux module to display a column
    output column_ready,
    // Tells the framebuffer module that the drivers are ready to receive data
    output driver_ready
);

/*
 * Here we create a quadrature-phase clock based on clk_lse. It will be use to
 * split the lat/sin/state logic from the sclk/gclk logic in order to meet the
 * timing requirement of the driver.
 */
logic clk_lse_quad;
always_ff @(negedge clk_hse or negedge nrst)
    if(~nrst) begin
        clk_lse_quad <= '0;
    end else begin
        clk_lse_quad <= ~clk_lse_quad;
    end

/*
 * List of the possible states of the drivers
 * STALL state is the initial state, whe the drivers are not configured
 * PREPARE_CONFIG state is the state where we send FCWRTEN command
 * CONFIG state is the configuration state
 * WRTFC_TIMING we wait 5 cycle to meet timing requirements after a WRTFC
 * PREPARE_DUMP_CONFIG state is the state where we send READFC command
 * DUMP_CONFIG state is the state where we read the config on sout
 * LOD is the LED Open Detection procedure
 * STREAM state is the state used to stream LEDs data to the drivers
 * WAIT_FOR_NEXT_SLICE we pause gclk and wait for position_sync
 *
 * Boot-time transition is:
 * STALL for 1 clock cycle
 * PREPARE_CONFIG fo 15 cycles
 * CONFIG for 48+1 clock cycles
 * WRTFC_TIMING for 5 cycles
 * PREPARE_DUMP_CONFIG for 11 cycles
 * DUMP_CONFIG for 48+5 cycles
 * LOD for 1 clock cycle (TODO), then waits for position_sync signal
 * alternate between STREAM and WAIT_FOR_NEXT_SLICE until reset
 */
enum logic[2:0] { STALL              ,
                  PREPARE_CONFIG     ,
                  CONFIG             ,
                  STREAM             ,
                  LOD                ,
                  PREPARE_DUMP_CONFIG,
                  DUMP_CONFIG        ,
                  WRTFC_TIMING       ,
                  WAIT_FOR_NEXT_SLICE
                } driver_state;

logic [7:0] driver_state_counter;
always_ff @(posedge clk_lse or negedge nrst)
    if(~nrst) begin
        driver_state <= STALL;
        driver_state_counter <= '0;
    end else begin
        case(driver_state)
            STALL: begin
                driver_state <= PREPARE_CONFIG;
            end

            PREPARE_CONFIG: begin
                // Here we wait 15 cycles to send the FCWRTEN command
                driver_state_counter <= driver_state_counter + 1'b1;
                if(driver_state_counter == 14) begin
                    driver_state <= CONFIG;
                    driver_state_counter <= '0;
                end
            end

            CONFIG: begin
                /*
                 * Here we wait 1 cycle to meet the timing requirement, and
                 * then 47 cycles to send the config data.
                 */
                driver_state_counter <= driver_state_counter + 1'b1;
                if(driver_state_counter == 48) begin
                    driver_state <= WRTFC_TIMING;
                    driver_state_counter <= '0;
                end
            end

            WRTFC_TIMING: begin
                // Here we wait 5 cycles to meet timing requirements
                driver_state_counter <= driver_state_counter + 1'b1;
                if(driver_state_counter == 5) begin
                    driver_state <= PREPARE_DUMP_CONFIG;
                    driver_state_counter <= '0;
                end

            end

            PREPARE_DUMP_CONFIG: begin
                // Here we wait 11 cycles to send the READFC command
                driver_state_counter <= driver_state_counter + 1'b1;
                if(driver_state_counter == 10) begin
                    driver_state <= DUMP_CONFIG;
                    driver_state_counter <= '0;
                end
            end

            DUMP_CONFIG: begin
                /*
                 * Here we wait 5 cycles to meet the timing requirement, and
                 * then 47 cycle to read the config data.
                 */
                driver_state_counter <= driver_state_counter + 1'b1;
                if(driver_state_counter == 47+5) begin
                    driver_state <= LOD;
                    driver_state_counter <= '0;
                end
            end

            LOD: begin
                // TODO
                driver_state <= WAIT_FOR_NEXT_SLICE;
            end

            STREAM: begin
                // If we have sent the whole slice wait for the next
                if(mux_counter == 7 && segment_counter == 512) begin
                    driver_state <= WAIT_FOR_NEXT_SLICE;
                end
            end

            WAIT_FOR_NEXT_SLICE: begin
                if(position_sync) begin
                    driver_state <= STREAM;
                end
            end

            default: begin
                driver_state <= STALL;
                driver_state_counter <= '0;
            end
        endcase
    end

/*
 * GCLK cycle counter. This counter counts the number of GCLK clock cycles in
 * STREAM state. In 9-bit poker mode a segment should be 512 cycle. To meet the
 * timing requirement it is necessary to pause GCLK for one cycle after a LATGS
 * or LINERESET, thus the segment counter goes up to 512 instead of 511 to
 * count this extra one cycle.
 */
logic [10:0] segment_counter;
logic [2:0]  mux_counter;
always_ff @(posedge clk_lse or negedge nrst)
    if(~nrst) begin
        segment_counter <= '0;
        mux_counter <= '0;
    end else begin
        case(driver_state)
            STREAM: begin
                segment_counter <= segment_counter + 1'b1;
                if(segment_counter == 512) begin
                    segment_counter <= '0;
                    mux_counter <= mux_counter + 1'b1;
                end
            end
            default: begin
                segment_counter <= '0;
                mux_counter <= '0;
            end
        endcase
    end

/*
 * Blanking mode. The GCLK segment must be 512 clock cycles, but we send
 * 9(bits) * 48 (R+G+B channel) + 8 timing cycle = 440 SCLK cycles. Thus we
 * need to wait for 512 - 440 = 72 SCLK cycles. This blanking time should be
 * done at the beginning to avoid latching issues.
 */
wire blanking_period;
assign blanking_period = nrst & (segment_counter < BLANKING_TIME);

/*
 * SCLK data counter. This counter counts the number of SCLK clock cycles in
 * STREAM and CONFIG state. In 9-bit poker mode a segment should be 512 cycle.
 * To meet the timing requirement it is necessary to pause SCLK for one cycle
 * after a WRTGS or WRTFC, thus the counter goes up to 48 instead of 47 to
 * count this extra one cycle.
 */
logic [7:0] shift_register_counter;
always_ff @(posedge clk_lse or negedge nrst)
    if(~nrst) begin
        shift_register_counter <= '0;
    end else begin
        case(driver_state)
            CONFIG: begin
                shift_register_counter <= shift_register_counter + 1'b1;
                if(shift_register_counter == 48) begin
                    shift_register_counter <= '0;
                end
            end

            DUMP_CONFIG: begin
                shift_register_counter <= shift_register_counter + 1'b1;
                if(shift_register_counter == 47+5) begin
                    shift_register_counter <= '0;
                end
            end

            STREAM: begin
                // Final state
                shift_register_counter <= '0;
                if(~blanking_period) begin
                    shift_register_counter <= shift_register_counter + 1'b1;
                    if(shift_register_counter == 48) begin
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
 *
 * driver_gclk drives the GCLK of the drivers.
 * The GCLK clock must be enabled only when the device is in STREAM and LOD
 * modes. The clock must be enabled after the GS data bank have already been
 * written.
 * TODO check GS data default value (SLVUAF0 p.16)
 */
always_comb begin
    case(driver_state)
        CONFIG: begin
            driver_sclk = clk_lse_quad;
            /*
             * After the WRTFC command we pause SCLK for one cycle to meet
             * timing requirement
             */
            if(shift_register_counter == 0) begin
                driver_sclk = '0;
            end
            driver_gclk = '0;
        end

        WRTFC_TIMING:begin
            driver_sclk = '0;
            driver_gclk = '0;
        end

        DUMP_CONFIG: begin
            driver_sclk = clk_lse_quad;
            /*
             * After the READFC command we pause SCLK for five cycles to meet
             * timing requirement
             */
            if(shift_register_counter < 5) begin
                driver_sclk = '0;
            end
            driver_gclk = '0;
        end

        STREAM: begin
            /*
             * After the WRTGS command we pause SCLK for one cycle to meet
             * timing requirement. After a LATGS we need more than one cycle
             * thus it is easier to just pause SCLK for the whole blanking
             * period.
             */
            driver_sclk = clk_lse_quad & ~blanking_period;
            if(shift_register_counter == 0) begin
                driver_sclk = '0;
            end
            driver_gclk = clk_lse_quad;
            /*
             * After the LATGS command we pause GCLK for one cycle to meet
             * timing requirement
             */
            if(segment_counter == 0) begin
                driver_gclk = '0;
            end
        end
        LOD: begin
            driver_sclk = '0;
            driver_gclk = '0;
        end
        default: begin
            driver_sclk = clk_lse_quad;
            driver_gclk = '0;
        end
    endcase
end

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
localparam FCWRTEN=15, READFC=11, WRTFC=5, WRTGS=1, LATGS=3, NO_LAT=0;
always_comb begin
    case(driver_state)
        PREPARE_CONFIG, PREPARE_DUMP_CONFIG: begin
            driver_lat = 1'b1;
        end

        CONFIG: begin
            driver_lat = 1'b0;
            // Send the WRTFC during the 5 last bits to trigger latch at EOT
            if(shift_register_counter >= 49 - WRTFC) begin
                driver_lat = 1'b1;
            end
        end

        STREAM: begin
            driver_lat = 1'b0;
            // Send 8 WRTGS, 1 every 48 SCLK cycles, except for the last one
            // Send 1 LATGS, at the end
            // TODO: LINERESET
            if((shift_register_counter >= 49 - WRTGS)
                || (segment_counter >= 513 - LATGS)) begin
                driver_lat = 1'b1;
            end
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
            driver_sout_mux = '0;
            if(shift_register_counter != 0) begin
                for(int i = 0; i < 30; i++) begin
                    drivers_sin[i] = serialized_conf[48-shift_register_counter];
                end
            end else begin
                drivers_sin = '0;
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
