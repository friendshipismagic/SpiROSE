#include <cmath>

#include "spirose.h"

namespace spirose {

GLFWwindow* createWindow(int resW, int resH, int resC) {
    // Configure window. This depends on whether we are using GL or GLES
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
#ifdef GLES
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
    glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
    glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_EGL_CONTEXT_API);
#else
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, false);
#endif
    glfwWindowHint(GLFW_RESIZABLE, false);

    glm::ivec2 size = windowSize(resW, resH, resC);
    GLFWwindow* window =
        glfwCreateWindow(size.x, size.y, "SpiROSE", nullptr, nullptr);
    glfwMakeContextCurrent(window);

#if !defined(GLES)
    // Load GLEW
    glewExperimental = GL_TRUE;
    glewInit();
#endif

    return window;
}

glm::ivec2 windowSize(int resW, int resH, int resC) {
    int h = int(sqrt(resC));
    while (resC % h) h--;
    return glm::vec2(resC / h, h) * glm::vec2(resW / 2, resH);
}

}  // namespace spirose
