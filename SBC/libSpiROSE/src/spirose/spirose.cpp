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
