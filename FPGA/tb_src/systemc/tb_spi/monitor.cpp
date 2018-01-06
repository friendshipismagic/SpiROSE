#include <systemc.h>
#include <verilated.h>
#include <sstream>

#include "monitor.hpp"

void Monitor::runTests() {
    sendReset();

    // wait some cycles before sending anything
    for (int i = 0; i < 200; ++i) wait(clk.posedge_event());

    sc_spawn(sc_bind(&Monitor::checkValue, this, 8, 1));
    generateSck(8);

    ss = true;
    mosi = true;

    sc_spawn(sc_bind(&Monitor::checkValue, this, 8, 1));
    generateSck(8);

    ss = false;
    mosi = true;

    sc_spawn(sc_bind(&Monitor::checkValue, this, 8, 1));
    generateSck(8);

    ss = false;
    mosi = true;

    sc_spawn(sc_bind(&Monitor::checkValue, this, 8, 1));
    generateSck(8);

    while (true) wait();
}

void Monitor::sendReset() {
    nrst = 0;
    for (int i = 0; i < 10; ++i) {
        wait(clk.posedge_event());
    }
    nrst = 1;
}

void Monitor::generateSck(int count) {
    for (int i = 0; i < 2 * count; ++i) {
        sck = clk;
        wait(clk.value_changed_event());
    }
    sck = 0;
}

void Monitor::checkValue(int count, bool value) {
    for (int i = 0; i < count; ++i) {
        wait(clk.posedge_event());
        std::ostringstream s;
        s << "the value is different from expected, received " << miso.read()
          << ", expected " << value;
        if (miso != value) {
            SC_REPORT_ERROR("spi", s.str().c_str());
            return;
        }
    }
}
