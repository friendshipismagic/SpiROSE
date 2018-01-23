#include <systemc.h>
#include <verilated.h>
#include <sstream>

#include "monitor.hpp"

void Monitor::runTests() {
    sendReset();

    // Run actual hall sensor tests

    // Small speed variations
    sendHallSignals(64000, 60000);

    // Small speed variations
    sendHallSignals(60000, 64000);

    // No speed variations
    sendHallSignals(32000, 32000);

    // Big speed variations
    sendHallSignals(13457, 500);

    while (true) wait(clk.posedge_event());
}

void Monitor::sendReset() {
    nrst = 0;
    hall1 = 1;
    hall2 = 1;
    positionSyncCounter = 0;
    for (int i = 0; i < 10; ++i) {
        wait(clk.posedge_event());
    }
    nrst = 1;
}

// Check that after a Hall signal, the right number of positionSync were sent
void Monitor::checkPositionSync(int value_hall1_to_hall2, int value_hall2_to_hall1) {
   while (1) {
       wait(clk.posedge_event());
       if (hall1 == 0 || hall2 == 0) {
           /*
            * The hall_sensor module uses the length of a half turn to compute
            * the cycle length of a slice.
            */
           int cyclePerSlice = value_hall1_to_hall2 / 128;
           int expectedPositionSyncCounter = value_hall2_to_hall1 / cyclePerSlice;
           /*
            * The module will wait for a top and send no positionSync after
            * 128 slices
            */
           if(expectedPositionSyncCounter > 127)
               expectedPositionSyncCounter = 0;
           if (positionSyncCounter != expectedPositionSyncCounter) {
               std::ostringstream msg;
               msg << "The number of positionSync received ("
                   << positionSyncCounter
                   << ") is different from the expected result ("
                   << expectedPositionSyncCounter
                   << ")";
               SC_REPORT_ERROR("hall_sensor", msg.str().c_str());
            }
        }
    }
}

// Count the number of positionSync that are sent
void Monitor::storePositionSync() {
    while (1) {
        wait(clk.posedge_event());
        if (positionSync == 1) {
            if (positionSyncCounter == 127) {
                positionSyncCounter = 0;
            } else {
                positionSyncCounter++;
            }
        }
    }
}

/*
 * Generic function to simulate a whole cycle of hall1
 * and hall2 being triggered in succession
 */
void Monitor::sendHallSignals(int value_hall1_to_hall2, int value_hall2_to_hall1) {
    wait(clk.posedge_event());

    // Set hall1 low for one cycle
    hall1 = 0;
    wait(clk.posedge_event());
    hall1 = 1;

    for (int i = 0; i < value_hall1_to_hall2; i++) wait(clk.posedge_event());

    // Set hall2 low for one cycle
    hall2 = 0;
    wait(clk.posedge_event());
    hall2 = 1;

    auto hall_p1 = sc_spawn(sc_bind(&Monitor::storePositionSync, this));
    auto hall_p2 = sc_spawn(sc_bind(&Monitor::checkPositionSync, this,
                value_hall1_to_hall2, value_hall2_to_hall1));
    for (int i = 0; i < value_hall2_to_hall1; i++) wait(clk.posedge_event());

    // Set hall1 low for one cycle
    hall1 = 0;
    wait(clk.posedge_event());
    hall1 = 1;

    hall_p1.kill();
    hall_p2.kill();
}
