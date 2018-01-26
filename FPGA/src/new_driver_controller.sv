module new_driver_controller (
    input clk,
    input clk_enable,
    input nrst,

    // Framebuffer access, 30b wide
    input [29:0] framebuffer_dat,

    // Drivers direct output
    output drv_sclk,
    output drv_gclk,
    output drv_lat,
    output [29:0] drv_sin,

    // Indicates that the position has changed
    input position_sync,
    // Tells the column_mux module to display a column
    output column_ready,
    // Tells the framebuffer module that the drivers are ready to receive data
    output driver_ready,

    // Configuration input
    input [47:0] serialized_conf,
    input new_configuration_ready
);

/*
 * List of the possible states of the drivers
 * STALL state is the initial state, whe the drivers are not configured
 * CONFIG state is the configuration state
 * WRTFC_TIMING we wait 5 cycle to meet timing requirements after a WRTFC
 * STREAM state is the state used to stream LEDs data to the drivers
 * WAIT_FOR_NEXT_SLICE we pause gclk and wait for position_sync
 *
 * Boot-time transition is:
 * STALL for 1 clock cycle (since a new configuration, the default one,
 *   is available)
 * PREPARE_CONFIG fo 15 cycles
 * CONFIG for 48+1 clock cycles
 * WRTFC_TIMING for 5 cycles
 * alternate between STREAM and WAIT_FOR_NEXT_SLICE until reset
 */
enum logic[3:0] {
    STALL,
    PREPARE_CONFIG,
    CONFIG,
    STREAM,
    WRTFC_TIMING,
    WAIT_FOR_NEXT_SLICE
} driver_state;

integer driver_state_counter;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        driver_state <= STALL;
        driver_state_counter <= '0;
    end else begin
        if (clk_enable) begin
            case(driver_state)
                STALL: begin
                    if (new_configuration_ready) begin
                        driver_state <= PREPARE_CONFIG;
                    end
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
                        driver_state <= WAIT_FOR_NEXT_SLICE;
                        driver_state_counter <= '0;
                    end

                end

                WAIT_FOR_NEXT_SLICE: begin
                    if(position_sync) begin
                        driver_state <= STREAM;
                    end
                    if(new_configuration_ready) begin
                       driver_state <= PREPARE_CONFIG;
                    end
                end

                STREAM: begin
                    // If we have sent the whole slice wait for the next
                    if(mux_counter == 7 && segment_counter == 512) begin
                        driver_state <= WAIT_FOR_NEXT_SLICE;
                    end
                    if(new_configuration_ready) begin
                       driver_state_counter <= '0;
                       driver_state <= PREPARE_CONFIG;
                    end
                end

                default: begin
                    driver_state <= STALL;
                    driver_state_counter <= '0;
                end
            endcase
        end
    end

/*
 * GCLK cycle counter. This process counts the number of GCLK clock cycles in
 * STREAM state. In 9-bit poker mode a segment should be 512 cycle. To meet the
 * timing requirement it is necessary to pause GCLK for one cycle after a LATGS
 * or LINERESET, thus the segment counter goes up to 512 instead of 511 to
 * count this extra one cycle.
 */
logic stop_gclk;
integer segment_counter;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        segment_counter <= '0;
        stop_gclk <= '0;
    end else begin
        if (clk_enable) begin
            segment_counter <= segment_counter + 1'b1;
            if(segment_counter == 512) begin
               segment_counter <= '0;
            end
            case(driver_state)
                STREAM: begin
                    // Never stop GCLK on STREAM mode
                    stop_gclk <= '0;
                end

                WAIT_FOR_NEXT_SLICE: begin
                    if(segment_counter == 512) begin
                        stop_gclk <= '1;
                    end
                end

                default: begin
                    stop_gclk <= '0;
                    segment_counter <= '0;
                end
            endcase
        end
    end

integer mux_counter;
always_ff @(posedge clk or negedge nrst)
   if(~nrst) begin
      mux_counter <= '0;
   end else begin
      if(clk_enable) begin
         if(driver_state == STREAM && segment_counter == 512) begin
            mux_counter <= mux_counter + 1'b1;
            if(mux_counter == 7) begin
               mux_counter <= '0;
            end
         end
      end
   end

/*
 * Blanking mode. The GCLK segment must be 512 clock cycles, but we send
 * 9(bits) * 48 (R+G+B channel) + 8 timing cycle = 440 SCLK cycles. Thus we
 * need to wait for 512 - 440 = 72 SCLK cycles. This blanking time should be
 * done at the beginning to avoid latching issues.
 */
logic blanking_period;
assign blanking_period = nrst & (segment_counter < 72);

/*
 * SCLK data counter.
 */
integer shift_register_counter;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        shift_register_counter <= '0;
    end else if (drv_sclk) begin
        shift_register_counter <= shift_register_counter + 1'b1;
        if(shift_register_counter == 48) begin
           shift_register_counter <= '0;
        end
    end

/*
 * SCLK, directly exported, no delay
 */
always_comb begin
    drv_sclk = '0;
    case(driver_state)
        CONFIG: begin
            /*
             * After the WRTFC command we pause SCLK for one cycle to meet
             * timing requirement
             */
            if(shift_register_counter != 0) begin
                drv_sclk = clk_enable;
            end
        end

        STREAM: begin
            /*
             * After the WRTGS command we pause SCLK for one cycle to meet
             * timing requirement. After a LATGS we need more than one cycle
             * thus it is easier to just pause SCLK for the whole blanking
             * period.
             */
            drv_sclk = clk_enable & ~blanking_period;

            if(segment_counter < 72 || segment_counter == 72
               || segment_counter == 72+49 || segment_counter == 72+2*49
               || segment_counter == 72+3*49 || segment_counter == 72+4*49
               || segment_counter == 72+5*49 || segment_counter == 72+6*49
               || segment_counter == 72+7*49 || segment_counter == 72+8*49
               ) begin
                drv_sclk = 1'b0;
            end
        end

        default: begin
           drv_sclk = '0;
        end

    endcase
end

/*
 * GCLK, directly exported, no delay
 */
always_comb begin
    drv_gclk = '0;
    case(driver_state)
       STREAM: begin
           /*
            * After the LATGS command we pause GCLK for one cycle to meet
            * timing requirement
            */
            if(segment_counter != 0) begin
                drv_gclk = clk_enable;
            end
       end

        WAIT_FOR_NEXT_SLICE: begin
            if(~stop_gclk && segment_counter != 0) begin
                drv_gclk <= clk_enable;
            end
        end

        default: begin
           drv_gclk = 1'b0;
        end
    endcase
end

/*
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
 * LATGS on STREAM state
 *
 * driver_lat is generated on the falling edge ofthe main clock to respect
 * the hold time after the driver clock **falling edge** see TLC5957
 * datasheet page...
 */
localparam FCWRTEN=15, READFC=11, WRTFC=5, WRTGS=1, LATGS=3, NO_LAT=0;

logic drv_lat_comb;
always_comb begin
   drv_lat_comb = 1'b0;
   case(driver_state)
      PREPARE_CONFIG: begin
          // Is in PREPARE_CONFIG for 15 SCLK cycles
          drv_lat_comb = 1'b1;
      end

      CONFIG: begin
          // Send the WRTFC during the 5 last bits to trigger latch at EOT
          if(shift_register_counter >= 49 - WRTFC) begin
              drv_lat_comb = 1'b1;
          end
      end

      STREAM: begin
          // Send 8 WRTGS, 1 every 48 SCLK cycles, except for the last one
          // Send 1 LATGS, at the end
          // TODO: LINERESET
          if(shift_register_counter >= 49 - WRTGS) begin
              drv_lat_comb = 1'b1;
          end
          if(segment_counter >= 513 - LATGS) begin
              drv_lat_comb = 1'b1;
          end
      end

      default: begin
         drv_lat_comb = 1'b0;
      end
   endcase
end

/*
 * drivers_sin write the LEDs data or the configuration data depending on the
 * current running state.
 */
logic [29:0] drv_sin_tolut;
always_comb begin
    drv_sin_tolut = '0;
    // If configurating, send config
    if(driver_state == CONFIG && shift_register_counter != 0) begin
        for(int i = 0; i < 30; i++) begin
           drv_sin_tolut[i] = serialized_conf[48-shift_register_counter];
        end
    end else if(driver_state == STREAM || driver_state == WAIT_FOR_NEXT_SLICE) begin
        drv_sin_tolut = framebuffer_dat;
    end
end

logic drv_sin_comb;
driver_sin_lut ublock_lut (
   .drv_sin_tolut(drv_sin_tolut),
   .drv_sin(drv_sin_comb)
);

// Export all signals with delay
always @(posedge clk or negedge nrst)
   if(~nrst) begin
      drv_lat <= '0;
      drv_sin <= '0;
   end else if(clk_enable) begin
      drv_lat <= drv_lat_comb;
      drv_sin <= drv_sin_comb;
   end

// Is the column ready to be displayed
assign column_ready = (driver_state == STREAM || driver_state == WAIT_FOR_NEXT_SLICE)
                      && segment_counter == 512;

// Are the drivers ready to accept data from the framebuffer
assign driver_ready = driver_state == STREAM
                      && shift_register_counter != 0
                      && ~blanking_period
                      && ~clk_enable;

endmodule
