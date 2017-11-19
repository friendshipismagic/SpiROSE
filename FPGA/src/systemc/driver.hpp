#pragma once

#include <systemc.h>

class Driver : public sc_module {
    SC_HAS_PROCESS(Driver);

    public:
    inline Driver(const sc_module_name& name) : sc_module(name) {
        SC_CTHREAD(handle_sin, clk);
    }

    void handle_sin() {}

    sc_signal<bool> clk;
};
