#include <libgen.h>
#include <spirose/spirose.h>
#include <iostream>

#define RES_W 80
#define RES_H 48
#define RES_C 128

void runTest(const std::string &testName, GLFWwindow *window,
             spirose::Context &context);

int main(int argc, char *argv[]) {
    glfwInit();
    GLFWwindow *window = spirose::createWindow(RES_W, RES_H, RES_C);
    spirose::Context context(RES_W, RES_H, RES_C);

    std::string name(basename(argv[0]));

    runTest(name, window, context);
}
