#include <systemc.h>
#include <verilated.h>
#include <array>

#include "driver_LUT.hpp"
#include "monitor.hpp"

#define BIT(x, n) ((x >> n) & 0x1)
/*
 * As parameter are unsupported this cvalue has to be harcoded to match the
 * one in framebuffer.sv.
 */
#define SLICES_IN_RAM 18

static uint8_t fbOutput[30][9*48];
static uint8_t fbOutputReference[30][9*48];
// Array with the base ram addresses for each driver
static const std::array<unsigned int, 30> ramBaseDriverAddress{
    0,         0,         8,          8,        16,        16,
    24,        24,        32,        32,        640,       640,
    640 + 8,   640 + 8,   640 + 16,  640 + 16,  640 + 24,  640 + 24,
    640 + 32,  640 + 32,  1280,      1280,      1280 + 8,  1280 + 8,
    1280 + 16, 1280 + 16, 1280 + 24, 1280 + 24, 1280 + 32, 1280 + 32
};

void Monitor::reset() {
    nrst = 0;
    // Reset the value of the output test array
    int i, j, k;
    for (i = 0; i < 30; i++) {
        for (j = 0; j < 9; j++) {
            for (k = 0; k < 48; k++) {
                fbOutput[i][48*j+k] = 0;
                fbOutputReference[i][48*j+k] = 0;
            }
        }
    }
    wait();
    nrst = 1;
}

int Monitor::isWRTGSBlankingCycle(int cycle) {
    if (cycle == 72 + 48 || cycle == 72 + 97 || cycle == 72 + 146 ||
        cycle == 72 + 195 || cycle == 72 + 244 || cycle == 72 + 293 ||
        cycle == 72 + 342 || cycle == 72 + 391) {
        return 1;
    }
    return 0;
}

void Monitor::frameCheck(int frameNumber, int waitForNextSliceCycles) {
    ramBaseAddress = 0;
    auto cycleSync_p = sc_spawn(sc_bind(&Monitor::cycleSync, this));
    for(int f = 0; f < frameNumber; f++) {
        // Signals that a new slice has begun
        position_sync = 1;
        wait();
        position_sync = 0;
        // Send data for a whole slice
        for (int i = 0; i < 4096 - 1; i++) {
            wait();
        }
        // Wait for the next slice
        for (int i = 0; i < waitForNextSliceCycles - 1; i++) {
            wait();
        }
        // Read the next slice in ram
        ramBaseAddress += 1920;
        // reset the base ram address as we have read all slices
        if(f == SLICES_IN_RAM)
            ramBaseAddress = 0;
    }
    cycleSync_p.kill();
}

void Monitor::runTests() {
    reset();

    stream_ready = 1;

    auto blanking_p = sc_spawn(sc_bind(&Monitor::checkWRTGSBlanking, this));
    frameCheck(20, 207);

    while (1) {
        wait();
    }
}

void Monitor::cycleSync() {
    cycleCounter = 0;
    bool endOfSlice = true;
    while (1) {
        wait(clk33.posedge_event());
        if(endOfSlice) {
            endOfSlice = position_sync.read() == 0;
        } else {
            if (cycleCounter == 511) {
                cycleCounter = 0;
                currentMultiplexing++;
                if(currentMultiplexing == 8) {
                    endOfSlice = true;
                    currentMultiplexing = 0;
                }
            } else {
                cycleCounter = cycleCounter.read() + 1;
            }
        }
    }
}


void Monitor::storeOutputData() {
    int write_idx = 0;
    while (1) {
        /*
         * Generate driver_ready, it should be sent one cycle before the real
         * blanking cycle, otherwise framebuffer will be late, hence the
         * cycleCounter + 2.
         */
        if (cycleCounter >= 71 && cycleCounter < 511
            && !isWRTGSBlankingCycle(cycleCounter+1)) {
                driver_ready = 1;
        } else {
            driver_ready = 0;
        }

        if (((cycleCounter >= 73 && write_idx < 432) || write_idx > 0)
            && !isWRTGSBlankingCycle(cycleCounter-1)
            && (stream_ready != 0)) {
            for (int i = 0; i < 30; i++) {
                fbOutput[i][write_idx] = BIT(data, i);
            }
            write_idx++;
        }
        if(write_idx == 432) {
            write_idx = 0;
        }
        wait();
    }
}

void Monitor::checkWRTGSBlanking() {
    while (1) {
        wait(clk33.posedge_event());
        if (isWRTGSBlankingCycle(cycleCounter-1) && (stream_ready == 1)) {
            for (int i = 0; i < 30; i++) {
                auto fbSinDriver_i = BIT(data, i);
                if (fbSinDriver_i != 0) {
                    std::string msg = "Missing blanking cycle number ";
                    msg += sc_uint<5>((cycleCounter-1-72) / 48).to_string();
                    msg += " out of 8 for driver ";
                    msg += sc_int<30>(i).to_string();
                    msg += " data: " + std::to_string(fbSinDriver_i);
                    msg += " cycleCounter: " + std::to_string(cycleCounter);
                    msg += " driver_ready: " + std::to_string(driver_ready.read());
                    SC_REPORT_FATAL("data", msg.c_str());
                    return;
                }
            }
        }
    }
}

/*
 * The aims of this testing method is to check that the data
 * that is output by the framebuffer module is correct,
 * relatively to the frames structure and the order in which
 * the data is meant to be ouput aka in poker mode.
 * The idea of the framebuffer is that it reads 30 16-bit wide
 * data from RAM and at the next cycle outputs it.
 *
 * Besides, since the pin assignment for the drivers was changed,
 * look-up tables need to be implemented in the framebuffer module
 * so as to modify the order of the data half words between the moment
 * they are read in RAM and they are sent to the driver controller.
 * Taking the led panel schematic notations, there are two different
 * driver pin assignments for {UB0, {UB1, UB2}}. The 16-bit data is
 * thus changed depending of which driver it corresponds to.
 */
void Monitor::checkDataIntegrity() {
    while (1) {
        wait();
        // Verification performed during a blanking cycle
        if (cycleCounter == 30 && stream_ready && currentMultiplexing >= 2) {
            /*
             * We create a reference data output of the framebuffer,
             * ie what we should obtain, to compare it to what we get
             * from the implemented framebuffer module.
             */
            for (int i = 0; i < 30; i++) {
                /*
                 * Compute the base address of the i-th driver
                 * given the current multiplexing. The fbOutput contains the
                 * data output by the framebuffer on the previous multiplexing
                 * phase, which was read in ram on the multiplexing phase
                 * before, hence we use currentMultiplexing-2.
                 */
                int driverBaseAddress = ramBaseAddress + ramBaseDriverAddress[i]
                                        + currentMultiplexing-2;
                for (int j = 0; j < 9; j++) {
                    for (int k = 0; k < 48; k++) {
                        /*
                         * 9 poker sequences (48 bits) need to be
                         * reconstructed from each driver data in RAM.
                         * In poker mode, sequences are sent MSB first,
                         * and B15 first.
                         * j is the poker sequence number.
                         * k is the bit number.
                         */
                        int ledNumber = (47 - k) / 3;
                        // Index of the color (B=2, G=1, R=0)
                        int color = (47 - k) % 3;
                        // Data needs to be remapped, because of PCB constraints
                        int ledRemapped;
                        // Upper drivers
                        if (i < 20) {
                            if (color != 2)
                                ledRemapped = driver_LUT_D12_RG[ledNumber] ;
                            else
                                ledRemapped = driver_LUT_D12_B[ledNumber];
                        }
                        // Lower drivers
                        else {
                            if (color != 2)
                                ledRemapped = driver_LUT_D0_RG[ledNumber];
                            else
                                ledRemapped = driver_LUT_D0_B[ledNumber];
                        }

                        int lineAddress = driverBaseAddress + ledRemapped * 40;
                        // 16 bit reference data
                        int data = ram(lineAddress);
                        uint8_t resultBit = 0;

                        if (j < 5) {
                            // up to 5 bits for each color
                            if (color == 2) {
                                resultBit = BIT(data, 15 - j);
                            }
                            if (color == 1) {
                                resultBit = BIT(data, 10 - j);
                            }
                            if (color == 0) {
                                resultBit = BIT(data, 4 - j);
                            }
                        }
                        fbOutputReference[i][48*j + k] = resultBit;
                    }
                }
            }

            // Comparison between the 2 arrays
            for (int i = 0; i < 30; i++) {
                for (int j = 0; j < 9; j++) {
                    for (int k = 0; k < 48; k++) {
                        if (fbOutput[i][48*j+k] != fbOutputReference[i][48*j+k]) {

                            // Display the two buffers for the relevant driver
                            std::cout << "fbOutput for driver " << i << std::endl;
                            for (int n = 0; n < 9; n++) {
                                for (int m = 0; m < 48; m++) {
                                    std::cout << std::to_string(fbOutput[i][48*n+m]) << " ";
                                }
                                std::cout << std::endl;
                            }
                            std::cout << "fbOutputReference for driver " << i << std::endl;
                            for (int n = 0; n < 9; n++) {
                                for (int m = 0; m < 48; m++) {
                                    std::cout << std::to_string(fbOutputReference[i][48*n+m]) << " ";
                                }
                                std::cout << std::endl;
                            }

                            std::string msg = "Invalid data for multiplexing ";
                            msg += sc_uint<5>(currentMultiplexing-1).to_string();
                            msg += " for the 48-bit poker sequence number ";
                            msg += sc_uint<5>(j).to_string();
                            msg += " out of 7, and bit number ";
                            msg += sc_uint<8>(k).to_string();
                            msg += " out of 47 (For Driver ";
                            msg += sc_uint<8>(i).to_string();
                            msg += ").";
                            SC_REPORT_ERROR("data", msg.c_str());
                            return;
                        }
                    }
                }
            }

        }
    }
}

/*
 * To emulate the RAM, we simply have an emulator that gives
 * back data as a function of the address to the framebuffer.
 * It will be tested, to be sure that the framebuffer correctly
 * sends data forward to the driver controller in poker mode
 * and in the right order.
 *
 * The real RAM structure is as follows:
 * The µblocks are stored one after another (µblock0, ... , µblock18)
 * Each µblock has 80*48 pixels, each pixel being 16-bit wide, aka RGB565.
 * Poker mode implies that the pixels are cut and sent to each driver
 * in the following order:
 * B15[n] || G15[n] || R15[n] || ... || B0[n] || G0[n] || R0[n]
 */
void Monitor::ramEmulator() { ram_data = ram(ram_addr.read()); }

unsigned int Monitor::ram(unsigned int addr) { return addr % (1 << 16); };
