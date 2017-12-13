#pragma once

#include <systemc.h>
#include <cstdint>
#include <memory>
#include <sstream>

#include "driver_cmd.h"
#include "lathandler.hpp"

struct Stimuler : public sc_module {
    static constexpr int DRIVER_NB = 30;
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
