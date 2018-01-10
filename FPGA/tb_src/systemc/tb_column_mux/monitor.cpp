#include <systemc.h>
#include <verilated.h>

#include "monitor.hpp"

void Monitor::runTests() {
    sendReset();

    // wait some cycles before sending anything
    for (int i = 0; i < 200; ++i) {
        wait(clk.posedge_event());
    }

    columnReady = true;

    sc_spawn(sc_bind(&Monitor::checkMuxOutTimings, this));
    sc_spawn(sc_bind(&Monitor::checkMuxOutSequence, this));

    while (true) wait(clk.posedge_event());
}

void Monitor::checkMuxOutIsZeroWithoutColumnReady() {
    std::string msg;
    msg += "column_mux changed value while column_ready was off";
    while (true) {
        if (!columnReady && muxOut.read() != 0) {
            SC_REPORT_ERROR("mux", msg.c_str());
            return;
        }
        wait(muxOut.value_changed_event());
    }
}

void Monitor::checkMuxOutTimings() {
    auto t = sc_time_stamp();
    while (true) {
        while (muxOut == 0) {
            wait(clk.posedge_event());
        }
        auto p =
            sc_spawn(sc_bind(&Monitor::timeoutThread, this, TIME_MUX_CHANGE));
        sc_event_or_list evt;
        evt |= muxOut.value_changed_event();
        evt |= p.terminated_event();
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
    bool zeroed = muxOut.read() == 0;
    while (true) {
        wait(muxOut.value_changed_event());
        auto newValue = muxOut.read();
        auto delta = (newValue >> 1) - previousValue;
        if (delta != 0 && newValue != 0 && (newValue != 1 || !zeroed)) {
            auto msg =
                "column_mux doesn't respect mux sequences, "
                "it changed from " +
                std::to_string(previousValue) + " to " +
                std::to_string(newValue);
            SC_REPORT_FATAL("mux", msg.c_str());
            return;
        }
        if (newValue != 0) previousValue = newValue;
        zeroed = newValue == 0;
    }
}

void Monitor::timeoutThread(sc_time timeout) { wait(timeout); }

void Monitor::sendReset() {
    nrst = 0;
    for (int i = 0; i < 10; ++i) {
        wait(clk.posedge_event());
    }
    nrst = 1;
}
