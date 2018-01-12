#pragma once

#include <systemc.h>
#include <verilated.h>
#include <array>
#include <cstdint>
#include <memory>
#include <sstream>

#include "driver.hpp"

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

        SC_THREAD(checkThatLatgsFallDuringTheEndOfASegment);

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

    void runTests();

    /*
     * Combinatorial glue logic to convert uint32_t into 30 bool signals
     */
    void copySinToArray();

    void checkConfigProtocol();

    void checkConfig();

    void checkNoGCLKDuringConfig();

    void checkData();

    void checkDataProtocol();

    void checkTimingRequirementsLat(int nbLatch, sc_time timeOff);

    void checkThatLatIsntMovedOnSCLK();

    void checkThatLatgsFallDuringTheEndOfASegment();

    void checkThatDataIsReceivedInPokerMode();

    sc_out<bool> nrst;
    sc_in<bool> lat;
    sc_in<uint32_t> sin;
    sc_in<bool> clk;
    sc_in<bool> sclk;
    sc_in<bool> gclk;
    sc_out<uint64_t> config;
    sc_out<uint32_t> framebufferData;
    sc_out<bool> positionSync;
    sc_in<bool> columnReady;
    sc_in<bool> driverReady;

    private:
    void sendReset();

    void sendPositionSync();

    void setConfig(Driver::RegBuff conf);

    std::array<sc_signal<bool>, DRIVER_NB> m_sin;
    std::array<std::unique_ptr<Driver>, DRIVER_NB> m_drivers;
};
