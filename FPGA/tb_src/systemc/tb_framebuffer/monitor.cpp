#include <systemc.h>
#include <verilated.h>
#include <array>

#include "monitor.hpp"
#include "driver_LUT.hpp"

static uint8_t fbOutput[30][9][48];
static uint8_t fbOutputReference[30][9][48];
// Array with the base ram addresses for each driver
static const std::array<unsigned int, 30> ramBaseDriverAddress
{
    0      , 1, 
    16     , 17, 
    32     , 33, 
    48     , 49, 
    64     , 65,
    1280   , 1281, 
    1280+16, 1280+17, 
    1280+32, 1280+33,
    1280+48, 1280+49,
    1280+64, 1280+65,
    2560   , 2561,
    2560+16, 2560+17,
    2560+32, 2560+33,
    2560+48, 2560+49,
    2560+64, 2560+65
};



void Monitor::reset() {
    nrst = 0;
    wait(clk33.posedge());
    nrst = 1;
}

int Monitor::isWRTGSBlankingCycle(int cycle) {
    if ( cycle == 48
        || cycle == 97
        || cycle == 146
        || cycle == 195
        || cycle == 244
        || cycle == 293
        || cycle == 342
        || cycle == 391) {
        return 1;
    }
    return 0;
}

void Monitor::runTests() {
    reset();

    auto blanking_p =
            sc_spawn(sc_bind(&Monitor::checkWRTGSBlanking, this));


    while(1) {
        wait();
    }
}

void Monitor::continuousCycleCount() {
    while(1) {
        if (!nrst) {
            cycleCounter = 0;
            numberOfColumnsRead = 0;
            currentMultiplexing = 0;
        }
        else {
            if (cycleCounter == 512) {
                cycleCounter = 0;
                numberOfColumnsRead++;
                if (currentMultiplexing == 7)
                    currentMultiplexing = 0;
                else
                    if (numberOfColumnsRead > 0)
                        currentMultiplexing++;
            }
            cycleCounter++;
        }
        wait();
    }
}

void Monitor::storeOutputData() {
    while(1) {
        if (!nrst) {
            // Reset the value of the output test array
            int i, j, k;
            for (i = 0; i < 30; i++) {
                for (j = 0; j < 9; j++) {
                    for (k = 0; k < 48; k++) {
                        fbOutput[i][j][k] = 0;
                        fbOutputReference[i][j][k] = 0;
                    }
                }
            }
        }
        else if (cycleCounter >= 0 
                    && cycleCounter < 440
                    && !isWRTGSBlankingCycle(cycleCounter)
                    && (numberOfColumnsRead != 0)) {
            for (int i = 0; i < 30; i++) {
                fbOutput[i][cycleCounter/49][cycleCounter%49] = (data >> i) & 0x1;
            }
        }
        wait();
    }
}

void Monitor::checkWRTGSBlanking() {
    while (1) {
        wait(clk33.posedge_event());
        if (isWRTGSBlankingCycle(cycleCounter) && (numberOfColumnsRead != 0)) {
            for (int i = 0; i < 30; i++) {
                if (fbOutput[i][(cycleCounter-1)/49][(cycleCounter-1)%49] 
                        != (data >> i) & 0x1) {
                    std::string msg = "Missing blanking cycle number ";
                    unsigned int cyclePosition = (cycleCounter-1)/49;
                    msg += sc_uint<5>(cyclePosition).to_string();
                    msg += " out of 8 for driver ";
                    msg += sc_int<30>(i).to_string();
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
    while(1) {
        wait();
        // Verification performed during a blanking cycle
        if (cycleCounter == 500 && numberOfColumnsRead > 0) {
            /*
             * We create a reference data output of the framebuffer, 
             * ie what we should obtain, to compare it to what we get
             * from the implemented framebuffer module.
             */
            for (int i = 0; i < 30; i++) {
                /* 
                 * Compute the base address of the i-th driver
                 * given the current multiplexing
                 */
                int driverBaseAddress = ramBaseDriverAddress[i]
                        + currentMultiplexing*2;
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
                        int lineAddress = driverBaseAddress + ((47-k)/3)*80;
                        // Index of the color (B=2, G=1, R=0)
                        int color = (47-k) % 3;
                        // 16 bit reference data
                        int data = lineAddress % (1 << 16);
                        uint8_t resultBit;

                        if (j < 5) {
                            // up to 5 bits for each color
                            if (color == 0) {
                                resultBit = (data >> (15 - j)) & 0x1;
                            }
                            if (color == 1) {
                                resultBit = (data >> (10 - j)) & 0x1;
                            }
                            if (color == 2) {
                                resultBit = (data >> (4 - j)) & 0x1;
                            }
                        }
                        else if (j == 5 && color == 1) {
                            // Case of the 6-th bit of color Green
                            resultBit = (data >> 5) & 0x1;
                        }
                        // Data needs to be remapped, because of PCB constraints
                        int kRemapped;
                        // Upper drivers
                        if (i < 10) {
                            if (color == 0)
                                kRemapped = driver_LUT_D0_RG[(47-k)/3] *3;
                            else if (color == 1)
                                kRemapped = driver_LUT_D0_RG[(47-k)/3] *3+1;
                            else if (color == 2)
                                kRemapped = driver_LUT_D0_B[(47-k)/3] *3+2;
                        }
                        // Lower drivers
                        else {
                            if (color == 0)
                                kRemapped = driver_LUT_D12_RG[(47-k)/3] *3;
                            else if (color == 1)
                                kRemapped = driver_LUT_D12_RG[(47-k)/3] *3+1;
                            else if (color == 2)
                                kRemapped = driver_LUT_D12_B[(47-k)/3] *3+2;
                        }

                        fbOutputReference[i][j][47-kRemapped] = resultBit;
                    }
                }
            }

            // Comparison between the 2 arrays
            for (int i = 0; i < 30; i++) {
                for (int j = 0; j < 9; j++) {
                    for (int k = 0; k < 48; k++) {
                        if (fbOutput[i][j][k] != fbOutputReference[i][j][k]) {
                            std::string msg = "Invalid data for multiplexing ";
                            msg += sc_uint<5>(currentMultiplexing).to_string();
                            msg += " for the 48-bit poker sequence number ";
                            msg += sc_uint<5>(j).to_string();
                            msg += " out of 8, and bit number ";
                            msg += sc_uint<8>(k).to_string();
                            msg += " out of 47 (For Driver ";
                            msg += sc_uint<8>(i).to_string();
                            msg += "). Output check number ";
                            msg += sc_uint<16>(numberOfColumnsRead).to_string();
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
void Monitor::ramEmulator() {
    ram_data = ram_addr % (1 << 16);
}
