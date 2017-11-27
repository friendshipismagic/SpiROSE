#include <systemc.h>
#include <verilated.h>

#include "Vdriver_controller.h"

int sc_main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    const sc_time T(30, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulation_time = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk("clk", T);
    sc_signal<bool> nrst("nrst");
    sc_signal<unsigned int> framebuffer_dat("framebuffer_dat");
    sc_signal<bool> framebuffer_sync("framebuffer_sync");
    sc_signal<bool> driver_sclk("driver_sclk");
    sc_signal<bool> driver_gclk("driver_gclk");
    sc_signal<bool> driver_lat("driver_lat");

    sc_signal<unsigned int> drivers_sin("drivers_sin");
    sc_signal<bool> driver_sout;
    sc_signal<unsigned int> driver_sout_mux;

    sc_signal<std::uint64_t> serialized_conf;

    Vdriver_controller top("driver_controller");

    top.clk_33(clk);
    top.nrst(nrst);
    top.framebuffer_dat(framebuffer_dat);
    top.framebuffer_sync(framebuffer_sync);
    top.driver_sclk(driver_sclk);
    top.driver_gclk(driver_gclk);
    top.driver_lat(driver_lat);
    top.drivers_sin(drivers_sin);
    top.driver_sout(driver_sout);
    top.driver_sout_mux(driver_sout_mux);
    top.serialized_conf(serialized_conf);

    for (int i = 0; i < 1000000; ++i) {
        if (Verilated::gotFinish()) return EXIT_SUCCESS;
        sc_start(1, SC_NS);
    }

    return EXIT_SUCCESS;
}
