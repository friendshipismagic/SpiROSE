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

#include "driver.hpp"

#include <iostream>
#include <sstream>

sc_bv<2> Driver::getLodth() const { return fcData.read()(1, 0); }

sc_bv<2> Driver::getTd0() const { return fcData.read()(3, 2); }

bool Driver::getGroup() const { return fcData.read().bit(4).to_bool(); }

bool Driver::getXrefreshDisabled() const {
    return fcData.read().bit(5).to_bool();
}

bool Driver::getSelGckEdge() const { return fcData.read().bit(6).to_bool(); }

bool Driver::getSelPchg() const { return fcData.read().bit(7).to_bool(); }

bool Driver::getEspwm() const { return fcData.read().bit(8).to_bool(); }

bool Driver::getLgse3() const { return fcData.read().bit(9).to_bool(); }

bool Driver::getSelSckEdge() const { return fcData.read().bit(10).to_bool(); }

sc_bv<3> Driver::getLgse1() const { return fcData.read()(13, 11); }

sc_bv<9> Driver::getCcb() const { return fcData.read()(22, 14); }

sc_bv<9> Driver::getCcg() const { return fcData.read()(31, 23); }

sc_bv<9> Driver::getCcr() const { return fcData.read()(40, 32); }

sc_bv<3> Driver::getBc() const { return fcData.read()(43, 41); }

bool Driver::getPokerMode() const { return fcData.read().bit(44).to_bool(); }

sc_bv<3> Driver::getLgse2() const { return fcData.read()(47, 45); }

void Driver::checkAssert() {
    while (true) {
        // Can't use XREFRESH and ESPWM in poker mode, p17, 3.4.3
        if (getPokerMode() && (!getXrefreshDisabled() || !getEspwm())) {
            std::ostringstream stream;
            stream << "FATAL: XREFRESH(" << getXrefreshDisabled() << ") "
                   << "and ESPWM(" << getEspwm() << ") "
                   << "have to be 1 (deactivated) in poker mode";
            SC_REPORT_ERROR("driver", stream.str().c_str());
            return;
        }
        wait();
    }
}

void Driver::handleSin() {
    while (true) {
        wait();
        shiftReg = ((shiftReg.read() << 1) & ~1) | sin;
    }
}

void Driver::handleLat() {
    gsAddrCounter = GS_ADDR_COUNTER_ORIGIN;

    while (true) {
        if (lat) {
            latCounter = latCounter.read() + 1;
        } else {
            executeLat(latCounter);
            latCounter = 0;
        }

        wait();
    }
}

void Driver::handleGclk() {
    if (getXrefreshDisabled() == 0) {
        // auto-refresh is enabled, so we automatically latch in the end
        std::cout << "xrefresh is activated and shouldn't be" << std::endl;
    } else {
        // auto-refresh is disabled, we shut everything off as soon as we reach
        // the end of the counter
        gsDataCounter = gsDataCounter.read() + 1;
    }
}

void Driver::updateBank(Driver::GSBuff& bank, int bufferId,
                        const RegBuff& buffer) {
    if (!getPokerMode()) {
        // Calculate the slice where to write in GS
        int end = REG_SIZE * (1 + bufferId) - 1;

        // We need to extract the data from signal to apply range
        // operator
        bank(end, end - REG_SIZE + 1) = buffer(REG_SIZE - 1, 0);
    } else {
        // i is the buffer iterator from end to start
        for (int i = GS_NB_BUFFER + 1; i > 0; --i) {
            // j is the current color of the pixel
            for (int j = 0; j < GS_NB_COLOR; ++j) {
                // + in this context, buffer_id is the bit number of the poker
                // mode.
                // + i*48 gives the buffer of 48 bits in which we must write
                // 16 - buffer_id will reverse the bit order so that we write
                // the MSB first
                // + the 48 bits buffer is splitted into three 16 bits parts,
                // one for each color, so j*16 translates to the right buffer
                auto idx = i * REG_SIZE - (GS_NB_BUFFER - bufferId) - j * 16;
                bank[idx] = buffer[i * 3 - j - 1];
            }
        }
    }
}

Driver::GSBuff Driver::getGs1Data() const { return gs1Data.read(); }
Driver::GSBuff Driver::getGs2Data() const { return gs2Data.read(); }
Driver::RegBuff Driver::getFcData() const { return fcData.read(); }

void Driver::displayBank(const Driver::GSBuff& bank) {
    for (int i = 0; i < GS_NB_BUFFER; ++i) {
        for (int j = 0; j < 3; ++j)
            std::cout << bank(767 - REG_SIZE * i - j * 16,
                              768 - REG_SIZE * i - (j + 1) * 16)
                      << " ";
        std::cout << std::endl;
    }
}

void Driver::displayReg(const Driver::RegBuff& buffer) {
    for (int i = 0; i < 3; ++i) {
        std::cout << buffer(47 - i * 16, 48 - (i + 1) * 16) << " ";
    }
    std::cout << std::endl;
}

void Driver::executeLat(int latCount) {
    if (latCount == 1) {
        // WRTGS, write to GS data at the GS counter position
        auto bank = gs1Data.read();
        updateBank(bank, gsAddrCounter.read(), shiftReg);
        gs1Data.write(bank);
        gsAddrCounter = gsAddrCounter.read() - 1;
    } else if (latCount == 3) {
        // LATGS, write to GS data
        auto bank = gs1Data.read();
        updateBank(bank, gsAddrCounter.read(), shiftReg);
        gs1Data.write(bank);

        // We will be using poker mode so no need to support Xrefresh
        assert(getXrefreshDisabled());

        if (getXrefreshDisabled() == 0) {
            // TODO: we do not handle Xrefresh mode, not used
        } else {
            // latch GS1 to GS2
            // reset gsAddrCounter (right after the else)
            // TODO: put outx = 0 if we need to test it
            gs2Data.write(bank);
        }
        gsAddrCounter = GS_ADDR_COUNTER_ORIGIN;
        lineCounter = lineCounter.read() + 1;
    } else if (latCount == 5) {
        // WRTFC
        fcData = shiftReg;
        gsAddrCounter = GS_ADDR_COUNTER_ORIGIN;
    } else if (latCount == 7) {
        // LINERESET
        auto bank = gs1Data.read();
        updateBank(bank, gsAddrCounter.read(), shiftReg);
        gs2Data.write(bank);
        gs1Data.write(bank);
        lineCounter = 0;
        gsAddrCounter = GS_ADDR_COUNTER_ORIGIN;

        // We will be using poker mode so no need to support Xrefresh
        assert(getXrefreshDisabled());

        if (getXrefreshDisabled() == 0) {
            // TODO: we do not handle Xrefresh mode, not used
            // TODO: copy everything when GS counter is 65536;
        } else {
            gs2Data.write(gs1Data);
            gsDataCounter = 0;
            // TODO: OUTx forced off
        }
    } else if (latCount == 11) {
        // READFC
        // It's the following line, but we can't do it because it is
        // driven
        // TODO: handle_sout using either fcData or shift_reg (later)
        // by handle_sin shift_reg.write(fcData);
    } else if (latCount == 13) {
        // TMGRST
        gsAddrCounter = GS_ADDR_COUNTER_ORIGIN;
        gsDataCounter = 0;
        lineCounter = 0;
        // TODO: force output off if we need to test it
    } else if (latCount == 15) {
        // FCWRTEN, enable to write to FC data latch
        currentMode = MODE_FCWRT;
    } else {
        if (latCount != 0)
            SC_REPORT_ERROR(
                "LAT", (std::to_string(latCount) + " is an invalid lat value")
                           .c_str());
    }
}
