#pragma once

#include <systemc.h>

class Driver : public sc_module {
    public:
    inline Driver(const sc_module_name& name) : sc_module(name) {}
};
