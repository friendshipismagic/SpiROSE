#include <systemc.h>
#include <verilated.h>

#include "Vdriver_controller.h"

int sc_main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    const sc_time T(10, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulation_time = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk("clk", T);
    sc_signal<bool> nrst("nrst");

    sc_signal<bool> drv_ctrl_sin("sin"), drv_ctrl_lat("lat"),
        drv_ctrl_bit_in("bit_in"), gclk("gclk"), sclk("sclk");

    Vdriver_controller top("driver_controller");

    for (int i = 0; i < 1000000; ++i) {
        if (Verilated::gotFinish()) return EXIT_SUCCESS;
        sc_start(1, SC_NS);
    }

    return EXIT_SUCCESS;
}
