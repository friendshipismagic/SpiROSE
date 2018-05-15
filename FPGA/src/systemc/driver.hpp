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

// From the TCL5957 application note
// external : http://www.ti.com/lit/ug/slvuaf0/slvuaf0.pdf
// internal :
// https://gitlab.telecom-paristech.fr/ROSE/2018/SpiROSE/blob/master/docs/datasheets/slvuaf0.pdf

constexpr auto GS_ADDR_COUNTER_ORIGIN = 15;
constexpr auto LINE_COUNTER_ORIGIN = 0;

class Driver : public sc_module {
    SC_HAS_PROCESS(Driver);

    enum driver_mode_t { MODE_DATA, MODE_FCWRT };
    enum driver_bank_t { GS1, GS2 };

    public:
    static constexpr auto REG_SIZE = 48;
    static constexpr auto GS_SIZE = 768;
    static constexpr auto GS_NB_BUFFER = 16;
    static constexpr auto GS_NB_COLOR = 3;

    using GSBuff = sc_bv<GS_SIZE>;
    using RegBuff = sc_bv<REG_SIZE>;

    inline Driver(const sc_module_name& name)
        : sc_module(name), gclk("gclk"), sclk("sclk"), sin("sin"), lat("lat") {
        SC_CTHREAD(handleSin, sclk);
        SC_THREAD(handleLat);
        sensitive << sclk.pos() << lat.neg();
        SC_CTHREAD(checkAssert, sclk);
        SC_CTHREAD(handleGclk, gclk);
    }

    /* Driver state getters */

    sc_bv<2> getLodth() const;

    sc_bv<2> getTd0() const;

    bool getGroup() const;

    bool getXrefreshDisabled() const;

    bool getSelGckEdge() const;

    bool getSelPchg() const;

    bool getEspwm() const;

    bool getLgse3() const;

    bool getSelSckEdge() const;

    sc_bv<3> getLgse1() const;

    sc_bv<9> getCcb() const;

    sc_bv<9> getCcg() const;

    sc_bv<9> getCcr() const;

    sc_bv<3> getBc() const;

    bool getPokerMode() const;

    sc_bv<3> getLgse2() const;

    GSBuff getGs1Data() const;

    GSBuff getGs2Data() const;

    RegBuff getFcData() const;

    /* SystemC processes */

    void handleSin();

    void handleLat();

    void handleGclk();

    void checkAssert();

    /* SystemC public signals */

    sc_in<bool> gclk;
    sc_in<bool> sclk;
    sc_in<bool> nrst;
    sc_in<bool> sin;
    sc_in<bool> lat;

    static void displayBank(const GSBuff& bank);

    static void displayReg(const RegBuff& buffer);

    private:
    void updateBank(Driver::GSBuff& bank, int bufferId, const RegBuff& buffer);

    void executeLat(int latCount);

    /* Driver internal state */

    sc_signal<RegBuff> shiftReg;
    sc_signal<RegBuff> fcData;
    sc_signal<GSBuff> gs1Data;
    sc_signal<GSBuff> gs2Data;

    sc_signal<int> latCounter;
    sc_signal<int> gsAddrCounter;
    sc_signal<int> gsDataCounter;
    sc_signal<int> lineCounter;
    sc_signal<driver_mode_t> currentMode;
};
