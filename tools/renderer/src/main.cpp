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
#include <vector>
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
#include <glm/gtx/rotate_vector.hpp>
#include <glm/gtx/transform.hpp>

#include <tinyobjloader/tiny_obj_loader.h>

void readFile(const std::string &filename, std::string &contents);
void onKey(GLFWwindow *window, int key, int scancode, int action, int mods);
void onButton(GLFWwindow *window, int button, int action, int mods);
void onMove(GLFWwindow *window, double x, double y);

GLuint loadShader(GLenum type, const char *filename);

bool wireframe = false, pause = false, clicking = false;
float time = 0.f;
GLuint progVoxel;

// Camera data
float yaw = 0.f, pitch = M_PI / 4.f, zoom = 2.f;
glm::vec3 camForward, camRight, camLook;

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
    glfwSetMouseButtonCallback(window, onButton);
    glfwSetCursorPosCallback(window, onMove);

#ifndef OS_OSX
    // Load GLEW
    glewExperimental = GL_TRUE;
    glewInit();
#endif

    glViewport(0, 0, 1280, 720);
    // glEnable(GL_DEPTH_TEST);

    // Load suzanne
    tinyobj::attrib_t attrib;
    std::vector<tinyobj::shape_t> shapes;
    std::vector<tinyobj::material_t> materials;
    std::string err;
    bool ret = tinyobj::LoadObj(&attrib, &shapes, &materials, &err,
                                "mesh/suzanne.obj");
    if (!err.empty()) std::cerr << "[ERR] " << err << std::endl;
    if (!ret) return -1;

    // Use first mesh
    auto &mesh = shapes[0].mesh;

    // Main VAO
    GLuint vao;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    // Vertex buffer
    GLuint buf;
    glGenBuffers(1, &buf);
    glBindBuffer(GL_ARRAY_BUFFER, buf);
    glBufferData(GL_ARRAY_BUFFER, attrib.vertices.size() * sizeof(float),
                 &attrib.vertices[0], GL_DYNAMIC_DRAW);

    // Index buffer
    unsigned int *indexes = new unsigned int[mesh.indices.size()];
    for (unsigned int i = 0; i < mesh.indices.size(); i++)
        indexes[i] = (unsigned int)mesh.indices[i].vertex_index;
    GLuint ibuf;
    glGenBuffers(1, &ibuf);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibuf);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, mesh.indices.size() * sizeof(int),
                 indexes, GL_DYNAMIC_DRAW);

    // Shaders
    loadShaders();

    // Send vertex to shader
    GLint inPositionLoc = glGetAttribLocation(progVoxel, "position");
    glVertexAttribPointer(inPositionLoc, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(inPositionLoc);

    // Get time uniform
    GLint timePosition = glGetUniformLocation(progVoxel, "time"),
          matMPosition = glGetUniformLocation(progVoxel, "matModel"),
          matVPosition = glGetUniformLocation(progVoxel, "matView"),
          matPPosition = glGetUniformLocation(progVoxel, "matProjection");

    // Matricies
    glm::mat4 matModel = glm::mat4(1.f), matView = glm::mat4(1.f),
              matProjection =
                  glm::perspective(glm::radians(90.f), 16.f / 9.f, .1f, 100.f),
              matOrtho = glm::ortho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f);

    glUniformMatrix4fv(matVPosition, 1, GL_FALSE, &matView[0][0]);
    glUniformMatrix4fv(matPPosition, 1, GL_FALSE, &matProjection[0][0]);

    // Simulate mouse move
    clicking = true;
    onMove(window, 0, 0);
    clicking = false;

    while (!glfwWindowShouldClose(window)) {
        glfwSwapBuffers(window);
        glfwPollEvents();

        if (!pause) time = glfwGetTime();

        //// Voxelization
        glBindVertexArray(vao);
        glUseProgram(progVoxel);
        glUniformMatrix4fv(matPPosition, 1, GL_FALSE, &matOrtho[0][0]);

        matView = glm::lookAt(camLook * -zoom, glm::vec3(0.f),
                              -glm::cross(camRight, camLook));
        matView = glm::lookAt(glm::vec3(0.f, 0.f, 1.f), glm::vec3(0.f),
                              glm::vec3(0.f, 1.f, 0.f));
        glUniformMatrix4fv(matVPosition, 1, GL_FALSE, &matView[0][0]);

        glUniform1f(timePosition, time / 10.f);
        matModel = glm::translate(glm::vec3(
            (float)sin(time / 3.f) / 2.f, (float)sin(time * 5.f) / 20.f, 0.f));
        matModel = glm::rotate(matModel, time, glm::vec3(0, 0, 1));
        matModel = glm::scale(matModel, glm::vec3(.5f));
        glUniformMatrix4fv(matMPosition, 1, GL_FALSE, &matModel[0][0]);

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        if (wireframe)
            glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        else
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        glEnable(GL_COLOR_LOGIC_OP);
        glLogicOp(GL_XOR);

        // Rendering
        glDrawElements(GL_TRIANGLES, mesh.indices.size(), GL_UNSIGNED_INT, 0);
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
    if (action == GLFW_REPEAT) {
        switch (key) {
            case GLFW_KEY_RIGHT:
                time += 0.01;
                break;
            case GLFW_KEY_LEFT:
                time -= 0.01;
                break;
            case GLFW_KEY_UP:
                zoom += 0.01;
                break;
            case GLFW_KEY_DOWN:
                zoom -= 0.01;
                break;
        }
    }
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
        case GLFW_KEY_P:
            pause = !pause;
            break;
        case GLFW_KEY_RIGHT:
            time += 0.01;
            break;
        case GLFW_KEY_LEFT:
            time -= 0.01;
            break;
        case GLFW_KEY_UP:
            zoom += 0.01;
            break;
        case GLFW_KEY_DOWN:
            zoom -= 0.01;
            break;
    }
}
void onButton(GLFWwindow *window, int button, int action, int mods) {
    if (button == GLFW_MOUSE_BUTTON_LEFT) clicking = action == GLFW_PRESS;
}
void onMove(GLFWwindow *window, double x, double y) {
    static double lastX = 0, lastY = 0;
    double dx = x - lastX, dy = y - lastY;
    lastX = x;
    lastY = y;

    if (!clicking) return;

    yaw -= dx / 250.f;
    pitch += dy / 250.f;

    // Keep yaw between 0 and 2pi
    yaw = yaw > 2.0 * M_PI ? yaw - 2.0 * M_PI
                           : (yaw < 0.0 ? yaw + 2.0 * M_PI : yaw);
    // Keep pitch between -pi/2 and pi/2
    pitch = fmax(fmin(pitch, M_PI / 2.0), -M_PI / 2.0);

    // Recompute camera vectors
    camForward =
        glm::rotate(glm::vec3(1.f, 0.f, 0.f), yaw, glm::vec3(0.f, 0.f, 1.f));
    camRight = glm::vec3(-camForward.y, camForward.x, 0.f);
    camLook = glm::rotate(
        glm::rotate(glm::vec3(1.f, 0.f, 0.f), pitch, glm::vec3(0.f, 1.f, 0.f)),
        yaw, glm::vec3(0.f, 0.f, 1.f));
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
    progVoxel = glCreateProgram();
    glAttachShader(progVoxel, loadShader(GL_VERTEX_SHADER, "shader/voxel.vs"));
    glAttachShader(progVoxel,
                   loadShader(GL_GEOMETRY_SHADER, "shader/voxel.gs"));
    glAttachShader(progVoxel,
                   loadShader(GL_FRAGMENT_SHADER, "shader/voxel.fs"));
    glBindFragDataLocation(progVoxel, 0, "fragColor");
    glLinkProgram(progVoxel);
    glUseProgram(progVoxel);
}
