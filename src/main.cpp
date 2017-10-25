/**
 * The MIT License (MIT)
 * Copyright (c) 2017 Tuetuopay
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 **/

#include <cmath>
#include <fstream>
#include <iostream>
#include <string>
#ifdef OS_WIN32
#include <windows.h>
#endif

#define GLEW_STATIC
#define GL3_PROTOTYPES 1
#ifdef OS_OSX
#include <OpenGL/gl3.h>
#include <OpenGL/gl3ext.h>
#else
#include <GL/glew.h>
#endif
#define GLFW_INCLUDE_GLCOREARB
#include <GLFW/glfw3.h>

void readFile(const std::string &filename, std::string &contents);

#ifdef OS_WIN32
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                   LPSTR lpCmdLine, int nCmdShow) {
#else
int main(int argc, char *argv[]) {
#endif
    // Load GLFW
    glfwInit();

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 4);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);

    GLFWwindow *window = glfwCreateWindow(1280, 720, "ROSE", nullptr, nullptr);
    glfwMakeContextCurrent(window);

#ifndef OS_OSX
    // Load GLEW
    glewExperimental = GL_TRUE;
    glewInit();
#endif

    // Main VAO
    GLuint vao;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    // Test buffer
    float vertices[3 * 12 * 2] = {0};
    for (int i = 0; i < 12; i++) {
        vertices[i * 6] = vertices[i * 6 + 1] = 0;
        vertices[i * 6 + 2] = sin(2.f * M_PI * float(i) / 12.f) * 0.5f;
        vertices[i * 6 + 3] = cos(2.f * M_PI * float(i) / 12.f) * 0.5f;
        vertices[i * 6 + 4] = sin(2.f * M_PI * float(i + 1) / 12.f) * 0.5f;
        vertices[i * 6 + 5] = cos(2.f * M_PI * float(i + 1) / 12.f) * 0.5f;
    }

    GLuint buf;
    glGenBuffers(1, &buf);
    glBindBuffer(GL_ARRAY_BUFFER, buf);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW);

    // Shaders
    std::string fss, vss;
    readFile("shader/basic.fs", fss);
    readFile("shader/basic.vs", vss);
    const char *_fss = fss.c_str(), *_vss = vss.c_str();
    GLuint vs = glCreateShader(GL_VERTEX_SHADER),
           fs = glCreateShader(GL_FRAGMENT_SHADER), prog = glCreateProgram();
    glShaderSource(vs, 1, &_vss, NULL);
    glShaderSource(fs, 1, &_fss, NULL);
    glCompileShader(vs);
    glCompileShader(fs);
    glAttachShader(prog, vs);
    glAttachShader(prog, fs);
    glBindFragDataLocation(prog, 0, "fragColor");
    glLinkProgram(prog);
    glUseProgram(prog);

    // Send vertex to shader
    GLint inPositionLoc = glGetAttribLocation(prog, "position");
    glVertexAttribPointer(inPositionLoc, 2, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(inPositionLoc);

    while (!glfwWindowShouldClose(window)) {
        glfwSwapBuffers(window);
        glfwPollEvents();

        if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
            glfwSetWindowShouldClose(window, GL_TRUE);

        // Rendering
        glDrawArrays(GL_TRIANGLES, 0, sizeof(vertices) / sizeof(float));
    }

    glfwTerminate();
    return 0;
}

void readFile(const std::string &filename, std::string &contents) {
    std::ifstream s(filename);
    s.seekg(0, std::ios::end);
    contents.reserve(s.tellg());
    s.seekg(0, std::ios::beg);

    contents.assign((std::istreambuf_iterator<char>(s)),
                    std::istreambuf_iterator<char>());
}
