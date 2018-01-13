#include <cstdio>
#include <iostream>
#include <vector>

#include <png.h>

#include "utils.h"

namespace spirose {

// This implementation is inspired by http://zarb.org/~gc/html/libpng.html
bool savePNG(const std::string &filename, const int width, const int height,
             uint8_t *pixels) {
    bool ret = false;

    FILE *fp = nullptr;
    png_structp png = nullptr;
    png_infop info = nullptr;
    std::vector<png_byte *> rows(height);

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
    for (int y = 0; y < height; y++) rows[y] = &pixels[y * width * 4];

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

    return ret;
}

}  // namespace spirose
