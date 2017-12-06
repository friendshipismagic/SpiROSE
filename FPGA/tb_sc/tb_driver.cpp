#include <systemc.h>

#include "driver.hpp"

int sc_main(int, char**) {
    const sc_time T(10, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulation_time = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk("clk", T);
    sc_signal<bool> nrst("nrst");

    Driver driver("driver");

    // bind the signals...

    while (sc_time_stamp() < simulation_time) {
        sc_start(1, SC_NS);
    }

    return EXIT_SUCCESS;
}
