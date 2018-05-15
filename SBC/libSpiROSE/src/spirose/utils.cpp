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

#include <cstdio>
#include <cstring>
#include <iostream>
#include <vector>

#include <png.h>

#include "utils.h"

namespace spirose {

// This implementation is inspired by http://zarb.org/~gc/html/libpng.html
bool savePNG(const std::string &filename, const int width, const int height,
             const uint8_t *cpixels) {
    bool ret = false;

    uint8_t *pixels = nullptr;
    FILE *fp = nullptr;
    png_structp png = nullptr;
    png_infop info = nullptr;
    std::vector<png_byte *> rows(height);

    // Duplicate pixels because libpng does *not* takes a const pointer...
    pixels = new uint8_t[width * height * 4];
    if (!pixels) {
        std::cerr << "[ERR] savePNG: failed to allocate "
                  << (width * height * 4) << " bytes" << std::endl;
        goto end;
    }
    memcpy(pixels, cpixels, width * height * 4);

    // Open file
    if (!(fp = fopen(filename.c_str(), "wb"))) {
        std::cerr << "[ERR] savePNG: failed to open file " << filename
                  << std::endl;
        goto end;
    }

    // Init libpng structures
    if (!(png = png_create_write_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr,
                                        nullptr))) {
        std::cerr << "[ERR] savePNG: png_create_write_struct failed"
                  << std::endl;
        goto end;
    }
    if (!(info = png_create_info_struct(png))) {
        std::cerr << "[ERR] savePNG: png_create_write_struct failed"
                  << std::endl;
        goto end;
    }

    if (setjmp(png_jmpbuf(png))) {
        std::cerr << "[ERR] savePNG: png_init_io failed" << std::endl;
        goto end;
    }
    png_init_io(png, fp);

    // Write PNG headers
    if (setjmp(png_jmpbuf(png))) {
        std::cerr << "[ERR] savePNG: failed to write headers" << std::endl;
        goto end;
    }
    png_set_IHDR(png, info, width, height, 8, PNG_COLOR_TYPE_RGBA,
                 PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE,
                 PNG_FILTER_TYPE_BASE);
    png_write_info(png, info);

    /* libPNG takes a 2D array in the form of an array of pointers to the rows.
     * Thus generate this array of pointers
     */
    for (int y = 0; y < height; y++)
        rows[height - y - 1] = &pixels[y * width * 4];

    // Write pixels
    if (setjmp(png_jmpbuf(png))) {
        std::cerr << "[ERR] savePNG: failed to write pixels" << std::endl;
        goto end;
    }
    png_write_image(png, &rows[0]);

    if (setjmp(png_jmpbuf(png))) {
        std::cerr << "[ERR] savePNG: failed to write end" << std::endl;
        goto end;
    }
    png_write_end(png, nullptr);

    // Success!
    ret = true;

end:
    if (fp) fclose(fp);
    if (png) png_destroy_write_struct(&png, info ? &info : nullptr);
    if (pixels) delete pixels;

    return ret;
}

}  // namespace spirose
