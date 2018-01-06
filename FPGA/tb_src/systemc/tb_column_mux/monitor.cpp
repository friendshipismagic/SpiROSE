#include <systemc.h>
#include <verilated.h>

#include "monitor.hpp"

void Monitor::runTests() {
    sendReset();

    // wait some cycles before sending anything
    wait(200);

    sc_spawn(sc_bind(&Monitor::checkMuxOutTimings, this));
    sc_spawn(sc_bind(&Monitor::checkMuxOutSequence, this));

    while (true) wait();
}

void Monitor::checkMuxOutTimings() {
    auto t = sc_time_stamp();
    while (true) {
        wait(muxOut.value_changed_event());
        auto t2 = sc_time_stamp();
        sc_time delta = t2 - t;
        if (delta > TIME_MUX_CHANGE) {
            auto msg =
                "column_mux doesn't respect mux timings, it should "
                "change within " +
                TIME_MUX_CHANGE.to_string() + " and changed after " +
                delta.to_string();
            SC_REPORT_FATAL("mux", msg.c_str());
            return;
        }
        t = t2;
    }
}

void Monitor::checkMuxOutSequence() {
    auto previousValue = muxOut.read();
    while(true) {
        wait(muxOut.value_changed_event());
        auto newValue = muxOut.read();
        auto delta = (newValue >> 1) - previousValue;
        if(delta != 0 && newValue != 1) {
            auto msg =
                "column_mux doesn't respect mux sequences, "
                "it changed from " +
                std::to_string(previousValue) + " to " +
                std::to_string(newValue);
            SC_REPORT_FATAL("mux", msg.c_str());
            return;
        }
        previousValue = newValue;
    }
}

void Monitor::sendReset() {
    nrst = 0;
    for (int i = 0; i < 10; ++i) {
        wait(clk.posedge());
    }
    nrst = 1;
}
