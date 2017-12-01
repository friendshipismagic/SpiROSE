#include <systemc.h>
#include "driver_cmd.h"

#include "driver.hpp"
#include "assert.h"

int sc_main(int, char**) {
    const sc_time T(10, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulation_time = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk("clk", T);
    sc_signal<bool> nrst("nrst");
    sc_signal<bool> sin("sin");
    sc_signal<bool> lat("lat");
    sc_signal<bool> gclk("gclk");

    static rgb_t testData[16];
    static driver_config_t testConfig;

    static driver_sequence_t configWriteEnableSequence;
    static driver_sequence_t writeConfigSequence;
    static driver_sequence_t* pokerSequence;

    Driver driver("driver");

    // bind the signals...
    driver.gclk(gclk);
    driver.sclk(clk);
    driver.nrst(nrst);
    driver.sin(sin);
    driver.lat(lat);

    sc_trace_file *wf = sc_create_vcd_trace_file("driverTest");
    sc_trace(wf, clk, "clk");
    sc_trace(wf, nrst, "nrst");
    sc_trace(wf, sin, "sin");
    sc_trace(wf, lat, "lat");
    sc_trace(wf, gclk, "gclk");

    sc_start(T);

    // Resets the module
    nrst = 0;
    sc_start(T);
    nrst = 1;
    sc_start(T);

    while (sc_time_stamp() < simulation_time) {

        // Send the configuration write enable to the driver
        configWriteEnableSequence = make_FCWRTEN();

        for (int i = 0; i < configWriteEnable.length; i++) {
            sin = configWriteEnableSequence.sin[i];
            lat = configWriteEnableSequence.lat[i];
            sc_start(T);
        }

        // Send the configuration sequence to the driver
        writeConfigSequence = make_WRTCFG(testConfig);

        for (int i = 0; i < writeConfigSequence.length; i++) {
            sin = writeConfigSequence.sin[i];
            lat = writeConfigSequence.lat[i];
            sc_start(T);
        }

        // Test the configuration register FC
        assert(testConfig.LODVTH       == (uint32_t) getLodth());
        assert(testConfig.SEL_TD0      == (uint32_t) getTd0());
        assert(testConfig.SEL_GDLY     == (uint32_t) getGroup());
        assert(testConfig.XREFRESH     == (uint32_t) getXrefreshDisabled());
        assert(testConfig.SEL_GCK_EDGE == (uint32_t) getSelGckEdge());
        assert(testConfig.SEL_PCHG     == (uint32_t) getSelPchg());
        assert(testConfig.ESPWM        == (uint32_t) getGetEspwm());
        assert(testConfig.LGSE3        == (uint32_t) getLgse3());
        assert(testConfig.SEL_SCK_EDGE == (uint32_t) getSelSckEdge());
        assert(testConfig.LGSE1        == (uint32_t) getLgse1());
        assert(testConfig.CCB          == (uint32_t) getCcb());
        assert(testConfig.CCG          == (uint32_t) getCcg());
        assert(testConfig.CCR          == (uint32_t) getCcr());
        assert(testConfig.BC           == (uint32_t) getBc());
        assert(testConfig.POKER        == (uint32_t) getPokerMode());
        assert(testConfig.LGSE2        == (uint32_t) getLgse2());
        

        // Send the data to the driver in poker mode
        pokerSequence = make_poker_data(testData);

        for (int i = 0; i < 9; i++) {
            for (int j = 0; j < pokerSequence[i].length; j++) {
                sin = pokerSequence[i].sin[j];
                lat = pokerSequence[i].lat[j];
                sc_start(T);
            }
            sc_start(T);
        }

        // TODO: Testing the driver internals
    }

    return EXIT_SUCCESS;
}
