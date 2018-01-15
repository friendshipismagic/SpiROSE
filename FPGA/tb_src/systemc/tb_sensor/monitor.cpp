#include <systemc.h>
#include <verilated.h>
#include <sstream>

#include "monitor.hpp"

void Monitor::runTests() {
    sendReset();

    while (true) wait();
}

void Monitor::sendReset() {
    nrst = 0;
    for (int i = 0; i < 10; ++i) {
        wait(clk.posedge_event());
    }
    nrst = 1;
}
