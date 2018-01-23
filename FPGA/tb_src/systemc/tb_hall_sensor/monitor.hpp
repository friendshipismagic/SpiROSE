#pragma once

#include <systemc.h>
#include <verilated.h>

SC_MODULE(Monitor) {
    SC_CTOR(Monitor)
        : nrst("nrst"),
          clk("clk"),
          hall1("hall1"),
          hall2("hall2"),
          positionSync("positionSync"),
          sliceCnt("sliceCnt"){
        SC_THREAD(runTests);
    }

    void runTests();

    sc_out<bool> nrst;
    sc_in<bool> clk;

    sc_out<bool> hall1;
    sc_out<bool> hall2;

    sc_in<bool> positionSync;
    sc_in<unsigned int> sliceCnt;

    int positionSyncCounter;
    void checkPositionSync(int value_hall1_to_hall2, int value_hall2_to_hall1);
    void storePositionSync();
    void checkThatPositionSyncAreSpacedEvenly();

    private:
    void sendReset();
    void sendHallSignals(int value_hall1_to_hall2, int value_hall2_to_hall1);
};
