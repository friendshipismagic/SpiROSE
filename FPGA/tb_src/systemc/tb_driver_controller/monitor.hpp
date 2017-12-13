#pragma once

#include <systemc.h>
#include <verilated.h>
#include <array>
#include <cstdint>
#include <memory>
#include <sstream>

#include "driver.hpp"
#include "driver_cmd.h"

#include "lathandler.hpp"

struct Monitor : public LatHandler {
    static constexpr int DRIVER_NB = 30;
    SC_CTOR(Monitor)
        : sin("sin"), lat("lat"), gclk("gclk"), sclk("sclk"), nrst("nrst") {
        SC_CTHREAD(runTests, clk.pos());

        SC_THREAD(checkConfigProtocol);

        SC_METHOD(copySinToArray);
        sensitive << sin;

        SC_THREAD(checkThatLatIsntMovedOnSCLK);

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
                         LATCH_LATGS, sc_time(80, SC_NS)));
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
        SC_REPORT_INFO("monitor",
                       "starting configuration protocol checker processus");

        m_checkNoGCLKDuringConfig =
            sc_spawn(sc_bind(&Monitor::checkNoGCLKDuringConfig, this));
        m_checkNoGCLKDuringConfig.suspend();

        SC_REPORT_INFO("monitor", "start waiting for configuration");

        while (true) {
            // Wait until we get FCWRTEN
            // waitLat(sclk, lat, LATCH_FCWRTEN);
            auto latCount = waitLat(sclk, lat);
            if (latCount != LATCH_FCWRTEN) {
                continue;
            }

            SC_REPORT_INFO(
                "LAT", "received FCWRTEN, new configuration request from DUT");

            // Start process checking that config is correctly sent
            auto p_checkConfig = sc_spawn(sc_bind(&Monitor::checkConfig, this));

            // Start process checking that gclk is not started
            m_checkNoGCLKDuringConfig.resume();

            // Wait until the config is received
            sc_join join;
            join.add_process(p_checkConfig);
            join.wait_clocked();

            SC_REPORT_INFO("LAT", "Received WRTFG, configuration is done");

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
            SC_REPORT_ERROR("GCLK", "GCLK raised during configuration");
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
                    sc_assert(latWRTGS == LATCH_WRTGS);
                }

                auto latLATGS = waitLat(sclk, lat);
                sc_assert(latLATGS == LATCH_LATGS);

                auto latWRTGS = waitLat(sclk, lat);
                sc_assert(latWRTGS == LATCH_WRTGS);
            }

            for (int k = 0; k < 6; ++k) {
                auto latWRTGS = waitLat(sclk, lat);
                sc_assert(latWRTGS == LATCH_WRTGS);
            }

            auto latLINERESET = waitLat(sclk, lat);
            sc_assert(latLINERESET == LATCH_LINERESET);
        }
    }

    void checkTimingRequirementsLat(int nbLatch, sc_time timeOff) {
        while (true) {
            wait(lat.posedge_event());
            SC_REPORT_INFO(
                "LAT",
                ("LAT raised at " + sc_time_stamp().to_string()).c_str());

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
                    if (delta < timeOff) {
                        SC_REPORT_ERROR(
                            "timings",
                            ("LAT(" + std::to_string(nbLatch) +
                             ") doest not meet timing " +
                             "requirements in LAT down and SCLK up\n it took " +
                             delta.to_string() + " instead of " +
                             timeOff.to_string())
                                .c_str());
                    }
                    // check for next time
                    break;
                }
                latCount += 1;
            }
        }
    }

    void checkThatLatIsntMovedOnSCLK() {
        sc_event_or_list evtList;
        evtList |= lat.posedge_event();
        evtList |= lat.negedge_event();
        while (true) {
            // Wait any event of lat (rise or fall)
            wait(evtList);
            if (sclk)
                SC_REPORT_ERROR(
                    "LAT", "SCLK shouldn't be on when LAT is changing state");
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
