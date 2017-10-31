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

#include <glm/glm.hpp>
#include <glm/gtx/transform.hpp>

void readFile(const std::string &filename, std::string &contents);
void onKey(GLFWwindow *window, int key, int scancode, int action, int mods);

GLuint loadShader(GLenum type, const char *filename);

bool wireframe = false;
GLuint prog = 0;

void loadShaders();

#ifdef OS_WIN32
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                   LPSTR lpCmdLine, int nCmdShow) {
#else
int main(int argc, char *argv[]) {
#endif
    // Load GLFW
    glfwInit();

    glfwWindowHint(GLFW_SAMPLES, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);

    GLFWwindow *window = glfwCreateWindow(1280, 720, "ROSE", nullptr, nullptr);
    glfwMakeContextCurrent(window);

    glfwSetInputMode(window, GLFW_STICKY_KEYS, GLFW_TRUE);
    glfwSetKeyCallback(window, onKey);

#ifndef OS_OSX
    // Load GLEW
    glewExperimental = GL_TRUE;
    glewInit();
#endif

    glViewport(0, 0, 1280, 720);

    // Main VAO
    GLuint vao;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    // Test buffer
    const int nSteps = 12, nDisks = 10;
    float vertices[3 * nSteps * 2 * nDisks * 2] = {0};
    for (int j = 0; j < nDisks; j++) {
        for (int i = 0; i < nSteps; i++) {
            vertices[(j * nSteps + i) * 12 + 0] =
                sin(2.f * M_PI * (0.5f + float(i)) / float(nSteps)) * float(j) *
                0.5f / float(nDisks);
            vertices[(j * nSteps + i) * 12 + 1] =
                cos(2.f * M_PI * (0.5f + float(i)) / float(nSteps)) * float(j) *
                0.5f / float(nDisks);
            vertices[(j * nSteps + i) * 12 + 2] =
                sin(2.f * M_PI * (0.5f + float(i)) / float(nSteps)) *
                float(j + 1) * 0.5f / float(nDisks);
            vertices[(j * nSteps + i) * 12 + 3] =
                cos(2.f * M_PI * (0.5f + float(i)) / float(nSteps)) *
                float(j + 1) * 0.5f / float(nDisks);
            vertices[(j * nSteps + i) * 12 + 4] =
                sin(2.f * M_PI * (0.5f + float(i + 1)) / float(nSteps)) *
                float(j + 1) * 0.5f / float(nDisks);
            vertices[(j * nSteps + i) * 12 + 5] =
                cos(2.f * M_PI * (0.5f + float(i + 1)) / float(nSteps)) *
                float(j + 1) * 0.5f / float(nDisks);

            vertices[(j * nSteps + i) * 12 + 6] =
                sin(2.f * M_PI * (0.5f + float(i + 1)) / float(nSteps)) *
                float(j) * 0.5f / float(nDisks);
            vertices[(j * nSteps + i) * 12 + 7] =
                cos(2.f * M_PI * (0.5f + float(i + 1)) / float(nSteps)) *
                float(j) * 0.5f / float(nDisks);
            vertices[(j * nSteps + i) * 12 + 8] =
                sin(2.f * M_PI * (0.5f + float(i)) / float(nSteps)) * float(j) *
                0.5f / float(nDisks);
            vertices[(j * nSteps + i) * 12 + 9] =
                cos(2.f * M_PI * (0.5f + float(i)) / float(nSteps)) * float(j) *
                0.5f / float(nDisks);
            vertices[(j * nSteps + i) * 12 + 10] =
                sin(2.f * M_PI * (0.5f + float(i + 1)) / float(nSteps)) *
                float(j + 1) * 0.5f / float(nDisks);
            vertices[(j * nSteps + i) * 12 + 11] =
                cos(2.f * M_PI * (0.5f + float(i + 1)) / float(nSteps)) *
                float(j + 1) * 0.5f / float(nDisks);
        }
    }

    GLuint buf;
    glGenBuffers(1, &buf);
    glBindBuffer(GL_ARRAY_BUFFER, buf);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW);

    // Shaders
    loadShaders();

    // Send vertex to shader
    GLint inPositionLoc = glGetAttribLocation(prog, "position");
    glVertexAttribPointer(inPositionLoc, 2, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(inPositionLoc);

    // Get time uniform
    GLint timePosition = glGetUniformLocation(prog, "time"),
          matMPosition = glGetUniformLocation(prog, "matModel"),
          matVPosition = glGetUniformLocation(prog, "matView"),
          matPPosition = glGetUniformLocation(prog, "matProjection");

    // Matricies
    glm::mat4 matModel = glm::mat4(1.f),
              matView = glm::lookAt(glm::vec3(-1.f, 1.f, 1.f), glm::vec3(0.f),
                                    glm::vec3(0.f, 0.f, 1.f)),
              matProjection =
                  glm::perspective(glm::radians(90.f), 16.f / 9.f, .1f, 100.f);

    glUniformMatrix4fv(matVPosition, 1, GL_FALSE, &matView[0][0]);
    glUniformMatrix4fv(matPPosition, 1, GL_FALSE, &matProjection[0][0]);

    while (!glfwWindowShouldClose(window)) {
        glfwSwapBuffers(window);
        glfwPollEvents();

        float time = glfwGetTime();

        glUniform1f(timePosition, time / 10.f);
        matModel = glm::translate(glm::vec3(
            (float)sin(time / 3.f) / 2.f, (float)sin(time * 5.f) / 20.f, 0.f));
        matModel = glm::rotate(matModel, time, glm::vec3(0, 0, 1));
        glUniformMatrix4fv(matMPosition, 1, GL_FALSE, &matModel[0][0]);

        glClear(GL_COLOR_BUFFER_BIT);
        if (wireframe)
            glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        else
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

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

void onKey(GLFWwindow *window, int key, int scancode, int action, int mods) {
    if (action != GLFW_PRESS) return;

    switch (key) {
        case GLFW_KEY_ESCAPE:
            glfwSetWindowShouldClose(window, GL_TRUE);
            break;
        case GLFW_KEY_Z:
            wireframe = !wireframe;
            break;
        case GLFW_KEY_R:
            loadShaders();
            break;
    }
}

GLuint loadShader(GLenum type, const char *filename) {
    std::string source;
    readFile(filename, source);
    const char *csource = source.c_str();
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &csource, NULL);
    glCompileShader(shader);

    GLint isOk;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &isOk);
    if (!isOk) {
        std::cerr << "[ERR] Shader " << filename << " compilation error"
                  << std::endl;

        // Getting the log
        GLint len = 0;
        GLchar *buf = NULL;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);
        buf = new GLchar[len];
        glGetShaderInfoLog(shader, len, NULL, buf);
        std::cerr << buf << std::endl;
        glDeleteShader(shader);

        return 0;
    }

    return shader;
}

void loadShaders() {
    prog = glCreateProgram();
    glAttachShader(prog, loadShader(GL_VERTEX_SHADER, "shader/basic.vs"));
    glAttachShader(prog, loadShader(GL_GEOMETRY_SHADER, "shader/basic.gs"));
    glAttachShader(prog, loadShader(GL_FRAGMENT_SHADER, "shader/basic.fs"));
    glBindFragDataLocation(prog, 0, "fragColor");
    glLinkProgram(prog);
    glUseProgram(prog);
}
