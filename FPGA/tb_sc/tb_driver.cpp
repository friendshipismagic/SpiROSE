#include <systemc.h>

#include "driver.hpp"
#include "assert.h"
#include "driver_cmd.h"

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

    static sc_bv<768> gs1Data;
    static sc_bv<768> gs2Data;

    // Assign configuration values to be sent ot the driver module
    testConfig = {3,3,0,1,1,1,1,1,0,4,128,128,128,7,1,5};

    for (int i = 0; i < 16; i++) {
        for (int j = 0; j < 3; j++) {
            testData[i].color[j] = rand() % 256;
        }
    }

    Driver driver("driver");

    // bind the signals
    driver.gclk(gclk);
    driver.sclk(clk);
    driver.nrst(nrst);
    driver.sin(sin);
    driver.lat(lat);

    // The following lins need to be uncommented if traces are wanted
    //sc_trace_file *wf = sc_create_vcd_trace_file("driverTest");
    //sc_trace(wf, clk, "clk");
    //sc_trace(wf, nrst, "nrst");
    //sc_trace(wf, sin, "sin");
    //sc_trace(wf, lat, "lat");
    //sc_trace(wf, gclk, "gclk");

    sc_start(T);

    // Resets the module
    nrst = 0;
    sc_start(T);
    nrst = 1;
    sc_start(T);

    while (sc_time_stamp() < simulation_time) {

        // Send the configuration write enable to the driver
        configWriteEnableSequence = make_FCWRTEN();

        for (int i = 0; i < (uint8_t) configWriteEnableSequence.size; i++) {
            sin.write(configWriteEnableSequence.sin[i]);
            lat.write(configWriteEnableSequence.lat[i]);
            sc_start(T);
        }

        // Send the configuration sequence to the driver
        writeConfigSequence = make_WRTCFG(testConfig);

        for (int i = 0; i < (uint8_t) writeConfigSequence.size; i++) {
            sin.write(writeConfigSequence.sin[i]);
            lat.write(writeConfigSequence.lat[i]);
            sc_start(T);
        }

        // Test the configuration register FC
        assert(testConfig.LODVTH       ==  driver.getLodth().to_uint());
        assert(testConfig.SEL_TD0      ==  driver.getTd0().to_uint());
        assert(testConfig.SEL_GDLY     ==  driver.getGroup());
        assert(testConfig.XREFRESH     ==  driver.getXrefreshDisabled());
        assert(testConfig.SEL_GCK_EDGE ==  driver.getSelGckEdge());
        assert(testConfig.SEL_PCHG     ==  driver.getSelPchg());
        assert(testConfig.ESPWM        ==  driver.getEspwm());
        assert(testConfig.LGSE3        ==  driver.getLgse3());
        assert(testConfig.SEL_SCK_EDGE ==  driver.getSelSckEdge());
        assert(testConfig.LGSE1        ==  driver.getLgse1().to_uint());
        assert(testConfig.CCB          ==  driver.getCcb().to_uint());
        assert(testConfig.CCG          ==  driver.getCcg().to_uint());
        assert(testConfig.CCR          ==  driver.getCcr().to_uint());
        assert(testConfig.BC           ==  driver.getBc().to_uint());
        assert(testConfig.POKER        ==  driver.getPokerMode());
        assert(testConfig.LGSE2        ==  driver.getLgse2().to_uint());
        

        // Send the data to the driver in poker mode
        pokerSequence = make_poker_data(testData);

        for (int i = 0; i < 9; i++) {
            for (int j = 0; j < (uint8_t) pokerSequence[i].size; j++) {
                sin.write(pokerSequence[i].sin[j]);
                lat.write(pokerSequence[i].lat[j]);
                sc_start(T);
            }
            sc_start(T);
        }

        // Testing the driver internals
        gs1Data = driver.getGs1Data();
        gs2Data = driver.getGs2Data();

        for (int outputNb = 0; outputNb < 48; outputNb++) {
            for (int j = 0; j < 9; j++) {
                // Verify that the data in the 768-bit latch registers
                assert(gs1Data(outputNb * 16 + 7, outputNb * 16 + 7 + 8).to_uint() 
                        == testData[outputNb / 3].color[outputNb % 3]);
                assert(gs2Data(outputNb * 16 + 7, outputNb * 16 + 7 + 8).to_uint() 
                        == testData[outputNb / 3].color[outputNb % 3]);
            }
        }
    }

    return EXIT_SUCCESS;
}
