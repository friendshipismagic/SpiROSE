#ifndef _WIDGET_H
#define _WIDGET_H

typedef enum type type;
enum type { BUTTON, SLIDER, CONTAINER };

GHandle genericWidgetCreation(type widget, int width_, int height_, int x_,
                              int y_, char *text_, GHandle parent_,
                              CustomWidgetDrawFunction customDraw_,
                              void *customParam_);

#endif
