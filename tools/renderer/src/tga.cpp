//
// Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément
// Decoodt, Alexandre Janniaux, Adrien Marcenat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#include <stdint.h>
#include <cstdio>
#include <iostream>
#include <string>

#include "tga.h"

typedef struct tga_header {
    uint8_t length;
    uint8_t colorMapType;
    uint8_t imageType;
    struct {
        uint16_t firstIdx;
        uint16_t count;
        uint8_t bpp;
    } __attribute__((packed)) colorMaps;
    struct {
        uint16_t xOrigin;
        uint16_t yOrigin;
        uint16_t width;
        uint16_t height;
        uint8_t bpp;
        uint8_t descriptor;
    } __attribute__((packed)) spec;
} __attribute__((packed)) tga_header;

void saveTGA(const std::string &filename, void *pixels, int bpp, int w, int h) {
    FILE *fo = fopen(filename.c_str(), "wb");
    if (!fo) return;

    // Create header for the image
    tga_header header = {.length = 0,
                         .colorMapType = 0,
                         .imageType = 2,
                         .colorMaps = {0},
                         .spec = {.xOrigin = 0,
                                  .yOrigin = 0,
                                  .width = (uint16_t)w,
                                  .height = (uint16_t)h,
                                  .bpp = (uint8_t)bpp,
                                  .descriptor = 0}};
    fwrite(&header, sizeof(header), 1, fo);

    // Swap Red and Blue (screw you TGA...)
    fwrite(pixels, bpp / 8, w * h, fo);

    fclose(fo);
}
