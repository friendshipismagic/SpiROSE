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

// clang-format off
#include "gfx.h"
#include "widget.h"
// clang-format on

/* This function offers a generic implementation for the creation of some
 * widgets, any type of widget may be added later, depending of the needs
 * of the application */

GHandle genericWidgetCreation(type widget, int width_, int height_, int x_,
                              int y_, char *text_, GHandle parent_,
                              CustomWidgetDrawFunction customDraw_,
                              void *customParam_) {
    GWidgetInit wi;
    gwinWidgetClearInit(&wi);
    wi.g.show = TRUE;
    wi.g.width = width_;
    wi.g.height = height_;
    wi.g.x = x_;
    wi.g.y = y_;
    wi.text = text_;
    wi.customDraw = customDraw_;
    wi.customParam = customParam_;
    if (widget == BUTTON) {
        wi.g.parent = parent_;
        return gwinButtonCreate(0, &wi);
    }
    if (widget == SLIDER) {
        wi.g.parent = parent_;
        return gwinSliderCreate(0, &wi);
    }
    if (widget == CONTAINER) {
        (void)parent_;
        return gwinContainerCreate(0, &wi, 0);
    }
    if (widget == LABEL) {
        wi.g.parent = parent_;
        return gwinLabelCreate(0, &wi);
    }
    return 0;
}
