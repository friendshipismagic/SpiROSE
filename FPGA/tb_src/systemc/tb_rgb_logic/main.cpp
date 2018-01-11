#include <systemc.h>
#include <verilated.h>

#include "Vrgb_logic.h"

#include "monitor.hpp"
#include "report_handler.hpp"

int sc_main(int argc, char** argv) {
    sc_report_handler::set_handler(report_handler);
    Verilated::commandArgs(argc, argv);

    // TODO: change clock period to the RGB's one
    const sc_time T(30, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulationTime = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk("clk", T);
    sc_signal<bool> nrst("nrst");
    sc_signal<bool> hsync("hsync");
    sc_signal<bool> vsync("vsync");
    sc_signal<bool> writeEnable("write_enable");
    sc_signal<uint32_t> rgb("rgb");
    sc_signal<uint32_t> ramAddr("ram_addr");
    sc_signal<uint32_t> ramData("ram_data");
    sc_signal<bool> rgbEnable("rgb_enable");
    sc_signal<bool> streamReady("stream_ready");

    sc_trace_file* traceFile;
    traceFile = sc_create_vcd_trace_file("rgb_logic");
    sc_trace(traceFile, clk, "clk");
    sc_trace(traceFile, nrst, "nrst");
    sc_trace(traceFile, hsync, "hsync");
    sc_trace(traceFile, vsync, "vsync");
    sc_trace(traceFile, writeEnable, "write_enable");
    sc_trace(traceFile, rgb, "rgb");
    sc_trace(traceFile, ramAddr, "ram_addr");
    sc_trace(traceFile, ramData, "ram_data");
    sc_trace(traceFile, rgbEnable, "rgb_enable");
    sc_trace(traceFile, streamReady, "stream_ready");

    Vrgb_logic dut("rgb_logic");
    dut.rgb_clk(clk);
    dut.nrst(nrst);
    dut.rgb(rgb);
    dut.hsync(hsync);
    dut.vsync(vsync);
    dut.ram_addr(ramAddr);
    dut.ram_data(ramData);
    dut.write_enable(writeEnable);
    dut.rgb_enable(rgbEnable);
    dut.stream_ready(streamReady);

    Monitor monitor("monitor");
    monitor.clk(clk);
    monitor.nrst(nrst);
    monitor.rgb(rgb);
    monitor.hsync(hsync);
    monitor.vsync(vsync);
    monitor.ramAddr(ramAddr);
    monitor.ramData(ramData);
    monitor.writeEnable(writeEnable);
    monitor.rgbEnable(rgbEnable);
    monitor.streamReady(streamReady);

    while (sc_time_stamp() < simulationTime) {
        if (Verilated::gotFinish()) return 1;
        sc_start(T);
    }

    sc_close_vcd_trace_file(traceFile);

    printReport();

    return errorCount();
}
