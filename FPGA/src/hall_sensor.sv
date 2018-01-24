module hall_sensor (
    input clk,
    input nrst,

    input hall_1,
    input hall_2,

    /*
     * Slice that is meant to be displayed (over a full 256-slice turn).
     * It is the slice counted after the Hall effect sensor 1 (arbitrarily)
     * is triggered.
     */
    output logic [7:0] slice_cnt,
    output logic position_sync,
    output logic [15:0] speed_data
);

localparam SLICE_PER_HALF_TURN = 128;
localparam HALF_TURN_COUNTER_WIDTH = 32;
localparam SLICE_PER_HALF_TURN_WIDTH = $clog2(SLICE_PER_HALF_TURN);
localparam INTERNAL_COUNTER_WIDTH = HALF_TURN_COUNTER_WIDTH - SLICE_PER_HALF_TURN_WIDTH;
localparam CLOCK_FREQUENCY = 66000000;

// Counter for slices over a half turn only
logic [SLICE_PER_HALF_TURN_WIDTH:0] slice_half_cnt;

// State for which half-turn we are in. HALFTURN1 after hall_1 trigger.
enum logic {HALFTURN1, HALFTURN2} half_turn_state;

// Counter for each half-turn
logic [HALF_TURN_COUNTER_WIDTH - 1:0] counter;

/*
 * Cycle counter for each slice (bit width is SLICE_PER_HALF_TURN times smaller
 * than that of counter)
 */
logic [INTERNAL_COUNTER_WIDTH - 1:0] slice_cycle_counter;

// 1-cycle high top signal, when the Hall effect sensor is first triggered
logic top;

/*
 * Number of cycles between two slices, calculated with
 * the last half-turn data
 */
logic [INTERNAL_COUNTER_WIDTH - 1:0] cycles_between_two_slices;

// Process handling the generation of position_sync
always_ff @(posedge clk or negedge nrst) begin
    if (~nrst) begin
        position_sync <= 0;
        slice_cycle_counter <= 0;
        slice_half_cnt <= 0;
    end else begin
        position_sync <= 0;
        if (top) begin
            // Resynchronization for each top
            slice_cycle_counter <= 0;
            slice_half_cnt <= 0;
            /*
             * A top corresponds to the first slice, so we need
             * a position_sync being high
             */
            position_sync <= 1;
        end else begin
            slice_cycle_counter <= slice_cycle_counter + 1;
            if (slice_cycle_counter == cycles_between_two_slices - 1
                    && slice_half_cnt < SLICE_PER_HALF_TURN) begin
                slice_cycle_counter <= 0;
                slice_half_cnt <= slice_half_cnt + 1;
                position_sync <= 1;
            end
        end
    end
end


/*
 * Process handling the top signals, and extracting the number of cycles that
 * are needed for each slice
 */
always_ff @(posedge clk or negedge nrst) begin
    if (~nrst) begin
        counter <= 0;
        speed_data <= 0;
    end else begin
        if (top) begin
            /*
             * Store the number of cycles it took to reach this top
             * In other words, cycles_between_two_slices is the number of cycles
             * between the previous top and this top, aka half a turn
             */
            cycles_between_two_slices <= INTERNAL_COUNTER_WIDTH'(counter >> SLICE_PER_HALF_TURN_WIDTH);
            counter <= 1;
            // Compute the immediate speed value
            speed_data <= 16'((CLOCK_FREQUENCY/(counter+1))/2);
        end else begin
            counter <= counter + 1;
        end
    end
end


// Guard, equals to 1 until both Hall sensors are high
logic guard;

// Process handling the "top" signal generation, given the Hall sensor data
always_ff @(posedge clk or negedge nrst) begin
    if (~nrst) begin
        top <= 0;
        guard <= 0;
        half_turn_state <= HALFTURN1;
    end else begin
        top <= 0;
        /*
         * Whenever one sensor is triggered and not guarded,
         * top is set high for one cycle
         */
        if ((~hall_1 | ~hall_2) && guard == 0) begin
            top <= 1;
            guard <= 1;
            if (~hall_1) begin
                half_turn_state <= HALFTURN1;
            end else if (~hall_2) begin
                half_turn_state <= HALFTURN2;
            end
        end
        /*
         * When both sensors are not triggered, remove the guard, for the next
         * sensor to be able to trigger the "top" signal
         */
        if (hall_1 & hall_2) begin
            guard <= 0;
        end
    end
end

// Generate the slice counter over 256 slices (a full turn)
always_comb
    if (half_turn_state == HALFTURN1) begin
        slice_cnt = 8'(slice_half_cnt);
    end else begin
        slice_cnt = SLICE_PER_HALF_TURN + slice_half_cnt;
    end

endmodule
