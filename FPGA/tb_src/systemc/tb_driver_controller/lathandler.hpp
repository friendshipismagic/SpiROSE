#pragma once

#include <systemc.h>

// TODO: pass event instead of clk
struct LatHandler : public sc_module {
    int waitLat(const sc_in<bool>& clk, const sc_in<bool>& lat) {
        int latCounter = 0;
        while (latCounter == 0 || lat.read() == 1) {
            latCounter += lat;
            wait(clk.posedge_event());
        }
        return latCounter;
    }
    void waitLat(const sc_in<bool>& clk, const sc_in<bool>& lat, int latCount) {
        while (waitLat(clk, lat) != latCount) {
            // nothing to do, just wait
        }
    }
};
