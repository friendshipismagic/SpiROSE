/*
 * This file is meant to test the sequence generation library
 * that will be used for SystemC simulations for drivers
 */

#include <stdio.h>
#include "assert.h"
#include "driver_cmd.h"
#include "stdint.h"
#include "stdlib.h"
#include "string.h"
#include "time.h"
#include "unistd.h"

#define TEST_NUMBER 5

#define BIT(X, pos) (((X) & (1 << (pos))) >> (pos))

int main(void) {
    static driver_sequence_t *sequence;
    static driver_sequence_t *sequence_poker;

    static rgb_t rgbTest[DRIVER_NB_BUFFER];

    srand((unsigned)time(NULL));

    for (int testNb = 0; testNb < TEST_NUMBER; testNb++) {
        printf("Tests for random data #%d\n", testNb + 1);

        for (int i = 0; i < DRIVER_NB_BUFFER; i++) {
            for (int colorNb = 0; colorNb < DRIVER_NB_COLOR; colorNb++) {
                rgbTest[i].color[colorNb] = rand() % (DRIVER_COLOR_SIZE - 1);
            }
        }

        /*
         * Test for normal data sequence generation
         */

        sequence = make_normal_data(rgbTest);

        /*
         * Test for the LAT signal data. In normal data mode,
         * 16 48-bit wide sequences are transmitted. At the end of each
         * sequence except the last one, a WRTGS command is sent, LAT is
         * set high (One SCLK rising edge needs to occurs while LAT is
         * high, at the end of the sequence). The last sequence has a
         * LATGS to copy all the data to the second 768-bit wide GS
         * data latch. The LATGS command corresponds to 3 SCLK-period
         * wide high LAT at the end of the last sequence.
         */

        // Check for WRTGS
        printf("NORMAL DATA MODE: Checking WRTGS commands\n");
        for (int i = 0; i < DRIVER_NB_BUFFER - 1; i++) {
            assert(sequence[i].lat[DRIVER_REG_SIZE - 1] == 1);
            for (int j = 0; j < DRIVER_REG_SIZE - 1; j++) {
                assert(sequence[i].lat[j] == 0);
            }
        }

        // Check for LATGS
        printf("NORMAL DATA MODE: Checking LATGS commands\n");
        assert((sequence[DRIVER_NB_BUFFER - 1].lat[DRIVER_REG_SIZE - 1] &
                sequence[DRIVER_NB_BUFFER - 1].lat[DRIVER_REG_SIZE - 2] &
                sequence[DRIVER_NB_BUFFER - 1].lat[DRIVER_REG_SIZE - 3]) == 1);
        for (int i = 0; i < DRIVER_REG_SIZE - 3; i++) {
            assert(sequence[DRIVER_NB_BUFFER - 1].lat[i] == 0);
        }

        /*
         * Half of all 16 bit data is set to zero, since we only
         * need a 8-bit depth.
         */
        printf("NORMAL DATA MODE: Checking structure of SIN\n");
        for (int k = 0; k < DRIVER_NB_BUFFER - 1; k++) {
            for (int i = 0; i < DRIVER_NB_COLOR; i++) {
                for (int j = 0; j < DRIVER_POKER_SIZE - 1; j++) {
                    assert(sequence[k].sin[DRIVER_NB_BUFFER * i + j +
                                           DRIVER_COLOR_SIZE] == 0);
                }
            }
        }

        /*
         * The MSB part of the data for each colour needs to be the same
         * as that of the initial LED data
         */
        printf("NORMAL DATA MODE: Checking data integrity of SIN\n");
        for (int k = 0; k < DRIVER_NB_BUFFER; k++) {
            for (int i = 0; i < DRIVER_NB_COLOR; i++) {
                for (int j = 0; j < DRIVER_POKER_SIZE - 1; j++) {
                    assert(sequence[k].sin[DRIVER_NB_BUFFER * i +
                                           (DRIVER_COLOR_SIZE - 1) - j] ==
                           BIT(rgbTest[k].color[i], j));
                }
            }
        }

        /*
         * Test for poker mode data sequence generation
         */

        sequence_poker = make_poker_data(rgbTest);

        /*
         * Verify that only N sequences are allocated, as it should be
         * for N-bit poker data mode
         */
        printf(
            "POKER DATA MODE: Checking that only %d sequences are generated\n",
            DRIVER_POKER_SIZE);
        assert(sequence_poker[DRIVER_POKER_SIZE - 1].sin != NULL);
        assert(sequence_poker[DRIVER_POKER_SIZE - 1].lat != NULL);
        assert(sequence_poker[DRIVER_POKER_SIZE].size == 0);

        /*
         * Tests for the lat sequence. There should be a WRTGS at every
         * sequence except for the last one that has a LATGS.
         * The code is essentially the same as for normal data.
         * NOTE: There is a mistake in the TLC5957 user guide SLUAF0,
         * page 20, the two graphs are identical, and the following
         * graph page 21 furthermore contradicts the length and the effects
         * of the LATGS command as regards the LAT signal.
         */

        // Check for WRTGS
        printf("POKER DATA MODE: Checking WRTGS commands\n");
        for (int i = 0; i < DRIVER_POKER_SIZE - 1; i++) {
            assert(sequence_poker[i].lat[DRIVER_REG_SIZE - 1] == 1);
            for (int j = 0; j < DRIVER_REG_SIZE - 1; j++) {
                assert(sequence_poker[i].lat[j] == 0);
            }
        }

        // Check for LATGS
        printf("POKER DATA MODE: Checking LATGS command\n");
        assert(
            (sequence_poker[DRIVER_POKER_SIZE - 1].lat[DRIVER_REG_SIZE - 1] &
             sequence_poker[DRIVER_POKER_SIZE - 1].lat[DRIVER_REG_SIZE - 2] &
             sequence_poker[DRIVER_POKER_SIZE - 1].lat[DRIVER_REG_SIZE - 3]) ==
            1);
        for (int i = 0; i < DRIVER_REG_SIZE - 3; i++) {
            assert(sequence_poker[DRIVER_POKER_SIZE - 1].lat[i] == 0);
        }

        /*
         * We should be able to construct the original data from the data bits
         * that are fragmented over multiple 48-bit long fragments.
         * In 9-bit poker mode, 9 segments of 48 bits are used.
         * The first bank has the MSB (aka the 9th) of all OUT(R/G/B)X.
         */
        printf("POKER DATA MODE: Cheking data integrity of SIN\n");
        for (int j = 0; j < DRIVER_NB_BUFFER; j++) {
            for (int i = 0; i < DRIVER_NB_COLOR; i++) {
                uint16_t reconstructedSingleData = 0;
                for (int k = 0; k < DRIVER_POKER_SIZE; k++) {
                    reconstructedSingleData |=
                        (sequence_poker[k].sin[(DRIVER_REG_SIZE - 1) -
                                               (DRIVER_NB_COLOR * j + i)]
                         << k);
                }
                assert(reconstructedSingleData == rgbTest[j].color[i]);
            }
        }
    }

    return 0;
}
