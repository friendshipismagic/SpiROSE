#include <systemc.h>
#include <verilated.h>

#include "monitor.hpp"

void Monitor::runTests() {
    sendReset();

    rgbEnable = true;

    // wait some cycles before sending anything
    for (int i = 0; i < 200; ++i) {
        wait(clk.negedge_event());
    }

    rgbEnable = false;

    SC_REPORT_INFO("rgb_logic", "try to send frames with rgb_enable=0");
    // Start sending 8 frames without rgbEnable
    // the module should write nothing
    auto p1 = sc_spawn(sc_bind(&Monitor::checkRAM, this));
    sendFrame(NUMBER_OF_FRAME, FRAME_WIDTH, FRAME_HEIGHT);
    p1.kill();

    SC_REPORT_INFO("rgb_logic", "try to send frames with rgb_enable=1");
    rgbEnable = true;
    // Start sending frames with rgbEnable
    // Now it should work
    auto p2 = sc_spawn(sc_bind(&Monitor::checkRAM, this));
    sendFrame(NUMBER_OF_FRAME, FRAME_WIDTH, FRAME_HEIGHT);
    p2.kill();

    rgbEnable = false;

    sendReset();

    // Test to send incomplete image, it shouldn't go further than an image
    auto p = sc_spawn([this]() {
        while (true) {
            wait(ramAddr.value_changed_event());

            if (ramAddr.read() < FRAME_WIDTH * FRAME_HEIGHT) {
                continue;
            }

            SC_REPORT_ERROR(
                "rgb_logic",
                "ram_addr is not reset when an incomplete image is received");
            return;
        }
    });

    SC_REPORT_INFO("rgb_logic", "Trying to send incomplete frames");
    rgbEnable = true;
    sendFrame(NUMBER_OF_FRAME, FRAME_WIDTH, FRAME_HEIGHT / 2);
    p.kill();

    rgbEnable = false;

    while (true) wait(clk.posedge_event());
}

void Monitor::sendReset() {
    nrst = 0;
    for (int i = 0; i < 10; ++i) {
        wait(clk.posedge_event());
    }
    nrst = 1;
}

/*
 * Test whether the address protocol for frames was respected
 */
void Monitor::captureRAM() {
    lastAddr = 0;
    lastVsync = vsync.read();
    while (true) {
        if (writeEnable) {
            if (ramAddr == 0) {
                bool error = false;
                // lastAddr is the address right before the 0
                error |= (lastAddr + 1) % (FRAME_WIDTH * FRAME_HEIGHT) != 0;
                error &= lastAddr >= FRAME_WIDTH * FRAME_HEIGHT - 1;
                error &= lastVsync;
                std::string msg;
                msg += "Captured frame was incomplete, with lastAddr=";
                msg += std::to_string(lastAddr.read());
                msg += " and ramAddr=0";
                if (error) {
                    SC_REPORT_ERROR("rgb_logic", msg.c_str());

                    return;
                }
            } else {
                if (ramAddr - lastAddr != 1) {
                    SC_REPORT_ERROR("rgb_logic",
                                    "Addresses are not consecutives");
                    return;
                }
            }
            lastAddr = ramAddr;
            lastVsync = vsync;
        }
        wait();
    }
}

/*
 * Test whether we are trying to write something in the RAM although
 * the module was disabled.
 */
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

/*
 * Send a frame on the RGB port. Frame pixels are just the address itself.
 * It is sampled on the rising edge of clk with correct handling for hsync
 * and vsync signals
 */
void Monitor::sendFrame(int nb_frame, int width, int height) {
    hsync = false;
    vsync = false;
    wait(clk.negedge_event());
    hsync = true;
    vsync = true;
    // Start sending 8 frames without rgbEnable
    for (int k = 0; k < nb_frame; ++k) {
        for (int y = 0; y < height; ++y) {
            for (int x = 0; x < width; ++x) {
                rgb = value(k, x, y);
                wait(clk.negedge_event());
            }
            hsync = false;
            wait(clk.negedge_event());
            hsync = true;
        }
        vsync = false;
        for (int x = 0; x < FRAME_WIDTH; ++x) {
            wait(clk.negedge_event());
        }
        hsync = false;
        wait(clk.negedge_event());
    }
}

/*
 * Check addresses and data from the RGB logic module during the
 * same period of time as sendFrame.
 * It sends NUMBER_OF_FRAME frames and handle writeEnable.
 * Data is sampled during the falling edges.
 */
void Monitor::checkRAM() {
    // synchronize with the frame generator
    wait(clk.negedge_event());

    uint32_t previousRamAddr = 0;
    uint32_t nextRamAddr = 0;
    for (int k = 0; k < NUMBER_OF_FRAME; ++k) {
        for (int y = 0; y < FRAME_HEIGHT; ++y) {
            for (int x = 0; x < FRAME_WIDTH; ++x) {
                // It has to wait for at least one cycle,
                do {
                    wait(clk.posedge_event());
                } while (!writeEnable);

                bool hasCycled =
                    ramAddr == 0 && previousRamAddr != 0 &&
                    (previousRamAddr + 1) % (FRAME_WIDTH * FRAME_HEIGHT) == 0;

                // Check for errors
                bool isInvalidData = ramData != v565(value(k, x, y));
                bool isInvalidCycle =
                    ramAddr == 0 && !hasCycled && previousRamAddr != 0;
                bool isInvalidAddr = !(hasCycled || ramAddr == nextRamAddr);

                std::string msg;
                msg += "Incorrect RAM addr, value or error at address ";
                msg += std::to_string(ramAddr.read());
                msg += " (expected ";
                msg += std::to_string(nextRamAddr);
                msg += ") , expected value ";
                msg += std::to_string(v565(value(k, x, y)));
                msg += " and got ";
                msg += std::to_string(ramData);
                msg += "; previous addr was " + std::to_string(previousRamAddr);
                if (hasCycled) msg += " and memory addr was reset";
                msg += "; Error code: ";
                msg += std::to_string(isInvalidData);
                msg += std::to_string(isInvalidCycle);
                msg += std::to_string(isInvalidAddr);

                bool isError = false;
                // Error if ramData doesn't contain the correct 565 value
                isError |= isInvalidData;
                // Error if ramData has cycled inside an image
                isError |= isInvalidCycle;
                // Error if ramData is not following the memory pattern
                isError |= isInvalidAddr;

                nextRamAddr++;
                if (hasCycled) nextRamAddr = 1;

                previousRamAddr = ramAddr;

                // It can't be an error if it wasn't written, rollback
                isError &= writeEnable;
                if (isError) {
                    cout << "x " << x << " / y " << y << " / k " << k << endl;
                    SC_REPORT_ERROR("rgb_logic", msg.c_str());
                    return;
                }
            }
        }
    }
}

/*
 * Generate a value from the frame index, the x position and the y position
 */
uint32_t Monitor::value(uint32_t k, uint32_t x, uint32_t y) {
    return y * FRAME_WIDTH + x + k * FRAME_WIDTH * FRAME_HEIGHT;
}

/*
 * Extract the 5-6-5 value from v
 */
uint32_t Monitor::v565(uint32_t v) {
    auto sc_v = sc_bv<24>(v);
    return (sc_v(23, 19).to_uint() << 11) | (sc_v(15, 10).to_uint() << 5) |
           sc_v(7, 3).to_uint();
}
