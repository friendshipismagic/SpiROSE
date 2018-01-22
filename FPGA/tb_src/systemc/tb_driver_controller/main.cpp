#include <systemc.h>
#include <verilated.h>
#include <array>
#include <cstdint>
#include <memory>
#include <sstream>

#include "Vclock_lse.h"
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

    // Use for defining the period of the main clock
    const sc_time T(30, SC_NS);
    // Use for defining the starting time fo the quadrature clock
    const sc_time T_start(7.5, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulationTime = T * STEPS * MAIN_DIV * DIV_RATIO * 128 * 2;

    sc_clock clk("clk", T, 0.5, SC_ZERO_TIME, true);
    sc_clock clkQuad("clk_quad", T, 0.5, T_start, true);
    sc_signal<bool> nrst("nrst");
    sc_signal<unsigned int> framebufferData("framebuffer_data");
    sc_signal<bool> driverSclk("driver_sclk");
    sc_signal<bool> driverGclk("driver_gclk");
    sc_signal<bool> driverLat("driver_lat");
    sc_signal<bool> positionSync("position_sync");
    sc_signal<bool> driverReady("driverReady");
    sc_signal<bool> columnReady("column_ready");
    sc_signal<bool> newConfigurationReady("new_configuration_ready");

    sc_signal<unsigned int> driversSin("drivers_sin");
    sc_signal<bool> driverSout;
    sc_signal<unsigned int> driverSoutMux;

    sc_signal<uint64_t> serializedConf;

    sc_trace_file* traceFile;
    traceFile = sc_create_vcd_trace_file("driver_controller");
    sc_trace(traceFile, serializedConf, "config");
    sc_trace(traceFile, driverGclk, "GCLK");
    sc_trace(traceFile, driverSclk, "SCLK");
    sc_trace(traceFile, driverLat, "LAT");
    sc_trace(traceFile, columnReady, "column_ready");
    sc_trace(traceFile, driverReady, "driver_ready");
    sc_trace(traceFile, positionSync, "position_sync");
    sc_trace(traceFile, newConfigurationReady, "new_configuration_ready");
    sc_trace(traceFile, clk, "clk");
    sc_trace(traceFile, clkQuad, "clk_quad");

    Vdriver_controller dut("driver_controller");
    dut.clk(clk);
    dut.clk_quad(clkQuad);
    dut.nrst(nrst);
    dut.framebuffer_dat(framebufferData);
    dut.driver_sclk(driverSclk);
    dut.driver_gclk(driverGclk);
    dut.driver_lat(driverLat);
    dut.drivers_sin(driversSin);
    dut.driver_sout(driverSout);
    dut.driver_sout_mux(driverSoutMux);
    dut.serialized_conf(serializedConf);
    dut.new_configuration_ready(newConfigurationReady);
    dut.position_sync(positionSync);
    dut.driver_ready(driverReady);
    dut.column_ready(columnReady);

    Monitor monitor("monitor");
    monitor.clk(clk);
    monitor.nrst(nrst);
    monitor.sin(driversSin);
    monitor.lat(driverLat);
    monitor.gclk(driverGclk);
    monitor.sclk(driverSclk);
    monitor.framebufferData(framebufferData);
    monitor.positionSync(positionSync);
    monitor.driverReady(driverReady);
    monitor.columnReady(columnReady);
    monitor.config(serializedConf);
    monitor.newConfigurationReady(newConfigurationReady);

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
