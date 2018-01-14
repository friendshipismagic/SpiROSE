#include <systemc.h>
#include <verilated.h>
#include <sstream>

#include "monitor.hpp"

constexpr int SPI_CYCLES = 8;

namespace {
template <int Size>
void checkValueEq(sc_bv<Size> left, sc_bv<Size> right) {
    if (left == right) {
        SC_REPORT_INFO("spi", "left and right are identical");
        return;
    }
    std::ostringstream s;
    s << "the value is different from expected, received " << left
      << ", expected " << right;
    SC_REPORT_ERROR("spi", s.str().c_str());
}
}  // namespace

void Monitor::runTests() {
    sendReset();

    // wait some cycles before sending anything
    for (int i = 0; i < 200; ++i) wait(clk.posedge_event());

    unsigned char capturedValue = 0;

    ss = 0;
    wait(clk.posedge_event());

    /*
     * Note: in case of unknown command, it is undefined behaviour
     * so we only test known commands
     */

    sc_spawn(&capturedValue, sc_bind(&Monitor::captureValue, this));
    sendCommand(0xBF);

    for (int i = 0; i < 7; ++i) {
        sendCommand(0xA1 + i);
    }

    checkValueEq<48>(configOut.read(), 0xA6A5A4A3A2A1);

    // Get rotation data
    rotationData = 0xBEEF;
    sendCommand(0xA0);
    sendCommand(0x4C);

    unsigned char bytes[2];
    for (int i = 0; i < 2; ++i) {
        sc_spawn(&bytes[i], sc_bind(&Monitor::captureValue, this));
        sendCommand(0xA0);
    }

    if (bytes[1] != 0xBE && bytes[0] != 0xEF) {
        std::string msg;
        msg += "Error during the process of get_rotation command, expected ";
        msg += "0xBEEF, got 0xXXXX";
        sprintf(&msg[msg.size() - 4], "%x%x", bytes[1], bytes[0]);

        SC_REPORT_ERROR("spi", msg.c_str());
    }

    sc_spawn(&capturedValue, sc_bind(&Monitor::captureValue, this));
    sendCommand(0x4C);
    while (true) wait();
}

void Monitor::sendReset() {
    nrst = 0;
    for (int i = 0; i < 10; ++i) {
        wait(clk.posedge_event());
    }
    nrst = 1;
}

void Monitor::sendCommand(char value) {
    // Sample data at the rising edge, so we change data at the falling edge
    sc_assert(clk == 1);
    for (int i = 0; i < 2 * SPI_CYCLES; ++i) {
        sck = clk;
        mosi = (value >> (SPI_CYCLES - i / 2 - 1)) & 1;
        wait(clk.value_changed_event());
    }
    mosi = 0;
    sck = 0;
}

unsigned char Monitor::captureValue() {
    unsigned char value = 0;
    for (int i = 0; i < SPI_CYCLES; ++i) {
        wait(clk.posedge_event());
        value = (value << 1) | miso.read();
    }
    return value;
}
