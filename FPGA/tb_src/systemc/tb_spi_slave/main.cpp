#include <systemc.h>
#include <verilated.h>

#include "Vclock_lse.h"
#include "Vspi_slave.h"

#include "monitor.hpp"
#include "report_handler.hpp"

int sc_main(int argc, char** argv) {
    sc_report_handler::set_handler(report_handler);
    Verilated::commandArgs(argc, argv);

    // TODO: choose a clock closer to the reality for spi
    const sc_time T(30, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulationTime = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk("clk", T);
    sc_signal<bool> nrst("nrst");

    sc_signal<bool> spiSck;
    sc_signal<bool> spiSs;
    sc_signal<bool> spiMosi;
    sc_signal<bool> spiMiso;
    sc_signal<uint32_t> spiRotationData;
    sc_signal<uint64_t> spiDriverConfig;
    sc_signal<bool> spiConfigAvailable;
    sc_signal<bool> rgbEnable;

    sc_trace_file* traceFile;
    traceFile = sc_create_vcd_trace_file("spi");
    sc_trace(traceFile, clk, "clk");
    sc_trace(traceFile, spiSck, "sck");
    sc_trace(traceFile, nrst, "nrst");
    sc_trace(traceFile, spiSs, "ss");
    sc_trace(traceFile, spiMosi, "mosi");
    sc_trace(traceFile, spiMiso, "miso");
    sc_trace(traceFile, spiRotationData, "rotation_data");
    sc_trace(traceFile, spiDriverConfig, "config_out");
    sc_trace(traceFile, spiConfigAvailable, "new_config_available");
    sc_trace(traceFile, rgbEnable, "rgb_enable");

    Vspi_slave dut("spi");
    dut.spi_clk(spiSck);
    dut.nrst(nrst);
    dut.spi_ss(spiSs);
    dut.spi_mosi(spiMosi);
    dut.spi_miso(spiMiso);
    dut.rotation_data(spiRotationData);
    dut.config_out(spiDriverConfig);
    dut.new_config_available(spiConfigAvailable);
    dut.rgb_enable(rgbEnable);

    Monitor monitor("monitor");
    monitor.clk(clk);
    monitor.sck(spiSck);
    monitor.nrst(nrst);
    monitor.ss(spiSs);
    monitor.mosi(spiMosi);
    monitor.miso(spiMiso);
    monitor.rotationData(spiRotationData);
    monitor.configOut(spiDriverConfig);
    monitor.newConfigAvailable(spiConfigAvailable);
    monitor.rgbEnable(rgbEnable);

    while (sc_time_stamp() < simulationTime) {
        if (Verilated::gotFinish()) return 1;
        sc_start(T);
    }

    sc_close_vcd_trace_file(traceFile);

    printReport();

    return errorCount();
}
