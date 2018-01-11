#include <systemc.h>
#include <verilated.h>

#include "monitor.hpp"

void Monitor::runTests() {
    rgbEnable = false;
    sendReset();

    // wait some cycles before sending anything
    for (int i = 0; i < 200; ++i) {
        wait(clk.posedge_event());
    }

    // Start sending 8 frames without rgbEnable
    sendFrame();
    checkRAM(false);
    cleanRAM();

    rgbEnable = true;
    // Start sending frames with rgbEnable
    sendFrame();
    checkRAM(true);
    cleanRAM();
}

void Monitor::sendReset() {
    nrst = 0;
    for (int i = 0; i < 10; ++i) {
        wait();
    }
    nrst = 1;
}

void Monitor::captureRAM() {
    while (true) {
        if (writeEnable) {
            ram.resize(std::max(ram.size(), (size_t)ramAddr.read()));
            ram[ramAddr] = ramData;
        }
        wait();
    }
}

void Monitor::checkRgbEnable() {
    while (true) {
        if (writeEnable && !rgbEnable) {
            std::string msg;
            msg += "rgb_logic module tried to write the ram ";
            msg += "although it was disabled (rgb_enable = 0)";
            SC_REPORT_ERROR("rgb", msg.c_str());
            return;
        }
        wait();
    }
}

void Monitor::sendFrame() {
    hsync = true;
    vsync = true;
    // Start sending 8 frames without rgbEnable
    for (int k = 0; k < 8; ++k) {
        for (int y = 0; y < FRAME_HEIGHT; ++y) {
            for (int x = 0; x < FRAME_WIDTH; ++x) {
                rgb = y * FRAME_WIDTH + x;
                wait(clk.posedge_event());
            }
            hsync = false;
            wait(clk.posedge_event());
            hsync = true;
        }
    }
    vsync = false;
    for (int x = 0; x < FRAME_WIDTH; ++x) {
        wait(clk.posedge_event());
    }
    hsync = false;
    wait(clk.posedge_event());
}

void Monitor::checkRAM(bool zeroed) {
    auto f = [this, zeroed](int k, int x, int y) {
        if (zeroed) return 0;
        return value(k, x, y);
    };

    for (int k = 0; k < 8; ++k) {
        for (int y = 0; y < FRAME_HEIGHT; ++y) {
            for (int x = 0; x < FRAME_WIDTH; ++x) {
                std::string msg;
                msg += "Incorrect RAM value at ";
                msg += std::to_string(value(k, x, y));
                msg += ", expected ";
                msg += std::to_string(f(k, x, y));
                msg += " and got ";
                msg += ram[value(k, x, y)];
                if (ram[value(k, x, y)] != f(k, x, y)) {
                    SC_REPORT_ERROR("rgb_logic", msg.c_str());
                }
            }
        }
    }
}

void Monitor::cleanRAM() {
    for (auto& x : ram) x = 0;
}

int Monitor::value(int k, int x, int y) {
    return y * FRAME_WIDTH + x + k * FRAME_WIDTH * FRAME_HEIGHT;
}
