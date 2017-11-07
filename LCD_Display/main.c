#include "gfx.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define WIDTH gdispGetWidth()
#define HEIGHT gdispGetHeight()

static font_t font;

static GListener gl;

static GHandle mainContainer;
static GHandle gButton1;
static GHandle gButton2;
static GHandle slider;
static GHandle console;

static gdispImage myImage;

static void widgetCreation(void);

// Definition of a custom Widget Style for SpiROSE to be used for every widget
static const GWidgetStyle SpiROSEStyle = {
    // Background colour
    HTML2COLOR(0x777777),

    // Focused-state colour
    HTML2COLOR(0x3333ff),

    // enabled widget color set
    {
        // Colour of the text part
        HTML2COLOR(0x444444),
        // Colour of the edges
        HTML2COLOR(0x404040),
        // Main background colour
        HTML2COLOR(0xff0000),
        // Colour for the used part of sliders
        HTML2COLOR(0x990000)
    },

    // disabled widget color set, same structure as above
    {
        HTML2COLOR(0x444444),
        HTML2COLOR(0x808080),
        HTML2COLOR(0xE0E0E0),
        HTML2COLOR(0xC0E0C0)
    },

    // pressed widget color set, same structure as above
    {
        HTML2COLOR(0xFF0000),
        HTML2COLOR(0x404040),
        HTML2COLOR(0x808080),
        HTML2COLOR(0x00E000),
    }
};

int main(void) {
    GEvent*    pe;

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
    int pos=0;

    while(TRUE) {
        pe = geventEventWait(&gl, TIME_INFINITE);
        
        if (pe->type == GEVENT_GWIN_SLIDER && ((GEventGWinSlider *)pe)->action == GSLIDER_EVENT_SET){
            pos = gwinSliderGetPosition(slider);
            char str[12];
            itoa(pos*3.6, str, 10);
            gwinSetText(slider, str, TRUE);
            // TODO: Send rotation information to the SBC
        }
        else if (pe->type == GEVENT_GWIN_BUTTON && ((GEventGWinButton *)pe)->gwin == gButton1){
            //TODO : Send start command to SBC
        }
        else if (pe->type == GEVENT_GWIN_BUTTON && ((GEventGWinButton *)pe)->gwin == gButton2){
            //TODO : Send stop command to SBC
        }

        
    }   

    return 0;
}

static void widgetCreation(void){
    // Structure used for widget initialisation
    GWidgetInit    wi;
    gwinWidgetClearInit(&wi);

    // Structure used for window initialisation
    GWindowInit gwi;
    gwinClearInit(&gwi);

    // Opens an image, need the name of the image defined in the image_name.h header file
    gdispImageOpenFile(&myImage, "degrade_bleu.png");

    /* Container */
    wi.g.show = TRUE;
    wi.g.width = WIDTH;
    wi.g.height = HEIGHT;
    wi.g.y = 0;
    wi.g.x = 0;
    wi.text = "Container";

    // This special rendering function allows an opened image to be displayed
    wi.customDraw = gwinContainerDraw_Image;

    //This parameter is passed to the rendering function above
    wi.customParam = (void*)&myImage;

    // Widget creation according to GWidgetInit structure
    mainContainer = gwinContainerCreate(0, &wi, GWIN_CONTAINER_BORDER);



    /* Button1 */
    wi.g.width = 160;
    wi.g.height = 30;
    wi.g.y = 10;
    wi.g.x = 10;
    wi.text = "Start SpiROSE";
    wi.customDraw = NULL;
    wi.g.parent = mainContainer;
    gButton1 = gwinButtonCreate(0, &wi);
    
    /* Button2 */
    wi.g.width = 160;
    wi.g.height = 30;
    wi.g.y = 10;
    wi.g.x = WIDTH-10-160;
    wi.text = "Stop SpiROSE";
    wi.g.parent = mainContainer;
    gButton2 = gwinButtonCreate(0, &wi);

    /* Slider */
    wi.g.width = WIDTH - 40;
    wi.g.height = 40;
    wi.g.y = 200;
    wi.g.x = 20;
    wi.text = "ROTATION";
    wi.g.parent = mainContainer;
    slider = gwinSliderCreate(0, &wi);
    
    /* Console */
    gwi.show = TRUE;
    gwi.x = 10;
    gwi.y = 50;
    gwi.width = WIDTH-20;
    gwi.height = 130;
    gwi.parent = mainContainer;
    console = gwinConsoleCreate(0, &gwi);

    // The container and all its children are visible
    gwinShow(mainContainer);

    gwinSetColor(console, Grey);
    gwinSetBgColor(console, White);
    gwinClear(console);

    // Print any data to the console
    gwinPrintf(console, "SpiROSE Status : WIP\nIMU Information:\nX acceleration:\nY acceleration:\nZ acceleration:\n");
    
    // We want to listen for widget events
    geventListenerInit(&gl);
    gwinAttachListener(&gl);
}

