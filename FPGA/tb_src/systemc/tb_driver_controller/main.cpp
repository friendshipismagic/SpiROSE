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

    const sc_time T(30, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulationTime = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk66("clk66", T);
    sc_signal<bool> clk33("clk33");
    sc_signal<bool> nrst("nrst");
    sc_signal<unsigned int> framebufferData("framebuffer_data");
    sc_signal<bool> framebufferSync("framebuffer_sync");
    sc_signal<bool> driverSclk("driver_sclk");
    sc_signal<bool> driverGclk("driver_gclk");
    sc_signal<bool> driverLat("driver_lat");

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
    sc_trace(traceFile, clk66, "clk_66");
    sc_trace(traceFile, clk33, "clk_33");

    Vclock_lse clock_lse("clock_lse");
    clock_lse.nrst(nrst);
    clock_lse.clk_lse(clk33);
    clock_lse.clk_hse(clk66);

    Vdriver_controller dut("driver_controller");
    dut.clk_hse(clk66);
    dut.clk_lse(clk33);
    dut.nrst(nrst);
    dut.framebuffer_dat(framebufferData);
    dut.framebuffer_sync(framebufferSync);
    dut.driver_sclk(driverSclk);
    dut.driver_gclk(driverGclk);
    dut.driver_lat(driverLat);
    dut.drivers_sin(driversSin);
    dut.driver_sout(driverSout);
    dut.driver_sout_mux(driverSoutMux);
    dut.serialized_conf(serializedConf);

    Monitor monitor("monitor");
    monitor.clk(clk66);
    monitor.nrst(nrst);
    monitor.sin(driversSin);
    monitor.lat(driverLat);
    monitor.gclk(driverGclk);
    monitor.sclk(driverSclk);
    monitor.framebufferData(framebufferData);
    monitor.framebufferSync(framebufferSync);
    monitor.config(serializedConf);

    while (sc_time_stamp() < simulationTime) {
        if (Verilated::gotFinish()) return 1;
        sc_start(T);
    }

    // TODO: should we resync by sending a TGMRST if we receive a
    // famebuffer_sync ?

    sc_close_vcd_trace_file(traceFile);

    printReport();

    return errorCount();
}
