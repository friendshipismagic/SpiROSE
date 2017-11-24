#pragma once

#include <systemc.h>

constexpr auto GS_ADDR_COUNTER_ORIGIN = 15;
constexpr auto LINE_COUNTER_ORIGIN = 0;

class Driver : public sc_module {
    SC_HAS_PROCESS(Driver);

    enum driver_mode_t { MODE_DATA, MODE_FCWRT };
    enum driver_bank_t { GS1, GS2 };

    public:
    inline Driver(const sc_module_name& name)
        : sc_module(name), gclk("gclk"), sclk("sclk"), sin("sin"), lat("lat") {
        SC_CTHREAD(handle_sin, sclk);
        SC_CTHREAD(handle_lat, sclk);
        SC_CTHREAD(check_assert, sclk);
    }

    sc_bv<2> get_lodth() const;

    sc_bv<2> get_td0() const;

    bool get_group() const;

    bool get_xrefresh() const;

    bool get_sel_gck_edge() const;

    bool get_sel_pchg() const;

    bool get_espwm() const;

    bool get_lgse3() const;

    bool get_sel_sck_edge() const;

    sc_bv<3> get_lgse1() const;

    sc_bv<9> get_ccb() const;

    sc_bv<9> get_ccg() const;

    sc_bv<9> get_ccr() const;

    sc_bv<3> get_bc() const;

    bool get_poker_mode() const;

    sc_bv<3> get_lgse2() const;

    void handle_sin();
    void handle_lat();
    void check_assert();

    sc_in<bool> gclk;
    sc_in<bool> sclk;
    sc_in<bool> nrst;

    sc_in<bool> sin;
    sc_in<bool> lat;

    private:
    void write_to_bank(driver_bank_t bank, int buffer_id,
                       const sc_bv<48>& buffer);
    sc_signal<sc_bv<48>> shift_reg;
    sc_signal<sc_bv<48>> fc_data;
    sc_signal<sc_bv<768>> gs1_data;
    sc_signal<sc_bv<768>> gs2_data;

    sc_signal<int> lat_counter;
    sc_signal<int> gs_addr_counter;
    sc_signal<int> gs_data_counter;
    sc_signal<int> line_counter;
    sc_signal<driver_mode_t> current_mode;
};
