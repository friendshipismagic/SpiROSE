module driver_controller #(
    parameter BLANKING_TIME=72
)(
    input clk,
    input clk_enable,
    input nrst,

    // Framebuffer access, 30b wide
    input [29:0] framebuffer_dat,

    // Drivers direct output
    output driver_sclk,
    output driver_gclk,
    output driver_lat,
    output [29:0] drivers_sin,

    // Indicates that the position has changed
    input position_sync,
    // Tells the column_mux module to display a column
    output column_ready,
    // Tells the framebuffer module that the drivers are ready to receive data
    output driver_ready,

    input [47:0] serialized_conf,
    input [47:0] data_in [29:0],
    input new_configuration_ready
);
// UB*D0 and UB*D2
// Red-Green
localparam [15:0] [31:0] DRIVER_LUT0_RG = '{
    3*6 ,
    3*7 ,
    3*9 ,
    3*8 ,
    3*10,
    3*11,
    3*13,
    3*12,
    3*14,
    3*15,
    3*1 ,
    3*0 ,
    3*2 ,
    3*3 ,
    3*5 ,
    3*4
};

//Blue
localparam [15:0] [31:0] DRIVER_LUT0_B = '{
   3*8 ,
   3*9 ,
   3*14,
   3*15,
   3*12,
   3*13,
   3*2 ,
   3*3 ,
   3*0 ,
   3*1 ,
   3*6 ,
   3*7 ,
   3*4 ,
   3*5 ,
   3*10,
   3*11
};

// UB*D1
// Red-Green
localparam [15:0] [31:0] DRIVER_LUT1_RG = '{
   3*2 ,
   3*3 ,
   3*5 ,
   3*4 ,
   3*6 ,
   3*7 ,
   3*9 ,
   3*8 ,
   3*10,
   3*11,
   3*13,
   3*12,
   3*14,
   3*15,
   3*1 ,
   3*0
};

//Blue
localparam [15:0] [31:0] DRIVER_LUT1_B = '{
   3*0 ,
   3*1 ,
   3*6 ,
   3*7 ,
   3*4 ,
   3*5 ,
   3*9 ,
   3*11,
   3*8 ,
   3*10,
   3*14,
   3*15,
   3*12,
   3*13,
   3*2 ,
   3*3
};


/*
 * List of the possible states of the drivers
 * STALL state is the initial state, whe the drivers are not configured
 * PREPARE_CONFIG state is the state where we send FCWRTEN command
 * CONFIG state is the configuration state
 * WRTFC_TIMING we wait 5 cycle to meet timing requirements after a WRTFC
 * PREPARE_DUMP_CONFIG state is the state where we send READFC command
 * DUMP_CONFIG state is the state where we read the config on sout
 * WAIT_FOR_NEXT_SLICE we pause gclk and wait for position_sync
 *
 * Boot-time transition is:
 * STALL for 1 clock cycle (since a new configuration, the default one,
 *   is available)
 * PREPARE_CONFIG fo 15 cycles
 * CONFIG for 48+1 clock cycles
 * WRTFC_TIMING for 5 cycles
 * PREPARE_DUMP_CONFIG for 11 cycles
 * DUMP_CONFIG for 48+5 cycles
 */
enum logic[6:0] {
    STALL,
    PREPARE_CONFIG,
    CONFIG,
    BLANKING,
    SHIFT_REGISTER,
    PAUSE_SCLK,
    PREPARE_DUMP_CONFIG,
    DUMP_CONFIG,
    WRTFC_TIMING,
    WAIT_FOR_NEXT_SLICE
} driver_state;

integer driver_state_counter;
integer wrtgs_cnt;
integer mux_counter;
integer rgb_idx;
integer led_idx;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        driver_state <= STALL;
        driver_state_counter <= '0;
        wrtgs_cnt <= '0;
        mux_counter <= '0;
        rgb_idx <= '0;
        led_idx <= '0;
    end else begin
        if (clk_enable) begin
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
                       driver_state <= WAIT_FOR_NEXT_SLICE;
                        driver_state_counter <= '0;
                    end
                end

                BLANKING: begin
                   wrtgs_cnt <= '0;
                   driver_state_counter <= driver_state_counter + 1'b1;
                   if(driver_state_counter == BLANKING_TIME - 1) begin
                      driver_state_counter <= '0;
                      driver_state <= PAUSE_SCLK;
                   end
                end

                SHIFT_REGISTER: begin
                   driver_state_counter <= driver_state_counter + 1'b1;
                   if(driver_state_counter == 47) begin
                      driver_state_counter <= '0;
                      wrtgs_cnt <= wrtgs_cnt + 1'b1;
                      driver_state <= PAUSE_SCLK;
                      if(wrtgs_cnt == 9) begin
                         wrtgs_cnt <= 0;
                         mux_counter <= mux_counter + 1'b1;
                         driver_state <= BLANKING;
                         if(mux_counter == 7) begin
                            mux_counter <= '0;
                            driver_state <= WAIT_FOR_NEXT_SLICE;
                         end
                      end
                   end
                   rgb_idx <= rgb_idx + 1'b1;
                   if(rgb_idx == 2) begin
                      rgb_idx <= '0;
                      led_idx <= led_idx + 1'b1;
                      if(led_idx == 15) begin
                         led_idx <= '0;
                      end
                   end
                end

                PAUSE_SCLK: begin
                   driver_state <= SHIFT_REGISTER;
                end

                WAIT_FOR_NEXT_SLICE: begin
                   driver_state_counter <= driver_state_counter + 1'b1;
                    if(position_sync) begin
                        driver_state <= BLANKING;
                        driver_state_counter <= '0;
                    end
                end

                default: begin
                    driver_state <= STALL;
                    driver_state_counter <= '0;
                end
            endcase

            if(new_configuration_ready && (driver_state == BLANKING
               || driver_state == WAIT_FOR_NEXT_SLICE
               || driver_state == PAUSE_SCLK || driver_state == SHIFT_REGISTER)) begin
                driver_state_counter <= '0;
                driver_state <= PREPARE_CONFIG;
            end
        end
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
            driver_sclk = clk_enable;
            /*
             * After the WRTFC command we pause SCLK for one cycle to meet
             * timing requirement
             */
            if(driver_state_counter == 0) begin
                driver_sclk = '0;
            end
            driver_gclk = '0;
        end

        WRTFC_TIMING:begin
            driver_sclk = '0;
            driver_gclk = '0;
        end

        DUMP_CONFIG: begin
            driver_sclk = clk_enable;
            /*
             * After the READFC command we pause SCLK for five cycles to meet
             * timing requirement
             */
            if(driver_state_counter < 5) begin
                driver_sclk = '0;
            end
            driver_gclk = '0;
        end

        WAIT_FOR_NEXT_SLICE: begin
            driver_sclk = '0;
            driver_gclk <= '0;
            if(driver_state_counter < 512) begin
                driver_gclk <= clk_enable;
            end
        end

        BLANKING: begin
           driver_sclk = '0;
           driver_gclk = clk_enable & driver_state_counter != 0;
        end

        PAUSE_SCLK: begin
           driver_sclk = '0;
           driver_gclk = clk_enable;
        end

        SHIFT_REGISTER: begin
           driver_sclk = clk_enable;
           driver_gclk = clk_enable;
        end


        default: begin
            driver_sclk = clk_enable;
            driver_gclk = '0;
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
 * LATGS on STREAM state (TODO for LOD state)
 *
 * driver_lat is generated on the falling edge ofthe main clock to respect
 * the hold time after the driver clock **falling edge** see TLC5957 
 * datasheet page...
 */
localparam FCWRTEN=15, READFC=11, WRTFC=5, WRTGS=1, LATGS=3, NO_LAT=0;

always_ff @(negedge clk or negedge nrst)
if(!nrst)
begin
    driver_lat <= 1'b0;
end else begin
    case(driver_state)
        PREPARE_CONFIG, PREPARE_DUMP_CONFIG: begin
            driver_lat <= 1'b1;
        end

        CONFIG: begin
            driver_lat <= 1'b0;
            // Send the WRTFC during the 5 last bits to trigger latch at EOT
            if(driver_state_counter >= 49 - WRTFC) begin
                driver_lat <= 1'b1;
            end
        end

        SHIFT_REGISTER: begin
           driver_lat <= '0;
           if(driver_state_counter == 47 || (driver_state_counter >= 45 && wrtgs_cnt == 9)) begin
              driver_lat <= '1;
           end
        end

        default: driver_lat <= 1'b0;
    endcase
end

/*
 * drivers_sin write the LEDs data or the configuration data depending on the
 * current running state.
 */
always_comb begin
    case(driver_state)
        CONFIG: begin
            if(driver_state_counter != 0) begin
                for(int i = 0; i < 30; i++) begin
                    drivers_sin[i] = serialized_conf[48-driver_state_counter];
                end
            end else begin
                drivers_sin = '0;
            end
        end
        SHIFT_REGISTER: begin
           for(int i = 0; i < 30; i++) begin
              if(i < 10) begin
                 drivers_sin[i] = data_in[i][DRIVER_LUT1_RG[led_idx]];
                 if(rgb_idx == 0) begin
                    drivers_sin[i] = data_in[i][DRIVER_LUT1_B[led_idx]];
                 end
              end else if(i >= 10 || i < 20) begin
                 drivers_sin[i] = data_in[i][DRIVER_LUT1_B[15-led_idx]];
                 if(rgb_idx == 0) begin
                    drivers_sin[i] = data_in[i][DRIVER_LUT1_RG[15-led_idx]];
                 end
              end else begin
                 drivers_sin[i] = data_in[i][DRIVER_LUT0_B[led_idx]];
                 if(rgb_idx == 0) begin
                    drivers_sin[i] = data_in[i][DRIVER_LUT0_RG[led_idx]];
                 end
              end
           end
        end
        default: begin
            drivers_sin = '0;
        end
    endcase
end

assign driver_ready = driver_state == SHIFT_REGISTER && clk_enable;
assign column_ready = (driver_state == SHIFT_REGISTER &&  wrtgs_cnt == 9 && driver_state_counter == 47)
                       || (driver_state == WAIT_FOR_NEXT_SLICE && driver_state_counter == 512);

endmodule
