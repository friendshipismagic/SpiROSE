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
    sendCommand(0xA0);

    // config is sent LSB order
    checkValueEq<48>(configOut.read(), 0xA6A5A4A3A2A1);

    rotationData = 0xB000;
    for (int step = 0; step < 50; ++step) {
        // Send blank command to add delay, nothing useful happens
        sendCommand(0xA0);

        // Send "get rotation data" command
        sendCommand(0x4C);

        unsigned char bytes[2];
        for (int byteNb = 0; byteNb < 2; ++byteNb) {
            // Record each bytes of the returned value
            sc_spawn(&bytes[byteNb], sc_bind(&Monitor::captureValue, this));
            sendCommand(0xA0);
        }

        // expected values
        unsigned char values[] = {
            static_cast<unsigned char>(rotationData.read() & 0x00FF),
            static_cast<unsigned char>((rotationData.read() & 0xFF00) >> 8),
        };

        if (bytes[1] != values[1] && bytes[0] != values[0]) {
            std::stringstream msg;
            msg << "Error during the process of get_rotation command, "
                   "expected ";
            msg << "0x" << std::hex << (int)values[1] << (int)values[0];
            msg << ", got 0x";
            msg << std::hex << (int)bytes[1] << (int)bytes[0];

            SC_REPORT_ERROR("spi", msg.str().c_str());
        }
        rotationData = rotationData.read() + 1;
        wait(clk.posedge_event());
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
