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
        if (get_poker_mode() && (!get_xrefresh() || !get_espwm())) {
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
                // reset gs_addr_counter
                // TODO: outx = 0
                gs2_data = gs1_data;
            }
            gs_addr_counter = GS_ADDR_COUNTER_ORIGIN;
            line_counter = line_counter.read() + 1;
        } else if (lat_counter == 5) {
            // WRTFC
            fc_data = shift_reg;
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
        } else if (lat_counter == 11) {
            // READFC
            // It's the following line, but we can't do it because it is driven
            // TODO: write an handle_sout using either fc_data or shift_reg
            // by handle_sin shift_reg.write(fc_data);
        } else if (lat_counter == 13) {
            // TMGRST
            gs_data_counter = 0;
            line_counter = 0;
            // TODO: force output off
        } else if (lat_counter == 15) {
            // FCWRTEN, enable to write to FC data latch
            current_mode = MODE_FCWRT;
        }
    }
}

void Driver::write_to_bank(driver_bank_t bank, int buffer_id,
                           const sc_bv<48>& buffer) {
    auto& gs = (bank == GS1) ? gs1_data : gs2_data;
    auto vec = gs.read();
    if (!get_poker_mode()) {
        // Calculate the slice where to write in GS
        int end = 48 * (1 + buffer_id) - 1;

        // We need to extract the data from signal to apply range
        // operator
        vec(end, end - 47) = buffer(47, 0);
    } else {
        // i is the buffer iterator from end to start
        for (int i = 16; i >= 0; --i) {
            // j is the current color of the pixel
            for (int j = 0; j < 3; ++i) {
                vec[i * 48 - (16 - buffer_id) - j * 16] = buffer[i];
            }
        }
    }
    gs.write(vec);
}
