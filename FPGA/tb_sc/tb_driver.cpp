#include <systemc.h>
#include <cassert>
#include "driver.hpp"
#include "driver_cmd.h"

void sendSequence(driver_sequence_t seq, sc_signal<bool> *sin, 
        sc_signal<bool> *lat, sc_time T) {
    for (int i = 0; i < (uint8_t)seq.size; i++) {
        sin->write(seq.sin[i]);
        lat->write(seq.lat[i]);
        sc_start(T);
    }
}

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
    // For now, sending false for gclk
    sc_clock gclk("gclk", T, 0.5, simulation_time, true);

    static rgb_t testData[16];
    static driver_config_t testConfig;

    static driver_sequence_t configWriteEnableSequence;
    static driver_sequence_t writeConfigSequence;
    static driver_sequence_t* pokerSequence;

    static sc_bv<768> gs1Data;
    static sc_bv<768> gs2Data;

    for (int i = 0; i < 16; i++) {
        for (int j = 0; j < 3; j++) {
            testData[i].color[j] = rand() % 256;
        }
    }

    printf(
        "***********************\n"
        "TESTS FOR DRIVER MODULE\n"
        "***********************\n\n");

    Driver driver("driver");

    // bind the signals
    driver.gclk(gclk);
    driver.sclk(clk);
    driver.nrst(nrst);
    driver.sin(sin);
    driver.lat(lat);

    // The following lins need to be uncommented if traces are wanted
    // sc_trace_file *wf = sc_create_vcd_trace_file("driverTest");
    // sc_trace(wf, clk, "clk");
    // sc_trace(wf, nrst, "nrst");
    // sc_trace(wf, sin, "sin");
    // sc_trace(wf, lat, "lat");
    // sc_trace(wf, gclk, "gclk");

    sc_start(T);

    configWriteEnableSequence = make_FCWRTEN();

    // Resets the module
    nrst = 0;
    sc_start(T);
    nrst = 1;
    sc_start(T);

    /*
     * Testing random configuration sequences for potential side effects
     * in the driver code (keeping XREFRESH and ESPWM disabled
     */
    for (int i = 0; i < 10; i++) {
        testConfig = {
            (uint32_t)rand(), (uint32_t)rand(), (uint32_t)rand(), 1,
            (uint32_t)rand(), (uint32_t)rand(), 1, (uint32_t)rand(),
            (uint32_t)rand(), (uint32_t)rand(), (uint32_t)rand(), (uint32_t)rand(),
            (uint32_t)rand(), (uint32_t)rand(), (uint32_t)rand(), (uint32_t)rand(),
        };
        sendSequence(configWriteEnableSequence, &sin, &lat, T);
        writeConfigSequence = make_WRTCFG(testConfig);
        sendSequence(writeConfigSequence, &sin, &lat, T);
        lat.write(0);
        sc_start(T);
    }

    // Assign configuration values to be sent to the driver module
    testConfig = {3, 3, 0, 1, 1, 1, 1, 1, 0, 4, 127, 127, 127, 7, 1, 5};

    while (sc_time_stamp() < simulation_time) {
        
        // Send the configuration write enable to the driver
        printf("Sending FC write enable sequence to the driver...");
        sendSequence(configWriteEnableSequence, &sin, &lat, T);
        printf("DONE\n");

        // Send the configuration sequence to the driver
        writeConfigSequence = make_WRTCFG(testConfig);

        printf("Sending configuration sequence to the driver...");
        sendSequence(writeConfigSequence, &sin, &lat, T);
        lat.write(0);
        sc_start(T);
        printf("DONE\n");

        // Test the configuration register FC
        printf("Testing configuration of the driver...");
        assert(testConfig.LODVTH == driver.getLodth().to_uint());
        assert(testConfig.SEL_TD0 == driver.getTd0().to_uint());
        assert(testConfig.SEL_GDLY == driver.getGroup());
        assert(testConfig.XREFRESH == driver.getXrefreshDisabled());
        assert(testConfig.SEL_GCK_EDGE == driver.getSelGckEdge());
        assert(testConfig.SEL_PCHG == driver.getSelPchg());
        assert(testConfig.ESPWM == driver.getEspwm());
        assert(testConfig.LGSE3 == driver.getLgse3());
        assert(testConfig.SEL_SCK_EDGE == driver.getSelSckEdge());
        assert(testConfig.LGSE1 == driver.getLgse1().to_uint());
        assert(testConfig.CCB == driver.getCcb().to_uint());
        assert(testConfig.CCG == driver.getCcg().to_uint());
        assert(testConfig.CCR == driver.getCcr().to_uint());
        assert(testConfig.BC == driver.getBc().to_uint());
        assert(testConfig.POKER == driver.getPokerMode());
        assert(testConfig.LGSE2 == driver.getLgse2().to_uint());
        printf("DONE\n");

        // Send the data to the driver in poker mode
        pokerSequence = make_poker_data(testData);

        printf("Sending 9 sequences of data (9-bit poker mode)...\n");
        for (int i = 0; i < 9; i++) {
            sendSequence(pokerSequence[i], &sin, &lat, T);
            // TODO: print the shift register value
        }
        printf("DONE\n");
        sc_start(T);
        for (int i = 0; i < 16; i++) {
            cout << 

        // Testing the driver internals
        gs1Data = driver.getGs1Data();
        gs2Data = driver.getGs2Data();

        for (int outputNb = 0; outputNb < 48; outputNb++) {
            // Verify that the data in the 768-bit latch registers
            auto expectedGS1 = 
                gs1Data(outputNb * 16 + 7 + 8, outputNb * 16 + 7).to_uint();
            auto expectedGS2 = 
                gs2Data(outputNb * 16 + 7 + 8, outputNb * 16 + 7).to_uint();
            auto readData = testData[outputNb / 3].color[outputNb % 3];

            if (outputNb % 3 == 0) {
                printf("Read data: R%d, G%d, B%d\n", outputNb/3, outputNb/3, outputNb/3);
            }

            printf(
                "gs1Data (read) = %x,"
                " testData (expected) = %x\n",
                expectedGS1,
                readData);

            assert(expectedGS1 == readData);
            assert(expectedGS2 == readData);
        }
    }

    return EXIT_SUCCESS;
}
