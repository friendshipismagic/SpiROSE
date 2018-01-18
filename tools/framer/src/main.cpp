#include <spirose/spirose.h>
#include <iostream>

int main(int argc, char *argv[]) {
    glfwInit();
    GLFWwindow *window = spirose::createWindow(80, 48, 256);
    spirose::Context context(80, 48, 256);

    // TODO

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
