#include <cstdio>
#include <iostream>

#include <systemc.h>
#include <verilated.h>

#include "Vspi_decoder.h"
#include "Vspi_iff.h"

#include "monitor.hpp"
#include "report_handler.hpp"

int sc_main(int argc, char** argv) {
    sc_report_handler::set_handler(report_handler);
    Verilated::commandArgs(argc, argv);

    // TODO: choose a clock closer to the reality for spi
    const sc_time T(30, SC_NS);
    const sc_time T_lse(200, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulationTime = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk("clk", T);
    // We need a low speed clock to generate spi_clk
    sc_clock clkLse("clk_lse", T_lse);
    sc_signal<bool> nrst("nrst");

    sc_signal<bool> spiSck;
    sc_signal<bool> spiSs;
    sc_signal<bool> spiMosi;
    sc_signal<bool> spiMiso;
    sc_signal<uint64_t> cmdRead;
    sc_signal<uint32_t> cmdLenBytes;
    sc_signal<uint64_t> cmdWrite;
    sc_signal<bool> valid;
    sc_signal<uint32_t> spiRotationData;
    sc_signal<uint32_t> spiSpeedData;
    sc_signal<uint32_t> spiDebugData;
    sc_signal<uint64_t> spiDriverConfig;
    sc_signal<bool> spiConfigAvailable;
    sc_signal<bool> rgbEnable;
    sc_signal<uint32_t> mux;
    sc_signal<uint64_t> driver_data[30];

    sc_trace_file* traceFile;
    traceFile = sc_create_vcd_trace_file("spi");
    sc_trace(traceFile, clk, "clk");
    sc_trace(traceFile, clkLse, "clk_lse");
    sc_trace(traceFile, spiSck, "sck");
    sc_trace(traceFile, nrst, "nrst");
    sc_trace(traceFile, spiSs, "ss");
    sc_trace(traceFile, spiMosi, "mosi");
    sc_trace(traceFile, spiMiso, "miso");
    sc_trace(traceFile, valid, "valid");
    sc_trace(traceFile, cmdRead, "cmd_read");
    sc_trace(traceFile, cmdWrite, "cmd_write");
    sc_trace(traceFile, cmdLenBytes, "cmd_len_bytes");
    sc_trace(traceFile, spiRotationData, "rotation_data");
    sc_trace(traceFile, spiSpeedData, "speed_data");
    sc_trace(traceFile, spiDebugData, "debug_data");
    sc_trace(traceFile, spiDriverConfig, "configuration");
    sc_trace(traceFile, spiConfigAvailable, "new_config_available");
    sc_trace(traceFile, rgbEnable, "rgb_enable");
    sc_trace(traceFile, mux, "mux");
    for (int i = 0; i < 30; i++)
        sc_trace(traceFile, driver_data[i],
                 "driver_data[" + std::to_string(i) + "]");

    Vspi_iff dut1("spi_iff");
    dut1.clk(clk);
    dut1.nrst(nrst);
    dut1.spi_clk(spiSck);
    dut1.spi_ss(spiSs);
    dut1.spi_mosi(spiMosi);
    dut1.spi_miso(spiMiso);
    dut1.cmd_read(cmdRead);
    dut1.cmd_len_bytes(cmdLenBytes);
    dut1.cmd_write(cmdWrite);
    dut1.valid(valid);

    Vspi_decoder dut2("spi_decoder");
    dut2.clk(clk);
    dut2.nrst(nrst);
    dut2.valid(valid);
    dut2.cmd_read(cmdRead);
    dut2.cmd_len_bytes(cmdLenBytes);
    dut2.cmd_write(cmdWrite);
    dut2.rotation_data(spiRotationData);
    dut2.speed_data(spiSpeedData);
    dut2.debug_data(spiDebugData);
    dut2.configuration(spiDriverConfig);
    dut2.new_config_available(spiConfigAvailable);
    dut2.rgb_enable(rgbEnable);
    dut2.mux(mux);
    for (int i = 0; i < 30; i++) dut2.driver_data[i](driver_data[i]);

    Monitor monitor("monitor");
    monitor.clk(clkLse);
    monitor.nrst(nrst);
    monitor.sck(spiSck);
    monitor.ss(spiSs);
    monitor.mosi(spiMosi);
    monitor.miso(spiMiso);
    monitor.valid(valid);
    monitor.rotationData(spiRotationData);
    monitor.speedData(spiSpeedData);
    monitor.debugData(spiDebugData);
    monitor.configuration(spiDriverConfig);
    monitor.newConfigAvailable(spiConfigAvailable);
    monitor.rgbEnable(rgbEnable);
    monitor.mux(mux);
    for (int i = 0; i < 30; i++) (*monitor.driver_data[i])(driver_data[i]);

    while (sc_time_stamp() < simulationTime) {
        if (Verilated::gotFinish()) return 1;
        sc_start(T);
    }

    sc_close_vcd_trace_file(traceFile);

    printReport();

    return errorCount();
}
