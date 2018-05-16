//
// Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément Decoodt,
// Alexandre Janniaux, Adrien Marcenat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

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
        SC_THREAD(runTests);
        sensitive << clk.pos();

        SC_THREAD(checkConfigProtocol);

        SC_METHOD(copySinToArray);
        sensitive << sin;

        SC_THREAD(checkThatNewConfigurationIsReceived);

        SC_THREAD(checkThatLatIsntMovedOnSCLK);

        SC_THREAD(checkData);

        SC_THREAD(checkThatDataIsReceivedInPokerMode);

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

    void checkThatNewConfigurationIsReceived();

    sc_out<bool> nrst;
    sc_in<bool> lat;
    sc_in<uint32_t> sin;
    sc_in<bool> clk;
    sc_in<bool> sclk;
    sc_in<bool> gclk;
    sc_out<uint64_t> configData;
    sc_out<bool> sof;
    sc_in<bool> eoc;
    sc_out<bool> startConfig;
    sc_in<bool> endConfig;

    sc_in<sc_bv<432>> data[15];

    private:
    void sendPositionSync();

    void setConfig(Driver::RegBuff conf);

    std::array<sc_signal<bool>, DRIVER_NB> m_sin;
    std::array<std::unique_ptr<Driver>, DRIVER_NB> m_drivers;
};
