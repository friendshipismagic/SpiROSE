#pragma once

#include <systemc.h>

class Driver : public sc_module {
    SC_HAS_PROCESS(Driver);

    public:
    inline Driver(const sc_module_name& name)
        : sc_module(name), gclk("gclk"), sclk("sclk"), sin("sin"), lat("lat") {
        SC_CTHREAD(handle_sin, gclk);
        SC_CTHREAD(handle_lat, gclk);
    }

    void handle_sin() {
        while (true) {
            wait();
            gs_reg = ((gs_reg.read() << 1) & ~1) | sin;
        }
    }

    void handle_lat() {
        while (true) {
            wait();
            if (lat) {
                lat_counter = lat_counter.read() + 1;
            } else if (lat_counter == 1) {
                // WRTGS
            } else if (lat_counter == 3) {
                // LATGS
            }
        }
    }

    sc_in<bool> gclk;
    sc_in<bool> sclk;
    sc_in<bool> nrst;

    sc_in<bool> sin;
    sc_in<bool> lat;

    private:
    sc_signal<sc_bv<48>> gs_reg;
    sc_signal<int> lat_counter;
};
