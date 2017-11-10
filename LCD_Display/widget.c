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
    return 0;
}
