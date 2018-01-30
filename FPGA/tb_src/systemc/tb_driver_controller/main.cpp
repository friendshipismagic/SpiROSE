#include <systemc.h>
#include <verilated.h>
#include <array>
#include <cstdint>
#include <memory>
#include <sstream>

#include "Vclock_enable.h"
#include "Vdriver_controller.h"

#include "driver.hpp"
#include "driver_cmd.h"

#include "monitor.hpp"
#include "report_handler.hpp"

constexpr int DRIVER_NB = 30;

void tb_report_handler(const sc_report& report, const sc_actions& actions) {
    if (report.get_process_name()) {
        auto name = std::string(report.get_process_name());
        auto it = name.find("monitor.driver");
        std::string allowedName = "monitor.driver_1.";
        if (it != std::string::npos &&
            name.substr(0, allowedName.size()) != allowedName)
            return;
    }
    report_handler(report, actions);
}

int sc_main(int argc, char** argv) {
    sc_report_handler::set_handler(tb_report_handler);
    Verilated::commandArgs(argc, argv);

    const sc_time T(15, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulationTime = T * STEPS * MAIN_DIV * DIV_RATIO * 128 * 2;

    sc_clock clk66("clk66", T);
    sc_signal<bool> nrst("nrst");
    sc_signal<bool> driverSclk("driver_sclk");
    sc_signal<bool> driverGclk("driver_gclk");
    sc_signal<bool> driverLat("driver_lat");
    sc_signal<uint32_t> driversSin("drivers_sin");

    sc_signal<bool> sof("start_of_frame");
    sc_signal<bool> eoc("end_of_column");

    sc_signal<bool> startConfig("start_config");
    sc_signal<bool> endConfig("end_config");
    sc_signal<uint64_t> configData("config_data");
    sc_signal<sc_bv<432>> data[15];

    sc_signal<uint32_t> muxOut("mux_out");

    sc_signal<bool> clk_enable;

    sc_signal<uint32_t> debug;

    sc_trace_file* traceFile;
    traceFile = sc_create_vcd_trace_file("driver_controller");
    sc_trace(traceFile, clk66, "clk_66");
    sc_trace(traceFile, clk_enable, "clk_enable");

    sc_trace(traceFile, driverGclk, "GCLK");
    sc_trace(traceFile, driverSclk, "SCLK");
    sc_trace(traceFile, driverLat, "LAT");
    sc_trace(traceFile, driversSin, "driversSin");

    sc_trace(traceFile, sof, "start_of_frame");
    sc_trace(traceFile, eoc, "end_of_column");

    sc_trace(traceFile, configData, "config");

    sc_trace(traceFile, data, "data");
    sc_trace(traceFile, muxOut, "mux_out");
    sc_trace(traceFile, debug, "debug");

    Vclock_enable main_clock_enable("clock_enable");
    main_clock_enable.clk(clk66);
    main_clock_enable.nrst(nrst);
    main_clock_enable.clk_enable(clk_enable);

    Vdriver_controller dut("driver_controller");
    dut.clk(clk66);
    dut.clk_enable(clk_enable);
    dut.nrst(nrst);
    dut.driver_sclk(driverSclk);
    dut.driver_gclk(driverGclk);
    dut.driver_lat(driverLat);
    dut.drivers_sin(driversSin);
    dut.config_data(configData);
    dut.start_config(startConfig);
    dut.end_config(endConfig);
    dut.SOF(sof);
    dut.EOC(eoc);
    dut.mux_out(muxOut);
    dut.debug(debug);
    for (int i = 0; i < 15; ++i) dut.data[i](data[i]);

    Monitor monitor("monitor");
    monitor.clk(clk66);
    monitor.nrst(nrst);
    monitor.sin(driversSin);
    monitor.lat(driverLat);
    monitor.gclk(driverGclk);
    monitor.sclk(driverSclk);
    monitor.sof(sof);
    monitor.eoc(eoc);
    monitor.configData(configData);
    monitor.startConfig(startConfig);
    monitor.endConfig(endConfig);
    for (int i = 0; i < 15; ++i) monitor.data[i](data[i]);

    nrst = 0;
    sc_start(T);
    sc_start(T);
    nrst = 1;

    while (sc_time_stamp() < simulationTime) {
        if (Verilated::gotFinish()) return 1;
        sc_start(T);
    }

    sc_close_vcd_trace_file(traceFile);

    printReport();

    return errorCount();
}
