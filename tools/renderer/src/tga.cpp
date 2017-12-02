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
                                  .width = w,
                                  .height = h,
                                  .bpp = bpp,
                                  .descriptor = 0}};
    fwrite(&header, sizeof(header), 1, fo);

    // Swap Red and Blue (screw you TGA...)
    fwrite(pixels, bpp / 8, w * h, fo);

    fclose(fo);
}
