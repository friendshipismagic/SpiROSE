module driver_controller #(
    parameter BLANKING_TIME=72
)(
    input clk,
    input clk_enable,
    input nrst,

    output driver_sclk,
    output driver_gclk,
    output driver_lat,
    output [29:0] drivers_sin,
    output [7:0] mux_out,

    input SOF,
    output EOC,

    input [431:0] data [14:0],
    input [47:0] config_data,
    input start_config,
    output end_config
);

logic should_send_config;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        should_send_config <= '0;
    end else if (start_config) begin
        should_send_config <= '1;
    end else if (driver_state == PREPARE_CONFIG) begin
        should_send_config <= '0;
    end

`include "drivers_conf.svh"
logic [47:0] config_buffer;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        config_buffer <= serialized_conf;
    end else if (start_config) begin
        config_buffer <= config_data;
    end

/*
 * List of the possible states of the drivers
 * STALL state is the initial state, whe the drivers are not configured
 * PREPARE_CONFIG state is the state where we send FCWRTEN command
 * CONFIG state is the configuration state
 * WRTFC_TIMING we wait 5 cycle to meet timing requirements after a WRTFC
 * PREPARE_DUMP_CONFIG state is the state where we send READFC command
 * DUMP_CONFIG state is the state where we read the config on sout
 * WAIT_FOR_SOF we pause gclk and wait for SOF
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
enum integer {
    STALL,
    PREPARE_CONFIG,
    CONFIG,
    BLANKING,
    SHIFT_REGISTER,
    PAUSE_SCLK,
    PREPARE_DUMP_CONFIG,
    DUMP_CONFIG,
    WRTFC_TIMING,
    WAIT_END_GCLK_SEGMENT,
    WAIT_FOR_SOF
} driver_state;

integer driver_state_counter;
integer wrtgs_cnt;
integer mux_counter;
integer data_idx;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        driver_state <= STALL;
        driver_state_counter <= '0;
        wrtgs_cnt <= '0;
        mux_counter <= '0;
        data_idx <= '0;
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
                       driver_state <= WAIT_FOR_SOF;
                        driver_state_counter <= '0;
                    end
                end

                BLANKING: begin
                    wrtgs_cnt <= '0;
                    data_idx <= '0;
                    driver_state_counter <= driver_state_counter + 1'b1;
                    if(driver_state_counter == BLANKING_TIME - 1) begin
                        driver_state_counter <= '0;
                        driver_state <= PAUSE_SCLK;
                    end
                end

                SHIFT_REGISTER: begin
                    driver_state_counter <= driver_state_counter + 1'b1;
                    data_idx <= data_idx + 1'b1;
                    if(driver_state_counter == 47) begin
                        driver_state_counter <= '0;
                        wrtgs_cnt <= wrtgs_cnt + 1'b1;
                        driver_state <= PAUSE_SCLK;
                        if(wrtgs_cnt == 8) begin
                            wrtgs_cnt <= 0;
                            mux_counter <= mux_counter + 1'b1;
                            driver_state <= BLANKING;
                            if(mux_counter == 7) begin
                                mux_counter <= '0;
                                driver_state <= WAIT_FOR_SOF;
                            end
                        end
                    end
                end

                PAUSE_SCLK: begin
                    driver_state <= SHIFT_REGISTER;
                end

                WAIT_FOR_SOF: begin
                    if(SOF) begin
                        driver_state <= WAIT_END_GCLK_SEGMENT;
                        mux_counter <= '0;
                    end
                end

                WAIT_END_GCLK_SEGMENT: begin
                    if(gclk_cnt == 512) begin
                        driver_state <= BLANKING;
                        if(should_send_config) begin
                            driver_state <= PREPARE_CONFIG;
                        end
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
 * driver_sclk drives the SCLK of the drivers.
 * There is no difference between the configuration mode and the stream mode.
 * The SCLK is on when device is not in reset and not in blanking mode.
 */
always_comb begin
    case(driver_state)
        CONFIG: begin
            driver_sclk = clk_enable;
            /*
             * After the WRTFC command we pause SCLK for one cycle to meet
             * timing requirement
             */
            if(driver_state_counter == 'd0) begin
                driver_sclk = '0;
            end
        end

        DUMP_CONFIG: begin
            driver_sclk = clk_enable;
            /*
             * After the READFC command we pause SCLK for five cycles to meet
             * timing requirement
             */
            if(driver_state_counter < 'd5) begin
                driver_sclk = '0;
            end
        end

        WAIT_FOR_SOF, BLANKING, PAUSE_SCLK, WRTFC_TIMING, WAIT_END_GCLK_SEGMENT: begin
            driver_sclk = '0;
        end

        default: begin
            driver_sclk = clk_enable;
        end
    endcase
end

integer gclk_cnt;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        gclk_cnt <= '0;
    end else if(clk_enable) begin
        gclk_cnt <= gclk_cnt + 1'b1;
        if(gclk_cnt == 512) begin
            gclk_cnt <= '0;
        end
    end

assign driver_gclk = gclk_cnt != 0 && clk_enable;

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
localparam FCWRTEN=15, READFC=11, WRTFC=5, WRTGS=1, LATGS=3, LINERESET=7, NO_LAT=0;

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
           if(driver_state_counter == 47
               || (driver_state_counter >= 45 && wrtgs_cnt == 8)
               ||(driver_state_counter >= 41 && wrtgs_cnt == 8 && mux_counter == 7)) begin
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
            drivers_sin = '0;
            if(driver_state_counter != 0) begin
                for(int i = 0; i < 30; i++) begin
                    drivers_sin[i] = config_data[48-driver_state_counter];
                end
            end
        end
        SHIFT_REGISTER: begin
            for(int i = 0; i < 15; i++) begin
                drivers_sin[2*i]   = data[i][431 - data_idx];
                drivers_sin[2*i+1] = data[i][431 - data_idx];
            end
        end
        default: begin
            drivers_sin = '0;
        end
    endcase
end

assign EOC = driver_state == SHIFT_REGISTER && wrtgs_cnt == 8
            && driver_state_counter == 47 && clk_enable;

always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        mux_out <= '0;
    end else begin
        mux_out <= 8'b1000_0000;
        if(mux_counter > 0) begin
            mux_out <= 1'b1 << (mux_counter - 1);
        end
    end

endmodule
