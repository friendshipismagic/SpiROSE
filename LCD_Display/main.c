#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "gfx.h"
#include "stm32f7_i2c.h"
#include "stm32f7xx.h"
#include "stm32f7xx_hal.h"
#include "widget.h"

#define WIDTH gdispGetWidth()
#define HEIGHT gdispGetHeight()

static font_t font;

static GListener gl;

static GHandle mainContainer;
static GHandle debugContainer;
static GHandle menuContainer;
static GHandle demoContainer;
static GHandle menuControls, menuDemo, menuDebug;
static GHandle gButton1;
static GHandle gButton2;
static GHandle slider;
static GHandle console;

static gdispImage myImage;

static void widgetCreation(void);

// Definition of a custom Widget Style for SpiROSE to be used for every widget
static const GWidgetStyle SpiROSEStyle = {
    // Background colour
    HTML2COLOR(0x5A4472),

    // Focused-state colour
    HTML2COLOR(0x3333ff),

    // enabled widget color set
    {// Colour of the text part
     HTML2COLOR(0x863E28),
     // Colour of the edges
     HTML2COLOR(0x404040),
     // Main background colour
     HTML2COLOR(0xFFC516),
     // Colour for the used part of sliders
     HTML2COLOR(0x999900)},

    // disabled widget color set, same structure as above
    {HTML2COLOR(0x444444), HTML2COLOR(0x808080), HTML2COLOR(0xE0E0E0),
     HTML2COLOR(0xC0E0C0)},

    // pressed widget color set, same structure as above
    {
        HTML2COLOR(0xFF0000), HTML2COLOR(0x404040), HTML2COLOR(0x808080),
        HTML2COLOR(0x00E000),
    }};

int main(void) {
    GEvent *pe;

    // Initialization of the display
    gfxInit();

    // Import the needed font, '*' means the first in the font list
    font = gdispOpenFont("*");

    // All widgets that have a text parameter will use this font by default
    gwinSetDefaultFont(font);

    // All widgets that have a text parameter will use this style by default
    gwinSetDefaultStyle(&SpiROSEStyle, FALSE);

    widgetCreation();

    // Slider's position
    int pos = 0;

    while (TRUE) {
        pe = geventEventWait(&gl, TIME_INFINITE);

        if (pe->type == GEVENT_GWIN_SLIDER &&
            ((GEventGWinSlider *)pe)->action == GSLIDER_EVENT_SET) {
            pos = gwinSliderGetPosition(slider);
            char str[12];
            itoa(pos * 3.6, str, 10);
            gwinSetText(slider, str, TRUE);
            // TODO: Send rotation information to the SBC
            gwinPrintf(console, "Rotation changed, new value:\n");
            gwinPrintf(console, str);
            gwinPrintf(console, "\n");
        } else if (pe->type == GEVENT_GWIN_BUTTON &&
                   ((GEventGWinButton *)pe)->gwin == gButton1) {
            // TODO : Send start command to SBC
            gwinPrintf(console, "START BUTTON pressed\n");
        } else if (pe->type == GEVENT_GWIN_BUTTON &&
                   ((GEventGWinButton *)pe)->gwin == gButton2) {
            // TODO : Send stop command to SBC
            gwinPrintf(console, "STOP BUTTON pressed\n");
        } else if (pe->type == GEVENT_GWIN_BUTTON &&
                   ((GEventGWinButton *)pe)->gwin == menuDebug) {
            gwinHide(mainContainer);
            gwinHide(demoContainer);
            gwinShow(debugContainer);
            // TODO : Send stop command to SBC
            gwinPrintf(console, "DEBUG MENU BUTTON pressed\n");
        } else if (pe->type == GEVENT_GWIN_BUTTON &&
                   ((GEventGWinButton *)pe)->gwin == menuControls) {
            gwinHide(debugContainer);
            gwinHide(demoContainer);
            gwinHide(mainContainer);
            gwinShow(mainContainer);
            // TODO : Send stop command to SBC
            gwinPrintf(console, "DEBUG MENU BUTTON pressed\n");
        } else if (pe->type == GEVENT_GWIN_BUTTON &&
                   ((GEventGWinButton *)pe)->gwin == menuDemo) {
            gwinHide(mainContainer);
            gwinHide(debugContainer);
            gwinShow(demoContainer);
            // TODO : Send stop command to SBC
            gwinPrintf(console, "DEBUG MENU BUTTON pressed\n");
        }
    }

    return 0;
}

static void widgetCreation(void) {
    // Opens an image, needs the name of the image defined in the image_name.h
    // header file
    gdispImageOpenFile(&myImage, "degrade_bleu.png");

    // Container creation

    menuContainer = genericWidgetCreation(CONTAINER, WIDTH, 40, 0, HEIGHT - 40,
                                          "menuContainer", NULL, NULL, NULL);

    mainContainer = genericWidgetCreation(CONTAINER, WIDTH, HEIGHT - 40, 0, 0,
                                          "mainContainer", NULL, NULL, NULL);

    debugContainer = genericWidgetCreation(CONTAINER, WIDTH, HEIGHT - 40, 0, 0,
                                           "debugContainer", NULL, NULL, NULL);

    demoContainer = genericWidgetCreation(CONTAINER, WIDTH, HEIGHT - 40, 0, 0,
                                          "debugContainer", NULL, NULL, NULL);

    menuControls = genericWidgetCreation(BUTTON, 160, 40, 0, 0, "CONTROLS",
                                         menuContainer, NULL, NULL);
    menuDemo = genericWidgetCreation(BUTTON, 160, 40, 160, 0, "DEMO",
                                     menuContainer, NULL, NULL);
    menuDebug = genericWidgetCreation(BUTTON, 160, 40, 320, 0, "DEBUG",
                                      menuContainer, NULL, NULL);

    // Button creation
    gButton1 =
        genericWidgetCreation(BUTTON, 160, 30, 10, 10, "START SPIROSE",
                              mainContainer, gwinButtonDraw_Rounded, NULL);
    gButton2 =
        genericWidgetCreation(BUTTON, 160, 30, WIDTH - 170, 10, "STOP SPIROSE",
                              mainContainer, gwinButtonDraw_Rounded, NULL);

    // Slider creation
    slider = genericWidgetCreation(SLIDER, WIDTH - 40, 40, 20, 120, "ROTATION",
                                   mainContainer, NULL, NULL);

    // The container and all its children are visible
    gwinShow(mainContainer);
    gwinHide(debugContainer);
    gwinHide(demoContainer);

    // Creation of the console window, needs a different initializing structure
    GWindowInit gwi;
    gwinClearInit(&gwi);
    gwi.show = TRUE;
    gwi.x = 10;
    gwi.y = 10;
    gwi.width = WIDTH - 20;
    gwi.height = HEIGHT - 60;
    gwi.parent = debugContainer;

    console = gwinConsoleCreate(0, &gwi);
    gwinSetColor(console, Grey);
    gwinSetBgColor(console, White);
    gwinClear(console);

    // Print any data to the console
    gwinPrintf(console,
               "SpiROSE Status : WIP\nIMU Information:\nX acceleration:\nY "
               "acceleration:\nZ acceleration:\n");

    // We want to listen for widget events
    geventListenerInit(&gl);
    gwinAttachListener(&gl);
}
