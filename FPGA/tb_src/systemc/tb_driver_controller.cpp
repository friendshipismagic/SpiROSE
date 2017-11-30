#include <systemc.h>
#include <verilated.h>
#include <cstdint>
#include <memory>
#include <sstream>

#include "Vdriver_controller.h"
#include "driver.hpp"
#include "driver_cmd.h"

constexpr int DRIVER_NB = 30;

// TODO: pass event instead of clk
struct LatHandler : public sc_module {
    int waitLat(const sc_in<bool>& clk, const sc_in<bool>& lat) {
        int latCounter = 0;
        while (latCounter == 0 || lat.read() == 1) {
            latCounter += lat;
            wait(clk.posedge_event());
        }
        return latCounter;
    }
    void waitLat(const sc_in<bool>& clk, const sc_in<bool>& lat, int latCount) {
        while (waitLat(clk, lat) != latCount) {
            // nothing to do, just wait
        }
    }
};

struct Stimuler : public sc_module {
    SC_CTOR(Stimuler) { SC_CTHREAD(runTests, clk.pos()); }

    void runTests() {
        Driver::RegBuff conf;
        std::string confStr = "010111001000001000000001000000000001000";
        std::string revConfStr(confStr.rbegin(), confStr.rend());
        conf = revConfStr.c_str();
        framebufferSync = false;

        reset();
        sendConfig(conf);

        wait();
        wait();

        // Send start of frame signal
        framebufferSync = true;
        wait();
        framebufferSync = false;

        while (true) {
            wait();
        }
    }

    void reset() {
        nrst = 0;
        for (int i = 0; i < 10; ++i) {
            wait(clk.posedge());
        }
        nrst = 1;
    }

    void sendConfig(Driver::RegBuff conf) {
        config = conf.to_uint();
        // Wait until config is done
        for (int i = 0; i < 200; ++i) wait(clk.posedge());
    }

    sc_in<bool> clk;
    sc_out<bool> nrst;
    sc_out<uint64_t> config;
    sc_out<uint32_t> framebufferData;
    sc_out<bool> framebufferSync;
};

struct Monitor : public LatHandler {
    SC_CTOR(Monitor)
        : sin("sin"), lat("lat"), gclk("gclk"), sclk("sclk"), nrst("nrst") {
        SC_CTHREAD(runTests, clk.pos());

        SC_THREAD(checkConfigProtocol);

        SC_METHOD(copySinToArray);
        sensitive << sin;

        SC_THREAD(checkData);

        for (int i = 0; i < DRIVER_NB; ++i) {
            std::ostringstream stream;
            stream << "driver_" << i;
            m_drivers[i] = std::make_unique<Driver>(stream.str().c_str());
            m_drivers[i]->sin(m_sin[i]);
            m_drivers[i]->lat(lat);
            m_drivers[i]->sclk(sclk);
            m_drivers[i]->gclk(gclk);
            m_drivers[i]->nrst(nrst);
        }
    }

    void runTests() {
        sc_spawn(sc_bind(&Monitor::checkTimingRequirementsLat, this,
                         (int)LATCH_LATGS, sc_time(80, SC_NS)));
        sc_spawn(sc_bind(&Monitor::checkTimingRequirementsLat, this,
                         LATCH_READFC, sc_time(80, SC_NS)));
        sc_spawn(sc_bind(&Monitor::checkTimingRequirementsLat, this,
                         LATCH_LINERESET, sc_time(80, SC_NS)));

        sc_spawn(sc_bind(&Monitor::checkTimingRequirementsLat, this,
                         LATCH_WRTGS, sc_time(20, SC_NS)));
        sc_spawn(sc_bind(&Monitor::checkTimingRequirementsLat, this,
                         LATCH_WRTFC, sc_time(20, SC_NS)));
        sc_spawn(sc_bind(&Monitor::checkTimingRequirementsLat, this,
                         LATCH_TMGRST, sc_time(20, SC_NS)));

        while (true) wait();
    }

    /*
     * Combinatorial glue logic to convert uint32_t into 30 bool signals
     */
    void copySinToArray() {
        for (int i = 0; i < DRIVER_NB; ++i) {
            m_sin[i] = sin.read() >> i & 1;
        }
    }

    void checkConfigProtocol() {
        std::cout << "[TEST]: starting configuration protocol checker processus"
                  << std::endl;

        m_checkNoGCLKDuringConfig =
            sc_spawn(sc_bind(&Monitor::checkNoGCLKDuringConfig, this));
        m_checkNoGCLKDuringConfig.suspend();

        std::cout << "Start waiting for config" << std::endl;

        while (true) {
            // Wait until we get FCWRTEN
            // waitLat(sclk, lat, LATCH_FCWRTEN);
            auto latCount = waitLat(sclk, lat);
            if (latCount != LATCH_FCWRTEN) {
                std::cout << "Received " << latCount
                          << " instead of config latch " << std::endl;
                continue;
            }

            std::cout << "[FCWRTEN] Receiving configuration request from DUT"
                      << std::endl;

            // Start process checking that config is correctly sent
            auto p_checkConfig = sc_spawn(sc_bind(&Monitor::checkConfig, this));

            // Start process checking that gclk is not started
            m_checkNoGCLKDuringConfig.resume();

            // Wait until the config is received
            sc_join join;
            join.add_process(p_checkConfig);
            join.wait_clocked();

            std::cout << "Configuration done" << std::endl;

            // Now we can use gclk again
            m_checkNoGCLKDuringConfig.suspend();
        }
    }

    void checkConfig() {
        for (int i = 0; i < 48; ++i) wait(sclk.posedge_event());
    }

    void checkNoGCLKDuringConfig() {
        while (true) {
            wait(gclk.posedge_event());
            std::cout << "[ERROR]: GCLK raised and shouldn't be" << std::endl;
        }
    }

    void checkData() {
        while (true) {
            wait();
        }
    }

    void checkDataProtocol() {
        while (true) {
            // Wait for the first WRTGS to occur
            waitLat(sclk, lat, LATCH_WRTGS);

            for (int j = 0; j < 7; ++j) {
                for (int i = 0; i < 7; ++i) {
                    // Wait for the next WRTGS
                    auto latWRTGS = waitLat(sclk, lat);
                    assert(latWRTGS == LATCH_WRTGS);
                }

                auto latLATGS = waitLat(sclk, lat);
                assert(latLATGS == LATCH_LATGS);

                auto latWRTGS = waitLat(sclk, lat);
                assert(latWRTGS == LATCH_WRTGS);
            }

            for (int k = 0; k < 6; ++k) {
                auto latWRTGS = waitLat(sclk, lat);
                assert(latWRTGS == LATCH_WRTGS);
            }

            auto latLINERESET = waitLat(sclk, lat);
            assert(latLINERESET == LATCH_LINERESET);
        }
    }

    void checkTimingRequirementsLat(int nbLatch, sc_time time) {
        while (true) {
            wait(lat.posedge_event());

            sc_event_or_list evtList;
            evtList |= lat.negedge_event();
            evtList |= sclk.posedge_event();

            int latCount = 0;

            while (true) {
                wait(evtList);
                if (lat == 0) {
                    if (latCount != nbLatch) break;
                    auto t = sc_time_stamp();
                    wait(sclk.posedge_event());
                    auto delta = sc_time_stamp() - t;
                    if (delta < sc_time(60, SC_NS)) {
                        // Error
                        std::cout << "[ERROR] LAT(" << nbLatch
                                  << ") doest not meet timing "
                                     "requirements in LAT down and SCLK up"
                                  << std::endl;
                    }
                    // check for next time
                    break;
                }
                latCount += 1;
            }
        }
    }

    void checkThatDataIsReceivedInPokerMode() {
        while (true) {
            // Wait until we get WRTGS
            wait(clk.posedge_event());
        }
    }

    sc_in<bool> nrst;
    sc_in<bool> lat;
    sc_in<uint32_t> sin;
    sc_in<bool> clk;
    sc_in<bool> sclk;
    sc_in<bool> gclk;

    private:
    std::array<sc_signal<bool>, DRIVER_NB> m_sin;
    std::array<std::unique_ptr<Driver>, DRIVER_NB> m_drivers;
    sc_process_handle m_checkNoGCLKDuringConfig;
};

int sc_main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    const sc_time T(15, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulationTime = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk66("clk66", T);
    sc_clock clk33("clk33", 2 * T);
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

    Stimuler stimuler("stimuler");
    stimuler.clk(clk66);
    stimuler.nrst(nrst);
    stimuler.framebufferData(framebufferData);
    stimuler.framebufferSync(framebufferSync);
    stimuler.config(serializedConf);

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

    while (sc_time_stamp() < simulationTime) {
        if (Verilated::gotFinish()) return 1;
        sc_start(T);
    }

    // TODO: should we resync by sending a TGMRST if we receive a
    // famebuffer_sync ?

    sc_close_vcd_trace_file(traceFile);

    return EXIT_SUCCESS;
}
