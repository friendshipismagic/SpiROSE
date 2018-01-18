#include <systemc.h>
#include <verilated.h>
#include <array>
#include <cstdint>
#include <memory>
#include <sstream>

#include "driver.hpp"
#include "driver_cmd.h"

#include "monitor.hpp"

void Monitor::runTests() {
    positionSync = true;
    framebufferData = 0;

    sc_spawn(sc_bind(&Monitor::checkTimingRequirementsLat, this, LATCH_LATGS,
                     sc_time(80, SC_NS)));
    sc_spawn(sc_bind(&Monitor::checkTimingRequirementsLat, this, LATCH_READFC,
                     sc_time(80, SC_NS)));
    sc_spawn(sc_bind(&Monitor::checkTimingRequirementsLat, this,
                     LATCH_LINERESET, sc_time(80, SC_NS)));

    sc_spawn(sc_bind(&Monitor::checkTimingRequirementsLat, this, LATCH_WRTGS,
                     sc_time(20, SC_NS)));
    sc_spawn(sc_bind(&Monitor::checkTimingRequirementsLat, this, LATCH_WRTFC,
                     sc_time(20, SC_NS)));
    sc_spawn(sc_bind(&Monitor::checkTimingRequirementsLat, this, LATCH_TMGRST,
                     sc_time(20, SC_NS)));

    // wait some cycles before sending anything
    wait(200);

    while (true) wait();
}

/*
 * Combinatorial glue logic to convert uint32_t into 30 bool signals
 */
void Monitor::copySinToArray() {
    for (int i = 0; i < DRIVER_NB; ++i) {
        m_sin[i] = sin.read() >> i & 1;
    }
}

void Monitor::checkConfigProtocol() {
    SC_REPORT_INFO("monitor",
                   "starting configuration protocol checker processus");

    SC_REPORT_INFO("monitor", "start waiting for configuration");

    while (true) {
        // Wait until we get FCWRTEN
        // waitLat(sclk, lat, LATCH_FCWRTEN);
        auto latCount = waitLat(sclk, lat);
        if (latCount != LATCH_FCWRTEN) {
            continue;
        }

        SC_REPORT_INFO("lat",
                       "received FCWRTEN, new configuration request from DUT");
        auto p_noGclk =
            sc_spawn(sc_bind(&Monitor::checkNoGCLKDuringConfig, this));

        for (int i = 0; i < 47; ++i) wait(sclk.posedge_event());

        // Start process checking that config is correctly sent
        auto p_checkConfig = sc_spawn(sc_bind(&Monitor::checkConfig, this));
        SC_REPORT_INFO("lat", "Received WRTFG, configuration is done");

        // Now we can use gclk again
        p_noGclk.kill();
        p_noGclk.disable();
    }
}

void Monitor::checkConfig() {
    wait(sclk.posedge_event());
    for (auto& d : m_drivers) {
        auto c = d->getFcData();
        if (c.to_uint64() != config) {
            std::string errorMsg = "Drivers didn't read the config correctly";
            errorMsg += ", wanted " + sc_bv<48>(config.read()).to_string();
            errorMsg += ", got " + c.to_string();
            SC_REPORT_FATAL("config", errorMsg.c_str());
            return;
        }
    }
    SC_REPORT_INFO("config", "Finish configuration process");
}

void Monitor::checkNoGCLKDuringConfig() {
    while (true) {
        wait(gclk.posedge_event());
        SC_REPORT_ERROR("gclk", "GCLK raised during configuration");
        return;
    }
}

void Monitor::checkData() {
    while (true) {
        wait();
    }
}

void Monitor::checkDataProtocol() {
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

void Monitor::checkTimingRequirementsLat(int nbLatch, sc_time timeOff) {
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
                if (delta < timeOff) {
                    SC_REPORT_ERROR(
                        "lat",
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

void Monitor::checkThatLatIsntMovedOnSCLK() {
    sc_event_or_list evtList;
    evtList |= lat.posedge_event();
    evtList |= lat.negedge_event();
    while (true) {
        // Wait any event of lat (rise or fall)
        wait(evtList);
        if (sclk)
            SC_REPORT_ERROR("lat",
                            "SCLK shouldn't be on when LAT is changing state");
    }
}

void Monitor::checkThatLatgsFallDuringTheEndOfASegment() {
    sc_event_or_list evtList;
    evtList |= lat.negedge_event();
    evtList |= gclk.posedge_event();

    SC_REPORT_INFO("gclk", "Starting the LATGS segment check");

    int gclkCounter = 0;
    while (true) {
        int latCounter = 0;
        while (!lat) {
            wait(gclk.posedge_event());
            gclkCounter += 1;
            latCounter += lat;
        }
        while (lat) {
            wait(evtList);
            gclkCounter += gclk;
            latCounter += lat;
        }

        if (latCounter == LATCH_LATGS && gclkCounter != 512) {
            auto error =
                "LATGS should fall down afer 512 GCLK ticks, and it falls "
                "after " +
                std::to_string(gclkCounter);
            SC_REPORT_ERROR("gclk", error.c_str());
            gclkCounter = 0;
        } else if (latCounter == LATCH_LATGS) {
            gclkCounter = 0;
        }
    }
}

void Monitor::checkThatDataIsReceivedInPokerMode() {
    while (true) {
        // Wait until we get WRTGS
        wait(clk.posedge_event());
    }
}

void Monitor::sendPositionSync() {
    positionSync = true;
    wait();
    positionSync = false;
}

void Monitor::checkThatNewConfigurationIsReceived() {
    auto p_latgs =
        sc_spawn(sc_bind(&Monitor::checkThatLatgsFallDuringTheEndOfASegment, this));
    Driver::RegBuff conf;
    std::string confStr = "010111001000001000000001000000000001000";
    std::string revConfStr(confStr.rbegin(), confStr.rend());
    conf = revConfStr.c_str();
    config = conf.to_uint64();
    newConfigurationReady = 0;

    // Wait an arbitrary number of cycles before sending a new configuration
    for(int i = 0; i < 300; ++i)
        wait(clk.posedge_event());

      // Change bright control configuration
    confStr = "010111001000001000000001000000000101000";
    revConfStr.assign(confStr.rbegin(), confStr.rend());
    conf = revConfStr.c_str();
    config = conf.to_uint64();

    newConfigurationReady = 1;
    wait(clk.posedge_event());
    newConfigurationReady = 0;

    // reset the latgs check
    p_latgs.reset();

    // Check that FCWRTEN command is sent
    auto latCount = waitLat(sclk, lat);
    if (latCount != LATCH_FCWRTEN) {
        SC_REPORT_FATAL("config","The new config is not sent");
    }
}
