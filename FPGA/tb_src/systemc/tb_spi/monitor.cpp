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

    int capturedValue = 0;

    sc_spawn(&capturedValue, sc_bind(&Monitor::captureValue, this));
    sendCommand(0b00000000);

    checkValueEq<8>(capturedValue, "11111111");

    ss = true;

    sc_spawn(&capturedValue, sc_bind(&Monitor::captureValue, this));
    sendCommand(0b11111111);

    checkValueEq<8>(capturedValue, "11111111");

    ss = false;

    sc_spawn(&capturedValue, sc_bind(&Monitor::captureValue, this));
    sendCommand(0b11111111);

    checkValueEq<8>(capturedValue, "11111111");

    ss = false;

    sc_spawn(&capturedValue, sc_bind(&Monitor::captureValue, this));
    sendCommand(0b11111111);

    checkValueEq<8>(capturedValue, "11111111");

    sc_spawn(&capturedValue, sc_bind(&Monitor::captureValue, this));
    sendCommand(0xBF);

    for (int i = 0; i < 7; ++i) {
        sendCommand(0xA0);
    }

    checkValueEq<48>(configOut.read(), 0xA0A0A0A0A0A0);

    sc_spawn(&capturedValue, sc_bind(&Monitor::captureValue, this));
    sendCommand(0x4C);

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
    sck = 0;
}

int Monitor::captureValue() {
    int value = 0;
    for (int i = 0; i < SPI_CYCLES; ++i) {
        wait(clk.posedge_event());
        value = (value << 1) | miso.read();
    }
    return value;
}
