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

    enableSck = false;

    // wait some cycles before sending anything
    for (int i = 0; i < 200; ++i) wait(clk.posedge_event());

    unsigned char capturedValue = 0;

    /*
     * Note: in case of unknown command, it is undefined behaviour
     * so we only test known commands
     */

    sc_spawn(&capturedValue, sc_bind(&Monitor::captureValue, this));
    sendCommand(0xBF);
    for (int i = 0; i < 50; ++i) wait(clk.posedge_event());

    for (int i = 0; i < 6; ++i) {
        sendCommand(0xA1 + i);
        for (int i = 0; i < 50; ++i) wait(clk.posedge_event());
    }

    // config is sent MSB order
    checkValueEq<48>(configOut.read(), 0xA1A2A3A4A5A6);

    for (int i = 0; i < 50; ++i) wait(clk.posedge_event());

    rotationData = 0xB000;
    for (int step = 0; step < 50; ++step) {
        for (int i = 0; i < 50; ++i) wait(clk.posedge_event());

        // Send "get rotation data" command
        sendCommand(0x4C);
        for (int i = 0; i < 50; ++i) wait(clk.posedge_event());

        unsigned char bytes[2];
        for (int byteNb = 0; byteNb < 2; ++byteNb) {
            // Record each bytes of the returned value
            sc_spawn(&bytes[byteNb], sc_bind(&Monitor::captureValue, this));
            sendCommand(0xA0);
            for (int i = 0; i < 50; ++i) wait(clk.posedge_event());
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

    for (int i = 0; i < 50; ++i) wait(clk.posedge_event());

    const auto msgE0 =
        "0xE0 command should have turned the rgb_enable signal on, but the "
        "signal state is off";
    const auto msgD0 =
        "0xD0 command should have turned the rgb_enable signal off, but the "
        "signal state is on";

    for (int i = 0; i < 10; ++i) {
        sendCommand(0xE0);
        sendCommand(0xff);
        if (!rgbEnable) SC_REPORT_ERROR("rgb", msgE0);

        sendCommand(0xD0);
        sendCommand(0xff);
        if (rgbEnable) SC_REPORT_ERROR("rgb", msgD0);
    }

    for (int i = 0; i < 50; ++i) wait(clk.posedge_event());


    // test that configure is not interpreted as as command in configure mode
    for (int i = 0; i < 7; ++i) {
        sendCommand(0xBF);
        for (int j = 0; j < 50; ++j) wait(clk.posedge_event());
    }

    if (configOut != 0xBFBFBFBFBFBF)
        SC_REPORT_ERROR("spi",
                        "module continue to parse configure command in the "
                        "configure state");

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
    enableSck.write(1);
    // If it is the first command we send we wait for sck
    if(enableSck.read() == 0)
        wait(clk.negedge_event());
    for (int i = 0; i < SPI_CYCLES; ++i) {
        mosi = (value >> (SPI_CYCLES - i - 1)) & 1;
        wait(clk.negedge_event());
    }
    mosi = 0;
    enableSck.write(0);
}

void Monitor::handleSck() {
    sc_event_or_list evt;
    while (1) {
        wait(clk.value_changed_event());
        sck = enableSck ? clk : 0;
    }
}

void Monitor::handleSs() {
    ss = 1;
    while (true) {
        ss = !enableSck;
        wait(enableSck.value_changed_event());
        ss = !enableSck;
        wait(enableSck.value_changed_event());
        wait(clk.negedge_event());
        ss = !enableSck;
    }
}

unsigned char Monitor::captureValue() {
    unsigned char value = 0;
    for (int i = 0; i < SPI_CYCLES; ++i) {
        wait(clk.posedge_event());
        value = (value << 1) | miso.read();
    }
    return value;
}
