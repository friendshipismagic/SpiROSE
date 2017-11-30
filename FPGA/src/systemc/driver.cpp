#include "driver.hpp"

#include <iostream>

sc_bv<2> Driver::get_lodth() const { return fc_data.read()(1, 0); }

sc_bv<2> Driver::get_td0() const { return fc_data.read()(3, 2); }

bool Driver::get_group() const { return fc_data.read().bit(4).to_bool(); }

bool Driver::get_xrefresh() const { return fc_data.read().bit(5).to_bool(); }

bool Driver::get_sel_gck_edge() const {
    return fc_data.read().bit(6).to_bool();
}

bool Driver::get_sel_pchg() const { return fc_data.read().bit(7).to_bool(); }

bool Driver::get_espwm() const { return fc_data.read().bit(8).to_bool(); }

bool Driver::get_lgse3() const { return fc_data.read().bit(9).to_bool(); }

bool Driver::get_sel_sck_edge() const {
    return fc_data.read().bit(10).to_bool();
}

sc_bv<3> Driver::get_lgse1() const { return fc_data.read()(13, 11); }

sc_bv<9> Driver::get_ccb() const { return fc_data.read()(22, 14); }

sc_bv<9> Driver::get_ccg() const { return fc_data.read()(31, 23); }

sc_bv<9> Driver::get_ccr() const { return fc_data.read()(40, 32); }

sc_bv<3> Driver::get_bc() const { return fc_data.read()(43, 41); }

bool Driver::get_poker_mode() const { return fc_data.read().bit(44).to_bool(); }

sc_bv<3> Driver::get_lgse2() const { return fc_data.read()(47, 45); }

void Driver::check_assert() {
    while (true) {
        // Can't use XREFRESH and ESPWM in poker mode, p17, 3.4.3
        if (get_poker_mode() && (get_xrefresh() || get_espwm())) {
            std::cout << "FATAL: XREFRESH(" << get_xrefresh() << ") "
                      << "and ESPWM(" << get_espwm() << ") "
                      << "have to be 0 in poker mode" << std::endl;
            exit(-1);
        }
        wait();
    }
}

void Driver::handle_sin() {
    while (true) {
        wait();
        shift_reg = ((shift_reg.read() << 1) & ~1) | sin;
    }
}

void Driver::handle_lat() {
    gs_addr_counter = GS_ADDR_COUNTER_ORIGIN;

    while (true) {
        wait();
        if (lat) {
            lat_counter = lat_counter.read() + 1;
        } else if (lat_counter == 1) {
            // WRTGS, write to GS data at the GS counter position
            write_to_bank(GS1, gs_addr_counter.read(), shift_reg);
            gs_addr_counter = gs_addr_counter.read() - 1;
            lat_counter = 0;
        } else if (lat_counter == 3) {
            // LATGS, write to GS data
            write_to_bank(GS1, gs_addr_counter.read(), shift_reg);
            if (get_xrefresh() == 0) {
                // latch GS1 to GS2 when gs_addr_counter = 65536
                if (gs_addr_counter == 0) {
                    gs2_data = gs1_data;
                }
            } else {
                // latch GS1 to GS2
                // reset gs_addr_counter (right after the else)
                // TODO: put outx = 0 if we need to test it
                gs2_data = gs1_data;
            }
            gs_addr_counter = GS_ADDR_COUNTER_ORIGIN;
            line_counter = line_counter.read() + 1;
            lat_counter = 0;
        } else if (lat_counter == 5) {
            // WRTFC
            fc_data = shift_reg;
            lat_counter = 0;
        } else if (lat_counter == 7) {
            // LINERESET
            write_to_bank(GS1, gs_addr_counter.read(), shift_reg);
            line_counter = 0;
            gs_addr_counter = GS_ADDR_COUNTER_ORIGIN;
            if (get_xrefresh() == 0) {
                // TODO: copy everything when GS counter is 65536;
            } else {
                gs2_data.write(gs1_data);
                gs_data_counter = 0;
                // TODO: OUTx forced off
            }
            lat_counter = 0;
        } else if (lat_counter == 11) {
            // READFC
            // It's the following line, but we can't do it because it is driven
            // TODO: handle_sout using either fc_data or shift_reg (later)
            // by handle_sin shift_reg.write(fc_data);
            lat_counter = 0;
        } else if (lat_counter == 13) {
            // TMGRST
            gs_data_counter = 0;
            line_counter = 0;
            // TODO: force output off if we need to test it
            lat_counter = 0;
        } else if (lat_counter == 15) {
            // FCWRTEN, enable to write to FC data latch
            current_mode = MODE_FCWRT;
            lat_counter = 0;
        } else {
            assert(lat_counter == 0 && "Invalid lat counter value");
        }
    }
}

void Driver::handle_gclk() {
    if (get_xrefresh() == 0) {
        // auto-refresh is enabled, so we automatically latch in the end
        std::cout << "xrefresh is activated and shouldn't be" << std::endl;
    } else {
        // auto-refresh is disabled, we shut everything off as soon as we reach
        // the end of the counter
        gs_data_counter = gs_data_counter.read() + 1;
    }
}

void Driver::write_to_bank(driver_bank_t bank, int buffer_id,
                           const RegBuff& buffer) {
    auto& gs = (bank == GS1) ? gs1_data : gs2_data;
    auto vec = gs.read();
    if (!get_poker_mode()) {
        // Calculate the slice where to write in GS
        int end = REG_SIZE * (1 + buffer_id) - 1;

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
                auto idx = i * REG_SIZE - (GS_NB_BUFFER - buffer_id) - j * 16;
                vec[idx] = buffer[i];
            }
        }
    }
    gs.write(vec);
}

Driver::GSBuff Driver::get_gs1_data() const { return gs1_data.read(); }
Driver::GSBuff Driver::get_gs2_data() const { return gs2_data.read(); }
Driver::RegBuff Driver::get_fc_data() const { return fc_data.read(); }
