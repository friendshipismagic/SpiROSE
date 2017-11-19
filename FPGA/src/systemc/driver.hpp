#pragma once

#include <systemc.h>

class Driver : public sc_module {
    SC_HAS_PROCESS(Driver);

    enum driver_mode_t { MODE_DATA, MODE_FCWRT };

    public:
    inline Driver(const sc_module_name& name)
        : sc_module(name), gclk("gclk"), sclk("sclk"), sin("sin"), lat("lat") {
        SC_CTHREAD(handle_sin, gclk);
        SC_CTHREAD(handle_lat, gclk);
    }

    sc_bv<2> get_lodth() const { return fc_data.read()(1, 0); }

    sc_bv<2> get_td0() const { return fc_data.read()(3, 2); }

    auto get_group() const { return fc_data.read().bit(4); }

    auto get_xrefresh() const { return fc_data.read().bit(5); }

    auto get_sel_gck_edge() const { return fc_data.read().bit(6); }

    auto get_sel_pchg() const { return fc_data.read().bit(7); }

    auto get_espwm() const { return fc_data.read().bit(8); }

    auto get_lgse3() const { return fc_data.read().bit(9); }

    auto get_sel_sck_edge() const { return fc_data.read().bit(10); }

    sc_bv<3> get_lgse1() const { return fc_data.read()(13, 11); }

    sc_bv<9> get_ccb() const { return fc_data.read()(22, 14); }

    sc_bv<9> get_ccg() const { return fc_data.read()(31, 23); }

    sc_bv<9> get_ccr() const { return fc_data.read()(40, 32); }

    sc_bv<3> get_bc() const { return fc_data.read()(43, 41); }

    auto get_poker_mode() const { return fc_data.read().bit(44); }

    sc_bv<3> get_lgse2() const { return fc_data.read()(47, 45); }

    void handle_sin() {
        while (true) {
            wait();
            shift_reg = ((shift_reg.read() << 1) & ~1) | sin;
        }
    }

    void handle_lat() {
        while (true) {
            wait();
            if (lat) {
                lat_counter = lat_counter.read() + 1;
            } else if (lat_counter == 1) {
                // WRTGS, write to GS data at the GS counter position

                // Calculate the slice where to write in GS
                int end = 48 * (1 + gs_counter.read()) - 1;

                // We need to extract the data from signal to apply range
                // operator
                auto vec = gs1_data.read();
                vec(end, end - 47) = shift_reg.read()(47, 0);

                gs1_data.write(vec);
            } else if (lat_counter == 3) {
                // LATGS, write to GS data and latch GS1 to GS2
            } else if (lat_counter == 5) {
                // WRTFC
            } else if (lat_counter == 15) {
                // FCWRTEN, enable to write to FC data latch
                current_mode = MODE_FCWRT;
            }
        }
    }

    sc_in<bool> gclk;
    sc_in<bool> sclk;
    sc_in<bool> nrst;

    sc_in<bool> sin;
    sc_in<bool> lat;

    private:
    sc_signal<sc_bv<48>> shift_reg;
    sc_signal<sc_bv<48>> fc_data;
    sc_signal<sc_bv<768>> gs1_data;
    sc_signal<sc_bv<768>> gs2_data;

    sc_signal<int> lat_counter;
    sc_signal<int> gs_counter;
    sc_signal<driver_mode_t> current_mode;
};
