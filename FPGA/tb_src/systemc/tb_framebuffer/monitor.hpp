#include "systemc.h"

SC_MODULE(Monitor) {
    SC_CTOR(Monitor) {
        SC_CTHREAD(runTests, clk33.pos());
        SC_METHOD(ramEmulator);
        sensitive << ram_addr;
    }

    sc_in<bool> clk33;
    sc_out<bool> nrst;

    sc_in<bool> sync;
    sc_in<unsigned int> data;

    sc_in<unsigned int> ram_addr;
    sc_out<unsigned int> ram_data;

    sc_out<unsigned int> enc_position;
    sc_out<bool> enc_sync;

    void runTests();
    void checkDataIntegrity();
    void checkRamAccess();
    void ramEmulator();

    private:

    void reset();
};
