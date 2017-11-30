#include "driver.hpp"

#include <iostream>

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
        if (getPokerMode() && (getXrefreshDisabled() || getEspwm())) {
            std::cout << "FATAL: XREFRESH(" << getXrefreshDisabled() << ") "
                      << "and ESPWM(" << getEspwm() << ") "
                      << "have to be 0 (deactivated) in poker mode"
                      << std::endl;
            exit(-1);
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
        wait();
        if (lat) {
            latCounter = latCounter.read() + 1;
        } else if (latCounter == 1) {
            // WRTGS, write to GS data at the GS counter position
            writeToBank(GS1, gsAddrCounter.read(), shiftReg);
            gsAddrCounter = gsAddrCounter.read() - 1;
            latCounter = 0;
        } else if (latCounter == 3) {
            // LATGS, write to GS data
            writeToBank(GS1, gsAddrCounter.read(), shiftReg);
            if (getXrefreshDisabled() == 0) {
                // latch GS1 to GS2 when gs_addr_counter = 65536
                if (gsAddrCounter == 0) {
                    gs2Data = gs1Data;
                }
            } else {
                // latch GS1 to GS2
                // reset gs_addr_counter (right after the else)
                // TODO: put outx = 0 if we need to test it
                gs2Data = gs1Data;
            }
            gsAddrCounter = GS_ADDR_COUNTER_ORIGIN;
            lineCounter = lineCounter.read() + 1;
            latCounter = 0;
        } else if (latCounter == 5) {
            // WRTFC
            fcData = shiftReg;
            latCounter = 0;
        } else if (latCounter == 7) {
            // LINERESET
            writeToBank(GS1, gsAddrCounter.read(), shiftReg);
            lineCounter = 0;
            gsAddrCounter = GS_ADDR_COUNTER_ORIGIN;
            if (getXrefreshDisabled() == 0) {
                // TODO: copy everything when GS counter is 65536;
            } else {
                gs2Data.write(gs1Data);
                gsDataCounter = 0;
                // TODO: OUTx forced off
            }
            latCounter = 0;
        } else if (latCounter == 11) {
            // READFC
            // It's the following line, but we can't do it because it is driven
            // TODO: handle_sout using either fcData or shift_reg (later)
            // by handle_sin shift_reg.write(fcData);
            latCounter = 0;
        } else if (latCounter == 13) {
            // TMGRST
            gsDataCounter = 0;
            lineCounter = 0;
            // TODO: force output off if we need to test it
            latCounter = 0;
        } else if (latCounter == 15) {
            // FCWRTEN, enable to write to FC data latch
            currentMode = MODE_FCWRT;
            latCounter = 0;
        } else {
            assert(latCounter == 0 && "Invalid lat counter value");
        }
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

void Driver::writeToBank(driver_bank_t bank, int bufferId,
                         const RegBuff& buffer) {
    auto& gs = (bank == GS1) ? gs1Data : gs2Data;
    auto vec = gs.read();
    if (!getPokerMode()) {
        // Calculate the slice where to write in GS
        int end = REG_SIZE * (1 + bufferId) - 1;

        // We need to extract the data from signal to apply range
        // operator
        vec(end, end - REG_SIZE + 1) = buffer(REG_SIZE - 1, 0);
    } else {
        // i is the buffer iterator from end to start
        for (int i = GS_NB_BUFFER; i > 0; --i) {
            // j is the current color of the pixel
            for (int j = 0; j < GS_NB_COLOR; ++i) {
                // + in this context, buffer_id is the bit number of the poker
                // mode.
                // + i*48 gives the buffer of 48 bits in which we must write
                // 16 - buffer_id will reverse the bit order so that we write
                // the MSB first
                // + the 48 bits buffer is splitted into three 16 bits parts,
                // one for each color, so j*16 translates to the right buffer
                auto idx = i * REG_SIZE - (GS_NB_BUFFER - bufferId) - j * 16;
                vec[idx] = buffer[i];
            }
        }
    }
    gs.write(vec);
}

Driver::GSBuff Driver::getGs1Data() const { return gs1Data.read(); }
Driver::GSBuff Driver::getGs2Data() const { return gs2Data.read(); }
Driver::RegBuff Driver::getFcData() const { return fcData.read(); }
