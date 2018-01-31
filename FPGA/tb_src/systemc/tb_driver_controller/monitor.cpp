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

    while (true) {
        wait();
        if (startConfig == 1) {
            sc_spawn(
                sc_bind(&Monitor::checkThatDataIsReceivedInPokerMode, this));
        }
        /*
         * After the last configuration is processed, send framebufferData to be
         * tested Send only data for the first 5 poker sequences to meet the
         * system configuration, pad with 0 everywhere else.
         */
        while (1) {
            int sequenceCount;
            // if (driverReady == 0) {
            //    if (sequenceCount == 8) {
            //        sequenceCount = 9;
            //        // Wait until the next 9 sequences need to be sent
            //        wait(driverReady.posedge_event());
            //        sequenceCount = 0;
            //    } else {
            //        sequenceCount++;
            //    }
            //} else {
            //    // Data is sent when driverReady is high and only on the first
            //    5
            //    // sequences
            //    if (sequenceCount == 0 || sequenceCount == 1 ||
            //        sequenceCount == 2 || sequenceCount == 3 ||
            //        sequenceCount == 4) {
            //        // TODO: generate RAND data rand();
            //    } else {
            //        // TODO: stop data
            //    }
            //}
            wait();
        }
    }
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

        for (int i = 0; i < 48; ++i) wait(sclk.posedge_event());

        // Start process checking that config is correctly sent
        auto p_checkConfig = sc_spawn(sc_bind(&Monitor::checkConfig, this));
        SC_REPORT_INFO("lat", "Received WRTFG, configuration is done");

        // Now we can use gclk again
        p_noGclk.kill();
        p_noGclk.disable();
    }
}

void Monitor::checkConfig() {
    /*
     * Wait on clk because there is no reason for sclk to
     * exist before a new configuration is sent
     */
    wait(clk.posedge_event());
    wait(clk.posedge_event());
    for (auto& d : m_drivers) {
        auto c = d->getFcData();
        if (c.to_uint64() != configData) {
            std::string errorMsg = "Drivers didn't read the config correctly";
            errorMsg += ", wanted " + sc_bv<48>(configData.read()).to_string();
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

/*
 * Check that sin is the same as the output
 * of the framebuffer when driver_ready is high
 */
void Monitor::checkData() {
    // while (true) {
    //     wait(sclk.posedge_event());
    //     if (driverReady) {
    //         int maskedData = framebufferData & 0x3fffffff;
    //         if (maskedData != sin) {
    //             cout << maskedData << "  ...  " << sin << endl;
    //             std::string msg = "The output of the framebuffer is not
    //             copied "
    //                 "properly to sin when driver_ready is high, expected ";
    //             msg += sc_bv<30>(framebufferData.read()).to_string();
    //             msg += ", got ";
    //             msg += sc_bv<30>(sin.read()).to_string();
    //             SC_REPORT_ERROR("data", msg.c_str());
    //             return;
    //         }
    //     }
    // }
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
        // Count LAT to find LAT type
        int latCounter = 0;
        sc_spawn([this, &latCounter]() {
            wait(sclk.posedge_event());
            latCounter += lat;
        });

        // Count GCLK, shouldn't be more than 512
        int gclkCounter = 0;
        sc_spawn([this, &gclkCounter]() {
            while (gclkCounter <= 511) {
                wait(gclk.posedge_event());
                gclkCounter++;
            }
        });

        sc_event_or_list evtList;
        evtList |= lat.negedge_event();

        wait(evtList);

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
    // Keeps track of the index of the sequence (out of 9) that is received
    int segmentCount = 0;

    while (true) {
        wait(sclk.posedge_event());
        // if (driverReady == 0) {
        //    if (segmentCount == 8) {
        //        segmentCount = 9;
        //        wait(driverReady.posedge_event());
        //        segmentCount = 0;
        //    } else {
        //        segmentCount++;
        //    }
        //} else {
        //    if (segmentCount == 5 || segmentCount == 6 || segmentCount == 7 ||
        //        segmentCount == 8) {
        //        // Check that output data is equal to zero when no relevant
        //        data
        //        // is set
        //        if (sin != 0) {
        //            SC_REPORT_ERROR("poker mode",
        //                            "SIN should be 0 because"
        //                            " 4 last sequences should be 0.");
        //            return;
        //        }
        //    }
        //}
    }
}

void Monitor::sendPositionSync() {
    // positionSync = true;
    wait();
    // positionSync = false;
}

void Monitor::checkThatNewConfigurationIsReceived() {
    auto p_latgs = sc_spawn(
        sc_bind(&Monitor::checkThatLatgsFallDuringTheEndOfASegment, this));
    Driver::RegBuff conf;
    // This is the default config used after the driver_controller is reset
    std::string confStr = "101011011000000000000010000000010000000010001000";
    std::string revConfStr(confStr.rbegin(), confStr.rend());
    conf = revConfStr.c_str();
    configData = conf.to_uint64();
    startConfig = 0;

    // Wait an arbitrary number of cycles before sending a new configuration
    for (int i = 0; i < 300; ++i) wait(clk.posedge_event());

    // Change bright control configuration
    confStr = "010111001000001000000001000000000101000";
    revConfStr.assign(confStr.rbegin(), confStr.rend());
    conf = revConfStr.c_str();
    configData = conf.to_uint64();

    startConfig = 1;
    wait(clk.posedge_event());
    startConfig = 0;

    // reset the latgs check
    p_latgs.reset();

    // Check that FCWRTEN command is sent
    auto latCount = waitLat(sclk, lat);
    // Wait for a LAT segment again because of the TMGRST LAT segment
    latCount = waitLat(sclk, lat);
    if (latCount != LATCH_FCWRTEN) {
        SC_REPORT_FATAL("config", "The new config is not sent");
    }
}
