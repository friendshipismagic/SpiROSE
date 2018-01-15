module hall_sensor (
    input clk,
    input nrst,
    
    input hall_1,
    input hall_2,

    output logic [7:0] slice_cnt,
    output logic position_sync
);

// Counter for each half-turn
logic [31:0] counter;

/* 
 * Cycle counter for each slice (bit width is 128 times smaller 
 * than that of counter)
 */
logic [23:0] slice_cycle_counter;

// 1-cycle high top signal, when the Hall effect sensor is first triggered
logic top;

/*
 * Number of cycles between two slices, calculated with 
 * the last half-turn data
 */
logic [31:0] slice_cycle_number;

// Process handling the generation of position_sync
always_ff @(posedge clk or negedge nrst) begin
    if (~nrst) begin
        position_sync <= 0;
        slice_cycle_counter <= 0;
        slice_cnt <= 0;
    end else begin
        if (32'(slice_cycle_counter) == slice_cycle_number - 1) begin
            slice_cycle_counter <= 0;
            slice_cnt <= slice_cnt + 1;
            position_sync <= 1;
        end else begin
            slice_cycle_counter <= slice_cycle_counter + 1;
            position_sync <= 0;
        end
    end
end


/* 
 * Process handling the top signals, and extracting the number of cycles that
 * are needed for each slide
 */
always_ff @(posedge clk or negedge nrst) begin
    if (~nrst) begin
        counter <= 0;
    end else begin
        if (top) begin
            /*
             * Store the number of cycles it took to reach this top
             * In other words, slice_cycle_number is the number of cycles
             * between the previous top and this top, aka half a turn
             */
            slice_cycle_number <= (counter >> 7);
            counter <= 1;
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
    end else begin
        /*
         * Whenever one sensor is triggered and not guarded, 
         * top is set high for one cycle
         */
        if ((~hall_1 | ~hall_2) && guard == 0) begin
            top <= 1;
            guard <= 1;
        end
        if (top == 1) begin
            top <= 0;
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

endmodule
