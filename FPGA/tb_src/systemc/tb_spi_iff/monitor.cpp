//
// Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément Decoodt,
// Alexandre Janniaux, Adrien Marcenat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#include <systemc.h>
#include <verilated.h>
#include <sstream>

#include "monitor.hpp"
#define WAIT_POSEDGE(n) for (int i = 0; i < 200; ++i) wait(clk.posedge_event())

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
    unsigned char capturedValue = 0;
    // wait some cycles before sending anything
    WAIT_POSEDGE(200);

    /*
     * Note: in case of unknown command, it is undefined behaviour
     * so we only test known commands
     */

    sc_spawn(&capturedValue, sc_bind(&Monitor::captureValue, this));
    sendCommand(0xBF);
    for (int i = 0; i < 6; ++i) {
        sendCommand(0xA1 + i);
    }

    WAIT_POSEDGE(50);

    // config is sent MSB order
    checkValueEq<48>(configuration.read(), 0xA1A2A3A4A5A6);

    WAIT_POSEDGE(50);

    rotationData = 0xB000;
    for (int step = 0; step < 50; ++step) {
        WAIT_POSEDGE(50);
        // Send "get rotation data" command
        sendCommand(0x4C);
        WAIT_POSEDGE(50);

        unsigned char bytes[2];
        for (int byteNb = 0; byteNb < 2; ++byteNb) {
            // Record each bytes of the returned value
            sc_spawn(&bytes[byteNb], sc_bind(&Monitor::captureValue, this));
            sendCommand(0xA0);
            WAIT_POSEDGE(50);
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

    WAIT_POSEDGE(50);

    speedData = 0xDEAD;
    for (int step = 0; step < 50; ++step) {
        WAIT_POSEDGE(50);
        // Send "get speed data" command
        sendCommand(0x4D);
        WAIT_POSEDGE(50);

        unsigned char bytes[2];
        for (int byteNb = 0; byteNb < 2; ++byteNb) {
            // Record each bytes of the returned value
            sc_spawn(&bytes[byteNb], sc_bind(&Monitor::captureValue, this));
            sendCommand(0xA0);
            WAIT_POSEDGE(50);
        }

        // expected values
        unsigned char values[] = {
            static_cast<unsigned char>(speedData.read() & 0x00FF),
            static_cast<unsigned char>((speedData.read() & 0xFF00) >> 8),
        };

        if (bytes[1] != values[1] && bytes[0] != values[0]) {
            std::stringstream msg;
            msg << "Error during the process of get_speed command, "
                   "expected ";
            msg << "0x" << std::hex << (int)values[1] << (int)values[0];
            msg << ", got 0x";
            msg << std::hex << (int)bytes[1] << (int)bytes[0];

            SC_REPORT_ERROR("spi", msg.str().c_str());
        }
        speedData = speedData.read() + 1;
        wait(clk.posedge_event());
    }

    WAIT_POSEDGE(50);

    debugData = 0xDEADBEEF;
    for (int step = 0; step < 50; ++step) {
        WAIT_POSEDGE(50);
        // Send "get debug data" command
        sendCommand(0x4D);
        WAIT_POSEDGE(50);

        unsigned char bytes[2];
        for (int byteNb = 0; byteNb < 2; ++byteNb) {
            // Record each bytes of the returned value
            sc_spawn(&bytes[byteNb], sc_bind(&Monitor::captureValue, this));
            sendCommand(0xA0);
            WAIT_POSEDGE(50);
        }

        // expected values
        unsigned char values[] = {
            static_cast<unsigned char>(debugData.read() & 0x00FF),
            static_cast<unsigned char>((speedData.read() & 0xFF00) >> 8),
        };

        if (bytes[1] != values[1] && bytes[0] != values[0]) {
            std::stringstream msg;
            msg << "Error during the process of get_debug command, "
                   "expected ";
            msg << "0x" << std::hex << (int)values[1] << (int)values[0];
            msg << ", got 0x";
            msg << std::hex << (int)bytes[1] << (int)bytes[0];

            SC_REPORT_ERROR("spi", msg.str().c_str());
        }
        debugData = debugData.read() + 1;
        wait(clk.posedge_event());
    }

    WAIT_POSEDGE(50);

    const auto msgE0 =
        "0xE0 command should have turned the rgb_enable signal on, but the "
        "signal state is off";
    const auto msgD0 =
        "0xD0 command should have turned the rgb_enable signal off, but the "
        "signal state is on";

    for (int i = 0; i < 10; ++i) {
        sendCommand(0xE0);
        WAIT_POSEDGE(50);
        if (!rgbEnable) SC_REPORT_ERROR("rgb", msgE0);

        sendCommand(0xD0);
        WAIT_POSEDGE(50);
        if (rgbEnable) SC_REPORT_ERROR("rgb", msgD0);
    }

    while (true) wait();
}

void Monitor::sendReset() {
    nrst = 0;
    WAIT_POSEDGE(10);
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
