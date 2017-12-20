#include <systemc.h>
#include <verilated.h>

#include "monitor.hpp"

void Monitor::reset() {
    nrst = 0;
    wait(clk33.posedge());
    nrst = 1;
}

void Monitor::runTests() {

}

void Monitor::checkDataIntegrity() {

}

void Monitor::checkRamAccess() {

}

void Monitor::ramEmulator() {
    /* To emulate the RAM, we simply have an emulator, that gives
     * back data as a function of the address to the framebuffer.
     * It will be tested, to be sure that the framebuffer correctly
     * sends data forward to the driver controller in poker mode
     * and in the right order.
     */
    ram_data = ram_addr % (1 << 16);
    cout << ram_addr << endl;
}
