#include "driver_cmd.h"
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BIT(X, pos) (((X) & (1 << (pos))) >> (pos))

#define LODVTH_IDX (0)
#define LODVTH_SIZE (2)

#define SEL_TD0_IDX (2)
#define SEL_TD0_SIZE (2)

#define SEL_GDLY_IDX (4)
#define SEL_GDLY_SIZE (1)

#define XREFRESH_IDX (5)
#define XREFRESH_SIZE (1)

#define SEL_GCK_EDGE_IDX (6)
#define SEL_GCK_EDGE_SIZE (1)

#define SEL_PCHG_IDX (7)
#define SEL_PCHG_SIZE (1)

#define ESPWM_IDX (8)
#define ESPWM_SIZE (1)

#define LGSE3_IDX (9)
#define LGSE3_SIZE (1)

#define SEL_SCK_EDGE_IDX (10)
#define SEL_SCK_EDGE_SIZE (1)

#define LGSE1_IDX (11)
#define LGSE1_SIZE (3)

#define CCB_IDX (14)
#define CCB_SIZE (9)

#define CCG_IDX (23)
#define CCG_SIZE (9)

#define CCR_IDX (32)
#define CCR_SIZE (9)

#define BC_IDX (41)
#define BC_SIZE (3)

#define POKER_IDX (44)
#define POKER_SIZE (1)

#define LGSE2_IDX (45)
#define LGSE2_SIZE (3)

driver_sequence_t make_sequence(size_t length) {
    return (driver_sequence_t){length, calloc(length, 1), calloc(length, 1)};
}

driver_sequence_t make_WRTCFG(driver_config_t c) {
    driver_sequence_t seq = make_sequence(48);
    // 5 latch then write
    for (int i = 0; i < 5; ++i) {
        seq.lat[seq.size - i - 1] = 1;
    }

#define SIZE(X) X##_SIZE
#define IDX(X) X##_IDX
#define PUT(X)                                                                 \
    do {                                                                       \
        for (int _i_i_m = 0; _i_i_m < SIZE(X); ++_i_i_m) {                     \
            seq.sin[DRIVER_REG_SIZE - 1 - IDX(X) - _i_i_m] = BIT(c.X, _i_i_m); \
        }                                                                      \
    } while (0)

    PUT(LODVTH);
    PUT(SEL_TD0);
    PUT(SEL_GDLY);
    PUT(XREFRESH);
    PUT(SEL_GCK_EDGE);
    PUT(SEL_PCHG);
    PUT(ESPWM);
    PUT(LGSE3);
    PUT(SEL_SCK_EDGE);
    PUT(LGSE1);
    PUT(CCB);
    PUT(CCG);
    PUT(CCR);
    PUT(BC);
    PUT(POKER);
    PUT(LGSE2);
#undef PUT
#undef IDX
#undef SIZE
    return seq;
}

driver_sequence_t make_FCWRTEN() {
    driver_sequence_t seq = make_sequence(LATCH_FCWRTEN);
    for (int i = 0; i < LATCH_FCWRTEN; ++i) seq.lat[i] = 1;
    return seq;
}

driver_sequence_t* make_normal_data(const rgb_t data[]) {
    driver_sequence_t* seqs =
        malloc((DRIVER_NB_BUFFER + 1) * sizeof(driver_sequence_t));
    for (int i = 0; i < DRIVER_NB_BUFFER; ++i) {
        enum latch_t latch = LATCH_WRTGS;
        if (i == DRIVER_NB_BUFFER - 1) latch = LATCH_LATGS;
        seqs[i] = make_normal_sequence(&data[i], latch);
    }
    seqs[DRIVER_NB_BUFFER] = make_sequence(0);
    return seqs;
}

driver_sequence_t make_normal_sequence(const rgb_t* data, enum latch_t latch) {
    driver_sequence_t seq = make_sequence(DRIVER_REG_SIZE);
    for (unsigned int i = 0; i < latch; ++i) {
        seq.lat[DRIVER_REG_SIZE - i - 1] = 1;
    }

    for (int i = 0; i < DRIVER_NB_COLOR; ++i) {
        for (int j = 0; j < DRIVER_NB_BUFFER; ++j) {
            // if j >= 8, we pad with zero, because we need to transfert 16
            // bits
            const uint8_t value =
                j < DRIVER_COLOR_SIZE
                    ? BIT(data->color[i], DRIVER_COLOR_SIZE - 1 - j)
                    : 0;
            seq.sin[i * DRIVER_NB_BUFFER + j] = value;
        }
    }
    return seq;
}

driver_sequence_t* make_poker_data(const rgb_t data[DRIVER_NB_BUFFER]) {
    driver_sequence_t* seqs =
        malloc((DRIVER_POKER_SIZE + 1) * sizeof(driver_sequence_t));
    for (int i = 0; i < DRIVER_POKER_SIZE; ++i) {
        seqs[i] = make_poker_sequence(data, i);
    }
    seqs[DRIVER_POKER_SIZE] = make_sequence(0);
    return seqs;
}

driver_sequence_t make_poker_sequence(const rgb_t data[DRIVER_NB_BUFFER],
                                      int bit_number) {
    driver_sequence_t seq = make_sequence(DRIVER_REG_SIZE);

    // Unless the nineth bit is read, send a WRTGS, else a LATGS
    enum latch_t latch =
        bit_number < DRIVER_POKER_SIZE - 1 ? LATCH_WRTGS : LATCH_LATGS;
    for (unsigned int i = 0; i < latch; ++i) {
        seq.lat[DRIVER_REG_SIZE - 1 - i] = 1;
    }

    // j is the buffer iterator
    for (int j = 0; j < DRIVER_NB_BUFFER; ++j) {
        // k is the color iterator
        for (int k = 0; k < DRIVER_NB_COLOR; ++k) {
            const uint8_t value = BIT(data[j].color[k], bit_number);
            // Higher OUTX number is presented first
            seq.sin[DRIVER_REG_SIZE - 1 - (j * DRIVER_NB_COLOR + k)] = value;
        }
    }

    return seq;
}

void free_sequence(driver_sequence_t* seq) {
    free(seq->sin);
    free(seq->lat);

    seq->size = 0;
    seq->sin = NULL;
    seq->lat = NULL;
}

void free_sequences(driver_sequence_t* seqs[]) {
    for (int i = 0; seqs[i]->size != 0; ++i) {
        free_sequence(seqs[i]);
    }
    free(seqs);
}

#undef BIT
