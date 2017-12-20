#include <systemc.h>
#include <verilated.h>

#include "monitor.hpp"

void Monitor::runTests() {
    sendReset();

    // wait some cycles before sending anything
    wait(200);

    while (true) wait();
}

void Monitor::sendReset() {
    nrst = 0;
    for (int i = 0; i < 10; ++i) {
        wait(clk.posedge());
    }
    nrst = 1;
}
