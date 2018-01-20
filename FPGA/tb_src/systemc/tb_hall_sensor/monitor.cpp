#include <systemc.h>
#include <verilated.h>
#include <sstream>

#include "monitor.hpp"

void Monitor::runTests() {
    sendReset();

    // Run actual hall sensor tests
    sendHallSignals(64000);

    sendHallSignals(64000);

    sendHallSignals(32000);

    sendHallSignals(13457);

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
void Monitor::checkPositionSync() {
   while (1) {
       wait(clk.posedge_event());
       if (hall1 == 0 || hall2 == 0) {
           if (positionSyncCounter != 0) {
               std::ostringstream msg;
               msg << "The number of positionSync received ("
                   << positionSyncCounter + 1
                   << ") is different from the expected result (0)";
               SC_REPORT_ERROR("hall_sensor", msg.str().c_str());
            }
        }
    }
}

// Count the number of positionSyncthat are sent
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
void Monitor::sendHallSignals(int value) {
    wait(clk.posedge_event());

    // Set hall1 low for one cycle
    hall1 = 0;
    wait(clk.posedge_event());
    hall1 = 1;

    for (int i = 0; i < value; i++) wait(clk.posedge_event());
    auto hall_p1 = sc_spawn(sc_bind(&Monitor::storePositionSync, this));

    // Set hall2 low for one cycle
    hall2 = 0;
    wait(clk.posedge_event());
    hall2 = 1;

    auto hall_p2 = sc_spawn(sc_bind(&Monitor::checkPositionSync, this));
    for (int i = 0; i < value; i++) wait(clk.posedge_event());

    // Set hall1 low for one cycle
    wait(clk.posedge_event());
    hall_p1.kill();
    hall_p2.kill();
}
