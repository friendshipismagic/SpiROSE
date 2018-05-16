/* * Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément
 * Decoodt, Alexandre Janniaux, Adrien Marcenat
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#ifndef FPGA_DRIVER_CMD_H
#define FPGA_DRIVER_CMD_H

#include <stdint.h>
#include <unistd.h>

#define DRIVER_NB_BUFFER 16
#define DRIVER_POKER_SIZE 9
#define DRIVER_REG_SIZE 48
#define DRIVER_NB_COLOR 3
#define DRIVER_COLOR_SIZE 8
#define DRIVER_COLOR_BUFFER_SIZE (DRIVER_REG_SIZE / DRIVER_NB_COLOR)

/*
 *  Represent the type of latch
 */
enum latch_t {
    LATCH_NONE = 0,
    LATCH_WRTGS = 1,
    LATCH_LATGS = 3,
    LATCH_WRTFC = 5,
    LATCH_LINERESET = 7,
    LATCH_READFC = 11,
    LATCH_TMGRST = 13,
    LATCH_FCWRTEN = 15
};

/*
 * Represents a sequence (timing) in which each cell in the array is
 * a value sent on LAT/SIN on a SCLK tick.
 *
 * The sequence should be allocated with make_sequence and freed
 * with free_sequence.
 *
 * \see make_sequence, free_sequence
 */
typedef struct {
    size_t size;
    uint8_t* lat;
    uint8_t* sin;
} driver_sequence_t;

/*
 * Unpacked structure representing the configuration of the driver.
 * The same naming convention as the application note in the repository
 * are taken.
 *
 * You can use the make_WRTCFG to convert the structure into a sequence.
 *
 * \see make_WRTCFG
 */
typedef struct {
    uint32_t LODVTH;
    uint32_t SEL_TD0;
    uint32_t SEL_GDLY;
    uint32_t XREFRESH;
    uint32_t SEL_GCK_EDGE;
    uint32_t SEL_PCHG;
    uint32_t ESPWM;
    uint32_t LGSE3;
    uint32_t SEL_SCK_EDGE;
    uint32_t LGSE1;
    uint32_t CCB;
    uint32_t CCG;
    uint32_t CCR;
    uint32_t BC;
    uint32_t POKER;
    uint32_t LGSE2;
} driver_config_t;

/*
 * Unpacked structure containing the RGB value of a pixel.
 *
 * \see make_poker_data, make_normal_data
 */
typedef struct {
    uint8_t color[3];
} rgb_t;

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Dynamically creates a sequence of the given length. The returned sequence
 * must be freed with free_sequence.
 *
 * \param length the length of the sequence to create
 * \return a new allocated sequence of the given size
 *
 * \see free_sequence
 */
driver_sequence_t make_sequence(size_t length);

/*
 * Dynamically creates a sequence given a driver configuration. The
 * configuration contains the WRTCFG latch pattern. The returned sequence must
 * be freed with the free_sequence function.
 *
 * \param c the config to convert into sequence
 * \return a new allocated driver_sequence_t containing the pattern
 *
 * \see free_sequence
 */
driver_sequence_t make_WRTCFG(driver_config_t c);

/*
 * Dynamically creates a FCWRTEN pattern sequence, putting the driver
 * in configuration mode. Poker mode shouldn't be used in configuration
 * mode. The returned sequence must be freed with free_sequence.
 *
 * \return a new allocated driver_sequence_t containing the FCWRTEN pattern
 */
driver_sequence_t make_FCWRTEN();

/*
 * Dynamically creates a list of sequences containing the full
 * data to send to the driver so as to configure the full GS
 * register. The array must be freed with free_sequences.
 *
 * \param data the rgb array to send, which should be of size 16
 *
 * \return a new dynamically allocated sequence array containing each \
 *         sequence with correct latch
 */
driver_sequence_t* make_normal_data(const rgb_t data[]);

/*
 * Dynamically creates a data sequence in normal ordering.
 *
 * \param data a rgb_t array containing the different colors
 *
 * \todo The latch should be {WRTGS, LATGS, LINERESET}
 */
driver_sequence_t make_normal_sequence(const rgb_t* data, enum latch_t latch);

/*
 * Dynamically creates a list of sequences containing the full
 * data to send to the driver in poker mode ordering, so as to
 * configure the full GS register. The array must be free with
 * free_sequences.
 *
 * \param data the rgb array to send, which should be of size 16
 *
 * \return a new dynamically allocated sequence array containing \
 *         each sequence with correct latch in poker mode ordering
 *
 */
driver_sequence_t* make_poker_data(const rgb_t data[DRIVER_NB_BUFFER]);

/*
 * Dynamically creates a data sequence in poker mode ordering
 *
 * \param data a rgb_t array containing the different colors
 * \param bitNumber the bit to send
 *
 * \return a new dynamically allocated sequence containing the data
 */
driver_sequence_t make_poker_sequence(const rgb_t data[DRIVER_NB_BUFFER],
                                      int bitNumber);

/*
 * Free the dynamically allocated sequence.
 *
 * \param seq the sequence to free
 */
void free_sequence(driver_sequence_t* seq);

/*
 * Free the dynamically allocated array of sequences.
 *
 * \param seqs the array of sequence to free
 */
void free_sequences(driver_sequence_t* seqs[]);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif
