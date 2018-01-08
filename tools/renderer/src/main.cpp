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

#include <unistd.h>
#include <cmath>
#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <vector>
#ifdef OS_WIN32
#include <windows.h>
#endif

#ifdef GLES
#define GLFW_INCLUDE_ES31
#define GLFW_INCLUDE_GLEXT
#define GL_BGRA GL_RGBA
#else
#define GLEW_STATIC
#define GL3_PROTOTYPES 1
#ifdef OS_OSX
#include <OpenGL/gl3.h>
#include <OpenGL/gl3ext.h>
#else
#include <GL/glew.h>
#endif
#define GLFW_INCLUDE_GLCOREARB
#endif
#include <GLFW/glfw3.h>

#include <glm/glm.hpp>
#include <glm/gtx/rotate_vector.hpp>
#include <glm/gtx/transform.hpp>

#include <tinyobjloader/tiny_obj_loader.h>
#include "tga.h"

void readFile(const std::string &filename, std::string &contents);
void onKey(GLFWwindow *window, int key, int scancode, int action, int mods);
void onButton(GLFWwindow *window, int button, int action, int mods);
void onMove(GLFWwindow *window, double x, double y);
void onGLFWError(int code, const char *desc);

GLuint loadShader(GLenum type, const std::string &filename);
void englobingRectangle(const int n, int &w, int &h);
int gcd(int a, int b) { return b == 0 ? a : gcd(b, a % b); }

typedef struct RenderOptions {
    bool wireframe, pause, pizza, useXor;
    int nDrawBuffer, nVoxelPass;
} RenderOptions;
RenderOptions renderOptions = {.wireframe = false,
                               .pause = false,
                               .pizza = false,
                               .useXor = false,
                               .nDrawBuffer = 0,
                               .nVoxelPass = 0};

bool clicking = false, doDump = false;
float t = 0.f;

// 0 is useXor == false, 1 is useXor == true
struct Program {
    GLuint voxel, offscreen, generate, interlace;
} program[2] = {{0}};

// Camera data
float yaw = 0.f, pitch = M_PI / 4.f, zoom = 2.f;
glm::vec3 camForward, camRight, camLook;

// Real framebuffer width and height taking high-DPI scaling into account
int fbWidth, fbHeight;

// Grids sizes for the interlace viewer
int dispInterlaceW, dispInterlaceH;

#define RES_W 80
#define RES_H 48
#define RES_C 64
#define N_BUF_NO_XOR (RES_H / 4)

void loadShaders();

#ifdef OS_WIN32
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                   LPSTR lpCmdLine, int nCmdShow) {
    // Declared in stdlib.h, populated by windows itself...
    int argc = __argc;
    char **argv = __argv;
#else
int main(int argc, char *argv[]) {
#endif
    // Command line options
    int c;
    std::string meshFile = "mesh/suzanne-tight.obj";
    while ((c = getopt(argc, argv, "wpcxt:m:")) != -1) switch (c) {
            case 'w':
                renderOptions.wireframe = true;
                break;
            case 'p':
                renderOptions.pause = true;
                break;
            case 'c':
                renderOptions.pizza = true;
                break;
            case 'x':
                renderOptions.useXor = true;
                break;
            case 't':
                t = atof(optarg);
                break;
            case 'm':
                meshFile = optarg;
                break;

            case '?':
            default:
                return -1;
                break;
        }

    // Load GLFW
    glfwInit();

    glfwSetErrorCallback(onGLFWError);

#ifdef GLES
    glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
    glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_EGL_CONTEXT_API);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
#else
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif
    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);

    GLFWwindow *window = glfwCreateWindow(1280, 720, "ROSE", nullptr, nullptr);
    glfwMakeContextCurrent(window);
    glfwGetFramebufferSize(window, &fbWidth, &fbHeight);

    glfwSetInputMode(window, GLFW_STICKY_KEYS, GLFW_TRUE);
    glfwSetKeyCallback(window, onKey);
    glfwSetMouseButtonCallback(window, onButton);
    glfwSetCursorPosCallback(window, onMove);

#if !defined(OS_OSX) && !defined(GLES)
    // Load GLEW
    glewExperimental = GL_TRUE;
    glewInit();
#endif

    glViewport(0, 0, fbWidth, fbHeight);

    // Determine how many draw buffer we can have
    int maxDrawBufferCount;
    glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &maxDrawBufferCount);
    renderOptions.nDrawBuffer = gcd(N_BUF_NO_XOR, maxDrawBufferCount);
    renderOptions.nVoxelPass = N_BUF_NO_XOR / renderOptions.nDrawBuffer;
    if (renderOptions.nDrawBuffer != N_BUF_NO_XOR)
        std::cout << "[WARN] GPU only has " << maxDrawBufferCount
                  << " draw buffers. Voxelization will be done in "
                  << renderOptions.nVoxelPass << " passes using "
                  << renderOptions.nDrawBuffer << " buffers." << std::endl;

    // Compute size of display textures
    englobingRectangle(RES_C, dispInterlaceW, dispInterlaceH);

    // Load suzanne
    tinyobj::attrib_t attrib;
    std::vector<tinyobj::shape_t> shapes;
    std::vector<tinyobj::material_t> materials;
    std::string err;
    bool ret =
        tinyobj::LoadObj(&attrib, &shapes, &materials, &err, meshFile.c_str());
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
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(0);

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
    struct Uniform {
        struct {
            GLint time, matM, matV, matP, doPizza, nPass;
        } voxel;
        struct {
            GLint matM, matV, matP, doPizza;
            GLint tex[N_BUF_NO_XOR];
        } generate;
        struct {
            GLint doPizza;
            GLint tex[N_BUF_NO_XOR];
        } interlace;
        struct {
            GLint tex[N_BUF_NO_XOR];
        } offscreen;
    } uniforms[2];

    for (int i = 0; i < 2; i++) {
        struct Uniform *u = &uniforms[i];
        struct Program *s = &program[i];

        u->voxel.time = glGetUniformLocation(s->voxel, "time");
        u->voxel.matM = glGetUniformLocation(s->voxel, "matModel");
        u->voxel.matV = glGetUniformLocation(s->voxel, "matView");
        u->voxel.matP = glGetUniformLocation(s->voxel, "matProjection");
        u->voxel.doPizza = glGetUniformLocation(s->voxel, "doPizza");
        u->voxel.nPass = glGetUniformLocation(s->voxel, "nPass");

        u->generate.matM = glGetUniformLocation(s->generate, "matModel");
        u->generate.matV = glGetUniformLocation(s->generate, "matView");
        u->generate.matP = glGetUniformLocation(s->generate, "matProjection");
        u->generate.doPizza = glGetUniformLocation(s->generate, "doPizza");

        u->interlace.doPizza = glGetUniformLocation(s->interlace, "doPizza");

        for (int i = 0; i < N_BUF_NO_XOR; i++)
            u->offscreen.tex[i] = glGetUniformLocation(
                s->offscreen, ("tex" + std::to_string(i)).c_str());
        for (int i = 0; i < N_BUF_NO_XOR; i++)
            u->generate.tex[i] = glGetUniformLocation(
                s->generate, ("voxels" + std::to_string(i)).c_str());
        for (int i = 0; i < N_BUF_NO_XOR; i++)
            u->interlace.tex[i] = glGetUniformLocation(
                s->interlace, ("tex" + std::to_string(i)).c_str());
    }

    // Matricies
    float resRatio = float(RES_W) / float(RES_H);
    glm::mat4 matModel = glm::mat4(1.f), matView = glm::mat4(1.f),
              matProjection =
                  glm::perspective(glm::radians(90.f), 16.f / 9.f, .1f, 100.f),
              matOrtho = glm::ortho(-resRatio, resRatio, -resRatio, resRatio,
                                    -1.f, 1.f);

    glUniformMatrix4fv(uniforms[renderOptions.useXor].voxel.matV, 1, GL_FALSE,
                       &matView[0][0]);
    glUniformMatrix4fv(uniforms[renderOptions.useXor].voxel.matP, 1, GL_FALSE,
                       &matProjection[0][0]);

    // Framebuffer to store our voxel thingy
    GLuint fbo, texVoxelBufs[N_BUF_NO_XOR];
    GLenum drawBuffers[N_BUF_NO_XOR];
    for (int i = 0; i < renderOptions.nDrawBuffer; i++)
        drawBuffers[i] = GL_COLOR_ATTACHMENT0 + (i % renderOptions.nDrawBuffer);
    glGenFramebuffers(1, &fbo);
    // We will still generate all textures as we'll swap them at each pass
    glGenTextures(renderOptions.nDrawBuffer, texVoxelBufs);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    for (int i = 0; i < renderOptions.nDrawBuffer; i++) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, texVoxelBufs[i]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
                     RES_W * renderOptions.nVoxelPass, RES_W, 0, GL_RGBA,
                     GL_UNSIGNED_BYTE, NULL);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glFramebufferTexture2D(GL_FRAMEBUFFER, drawBuffers[i], GL_TEXTURE_2D,
                               texVoxelBufs[i], 0);
        // Test framebuffer status
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
            std::cerr << "[ERR] Incomplete framebuffer "
                      << (i / renderOptions.nDrawBuffer) << std::endl;
    }
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glDrawBuffers(renderOptions.nDrawBuffer, drawBuffers);

    // Small square to texture with the final image
    GLuint vaoSquare, vboSquare;
    glGenVertexArrays(1, &vaoSquare);
    glBindVertexArray(vaoSquare);
    float vert[] = {// Interlave pos and UV
                    -1, -1, 0, 0, 1, 1, 1, 1, -1, 1,  0, 1,
                    -1, -1, 0, 0, 1, 1, 1, 1, 1,  -1, 1, 0};
    glGenBuffers(1, &vboSquare);
    glBindBuffer(GL_ARRAY_BUFFER, vboSquare);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vert), vert, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), 0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float),
                          (void *)(2 * sizeof(float)));
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);

    // Set of points to render the voxels
    float voxPoints[RES_W * RES_W * RES_H * 3] = {0.f};
    for (int i = 0; i < RES_W; i++)
        for (int j = 0; j < RES_W; j++)
            for (int k = 0; k < RES_H; k++) {
                voxPoints[3 * (RES_H * (i * RES_W + j) + k) + 0] =
                    (float(i) - float(RES_W / 2)) / float(RES_H / 2);
                voxPoints[3 * (RES_H * (i * RES_W + j) + k) + 1] =
                    (float(j) - float(RES_W / 2)) / float(RES_H / 2);
                voxPoints[3 * (RES_H * (i * RES_W + j) + k) + 2] =
                    (float(k) - float(RES_H / 2)) / float(RES_H / 2);
            }
    GLuint vaoVox, vboVox;
    glGenVertexArrays(1, &vaoVox);
    glBindVertexArray(vaoVox);
    glGenBuffers(1, &vboVox);
    glBindBuffer(GL_ARRAY_BUFFER, vboVox);
    glBufferData(GL_ARRAY_BUFFER, sizeof(voxPoints), voxPoints, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(0);

    // Simulate mouse move
    clicking = true;
    onMove(window, 0, 0);
    clicking = false;

    while (!glfwWindowShouldClose(window)) {
        glfwSwapBuffers(window);
        glfwPollEvents();

        if (!renderOptions.pause) t = glfwGetTime();

        std::string title = "ROSE /// [w] wireframe ";
        title += std::to_string(renderOptions.wireframe);
        title += " / [p] pause ";
        title += std::to_string(renderOptions.pause);
        title += " / [c] pizza ";
        title += std::to_string(renderOptions.pizza);
        title += " / [x] xor ";
        title += std::to_string(renderOptions.useXor);
        title += " / time ";
        title += std::to_string(t);
        glfwSetWindowTitle(window, title.c_str());

        //// Voxelization
        glBindVertexArray(vao);
        glUseProgram(program[renderOptions.useXor].voxel);
        glUniformMatrix4fv(uniforms[renderOptions.useXor].voxel.matP, 1,
                           GL_FALSE, &matOrtho[0][0]);
        glUniform1ui(uniforms[renderOptions.useXor].voxel.doPizza,
                     renderOptions.pizza);

        matView = glm::lookAt(glm::vec3(0.f), glm::vec3(0.f, 0.f, -1.f),
                              glm::vec3(0.f, 1.f, 0.f));
        glUniformMatrix4fv(uniforms[renderOptions.useXor].voxel.matV, 1,
                           GL_FALSE, &matView[0][0]);

        glUniform1f(uniforms[renderOptions.useXor].voxel.time, t / 10.f);
        matModel = glm::translate(glm::vec3((float)sin(t / 3.f) / 2.f,
                                            (float)sin(t * 5.f) / 20.f, 0.f));
        matModel = glm::rotate(matModel, t, glm::vec3(0, 0, 1));
        glUniformMatrix4fv(uniforms[renderOptions.useXor].voxel.matM, 1,
                           GL_FALSE, &matModel[0][0]);

#ifndef GLES
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
#endif

        if (renderOptions.useXor) {
#ifndef GLES
            glEnable(GL_COLOR_LOGIC_OP);
            glLogicOp(GL_XOR);
#endif
        } else {
            glEnable(GL_BLEND);
            glBlendFunc(GL_ONE, GL_ONE);
        }
        glDisable(GL_DEPTH_TEST);
        glEnable(GL_SCISSOR_TEST);

        // Rendering
        glBindVertexArray(vao);
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        for (int i = 0; i < renderOptions.nVoxelPass; i++) {
            glViewport(RES_W * i, 0, RES_W, RES_W);
            glScissor(RES_W * i, 0, RES_W, RES_W);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glUniform1i(uniforms[renderOptions.useXor].voxel.nPass, i);
            glDrawElements(GL_TRIANGLES, mesh.indices.size(), GL_UNSIGNED_INT,
                           0);
        }
        glDisable(GL_SCISSOR_TEST);

        // Dump the FBO if required
        if (doDump) {
            GLuint pixels[RES_W * RES_W * 4] = {0};
            glPixelStorei(GL_PACK_ALIGNMENT, 1);
            if (renderOptions.useXor) {
                glReadBuffer(GL_COLOR_ATTACHMENT0);
                // Use BGRA as TGA swaps red and blue
                glReadPixels(0, 0, RES_W, RES_W, GL_BGRA, GL_UNSIGNED_BYTE,
                             pixels);
                saveTGA("output.tga", pixels, RES_W, RES_W, 32);
                std::cout << "[INFO] Dumped FBO to output.tga" << std::endl;
            } else
                for (int i = 0; i < renderOptions.nDrawBuffer; i++) {
                    glReadBuffer(GL_COLOR_ATTACHMENT0 + i);
                    glReadPixels(0, 0, RES_W * renderOptions.nVoxelPass, RES_W,
                                 GL_BGRA, GL_UNSIGNED_BYTE, pixels);
                    saveTGA("output" + std::to_string(i) + ".tga", pixels,
                            RES_W * renderOptions.nVoxelPass, RES_W, 32);
                    std::cout << "[INFO] Dumped FBO layer " << i << " to output"
                              << i << ".tga" << std::endl;
                }
            doDump = false;
        }
        glBindFramebuffer(GL_FRAMEBUFFER, 0);

#ifndef GLES
        glDisable(renderOptions.useXor ? GL_COLOR_LOGIC_OP : GL_BLEND);
#else
        glDisable(GL_BLEND);
#endif
        //// Display 3D voxels
        glViewport(0, 0, fbWidth, fbHeight);
        glEnable(GL_DEPTH_TEST);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

#ifndef GLES
        if (renderOptions.wireframe)
            glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        else
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
#endif
        glUseProgram(program[renderOptions.useXor].generate);

        glUniformMatrix4fv(uniforms[renderOptions.useXor].generate.matP, 1,
                           GL_FALSE, &matProjection[0][0]);
        matView = glm::lookAt(camLook * -zoom, glm::vec3(0.f),
                              -glm::cross(camRight, camLook));
        glUniformMatrix4fv(uniforms[renderOptions.useXor].generate.matV, 1,
                           GL_FALSE, &matView[0][0]);
        matModel = glm::mat4(1.f);
        glUniformMatrix4fv(uniforms[renderOptions.useXor].generate.matM, 1,
                           GL_FALSE, &matModel[0][0]);
        glUniform1ui(uniforms[renderOptions.useXor].generate.doPizza,
                     renderOptions.pizza);
        for (int i = 0; i < N_BUF_NO_XOR; i++)
            glUniform1i(uniforms[renderOptions.useXor].generate.tex[i], i);

        glBindVertexArray(vaoVox);
#ifndef GLES
        glPointSize(10.f);
#endif
        glDrawArrays(GL_POINTS, 0, sizeof(voxPoints) / sizeof(float) / 3);

#ifndef GLES
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
#endif
        //// Interlace voxels
        glViewport(fbWidth - RES_W * dispInterlaceH, 0, RES_W * dispInterlaceH,
                   RES_H * dispInterlaceW);
        glBindVertexArray(vaoSquare);
        glUseProgram(program[renderOptions.useXor].interlace);
        glUniform1ui(uniforms[renderOptions.useXor].interlace.doPizza,
                     renderOptions.pizza);
        for (int i = 0; i < N_BUF_NO_XOR; i++)
            glUniform1i(uniforms[renderOptions.useXor].interlace.tex[i], i);
        glDrawArrays(GL_TRIANGLES, 0, sizeof(vert) / sizeof(float));

        //// Displaying the voxel texture
        if (renderOptions.useXor)
            glViewport(0, 0, RES_W, RES_W);
        else
            glViewport(0, 0, RES_W * 3, RES_W * 4);
        glBindVertexArray(vaoSquare);
        glUseProgram(program[renderOptions.useXor].offscreen);
        for (int i = 0; i < N_BUF_NO_XOR; i++)
            glUniform1i(uniforms[renderOptions.useXor].offscreen.tex[i], i);
        glDrawArrays(GL_TRIANGLES, 0, sizeof(vert) / sizeof(float));
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
                t += 0.01;
                break;
            case GLFW_KEY_LEFT:
                t -= 0.01;
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
            renderOptions.wireframe = !renderOptions.wireframe;
            break;
        case GLFW_KEY_R:
            loadShaders();
            break;
        case GLFW_KEY_P:
            renderOptions.pause = !renderOptions.pause;
            break;
        case GLFW_KEY_RIGHT:
            t += 0.01;
            break;
        case GLFW_KEY_LEFT:
            t -= 0.01;
            break;
        case GLFW_KEY_UP:
            zoom += 0.01;
            break;
        case GLFW_KEY_DOWN:
            zoom -= 0.01;
            break;
        case GLFW_KEY_C:
            renderOptions.pizza = !renderOptions.pizza;
            break;
        case GLFW_KEY_X:
            renderOptions.useXor = !renderOptions.useXor;
            break;
        case GLFW_KEY_S:
            doDump = true;
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

GLuint loadShader(GLenum type, const std::string &filename) {
    // Determine shader extension
    const std::map<GLenum, std::string> exts = {{GL_VERTEX_SHADER, "vs"},
#ifdef GL_GEOMETRY_SHADER
                                                {GL_GEOMETRY_SHADER, "gs"},
#endif
                                                {GL_FRAGMENT_SHADER, "fs"}};
    std::string path = "shader/" + filename + "." + exts.at(type), source;
    readFile(path, source);

    // Craft defines containing useful constants
    std::string defines =
        "#define N_VOXEL_PASS " + std::to_string(renderOptions.nVoxelPass) +
        "\n#define N_DRAW_BUFFER " + std::to_string(renderOptions.nDrawBuffer) +
        "\n#define RES_W " + std::to_string(RES_W) + "\n#define RES_H " +
        std::to_string(RES_H) + "\n#define RES_C " + std::to_string(RES_C) +
        "\n#define DISP_INTERLACE_W " + std::to_string(dispInterlaceW) +
        "\n#define DISP_INTERLACE_H " + std::to_string(dispInterlaceH) + "\n";
    const char *csource[] = {
// GL and GLES have different version syntaxes...
#ifdef GLES
        "#version 300 es\n\n",
        // GLES needs an explicit float precision declaration
        "precision highp float;\n",
#else
        "#version 330 core\n\n",
#endif
/* For some shaders (mainly voxel), some critical operations are done in the
 * geometry shader (e.g. MVP matrix application). For such shaders, we need to
 * apply those operations in the vertex shader rather than in the geometry
 * shader.
 */
#ifdef GL_GEOMETRY_SHADER
        "#define HAS_GEOMETRY_SHADER\n\n",
#endif
        defines.c_str(), source.c_str()};
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, sizeof(csource) / sizeof(char *), csource, NULL);
    glCompileShader(shader);

    GLint isOk;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &isOk);
    if (!isOk) {
        std::cerr << "[ERR] Shader " << filename << "." << exts.at(type)
                  << " compilation error" << std::endl;

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
    GLuint voxelV = loadShader(GL_VERTEX_SHADER, "voxel"),
           voxelFX = loadShader(GL_FRAGMENT_SHADER, "voxel"),
           voxelF = loadShader(GL_FRAGMENT_SHADER, "voxel-noxor"),
           offscreenV = loadShader(GL_VERTEX_SHADER, "offscreen"),
           offscreenFX = loadShader(GL_FRAGMENT_SHADER, "offscreen"),
           offscreenF = loadShader(GL_FRAGMENT_SHADER, "offscreen-noxor"),
           generateVX = loadShader(GL_VERTEX_SHADER, "generate"),
           generateV = loadShader(GL_VERTEX_SHADER, "generate-noxor"),
           generateF = loadShader(GL_FRAGMENT_SHADER, "generate"),
           interlaceFX = loadShader(GL_FRAGMENT_SHADER, "interlace"),
           interlaceF = loadShader(GL_FRAGMENT_SHADER, "interlace-noxor");
#ifdef GL_GEOMETRY_SHADER
    GLuint voxelG = loadShader(GL_GEOMETRY_SHADER, "voxel"),
           generateGX = loadShader(GL_GEOMETRY_SHADER, "generate"),
           generateG = loadShader(GL_GEOMETRY_SHADER, "generate-noxor");
#endif

    // Load non-XOR shaders
    program[0].voxel = glCreateProgram();
    glAttachShader(program[0].voxel, voxelV);
#ifdef GL_GEOMETRY_SHADER
    glAttachShader(program[0].voxel, voxelG);
#endif
    glAttachShader(program[0].voxel, voxelF);
    glLinkProgram(program[0].voxel);

    program[0].offscreen = glCreateProgram();
    glAttachShader(program[0].offscreen, offscreenV);
    glAttachShader(program[0].offscreen, offscreenF);
    glLinkProgram(program[0].offscreen);

    program[0].generate = glCreateProgram();
    glAttachShader(program[0].generate, generateV);
#ifdef GL_GEOMETRY_SHADER
    glAttachShader(program[0].generate, generateG);
#endif
    glAttachShader(program[0].generate, generateF);
    glLinkProgram(program[0].generate);

    program[0].interlace = glCreateProgram();
    glAttachShader(program[0].interlace, offscreenV);
    glAttachShader(program[0].interlace, interlaceF);
    glLinkProgram(program[0].interlace);

    // Load XOR shaders
    program[1].voxel = glCreateProgram();
    glAttachShader(program[1].voxel, voxelV);
#ifdef GL_GEOMETRY_SHADER
    glAttachShader(program[1].voxel, voxelG);
#endif
    glAttachShader(program[1].voxel, voxelFX);
    glLinkProgram(program[1].voxel);

    program[1].offscreen = glCreateProgram();
    glAttachShader(program[1].offscreen, offscreenV);
    glAttachShader(program[1].offscreen, offscreenFX);
    glLinkProgram(program[1].offscreen);

    program[1].generate = glCreateProgram();
    glAttachShader(program[1].generate, generateVX);
#ifdef GL_GEOMETRY_SHADER
    glAttachShader(program[1].generate, generateGX);
#endif
    glAttachShader(program[1].generate, generateF);
    glLinkProgram(program[1].generate);

    program[1].interlace = glCreateProgram();
    glAttachShader(program[1].interlace, offscreenV);
    glAttachShader(program[1].interlace, interlaceFX);
    glLinkProgram(program[1].interlace);
}
void onGLFWError(int code, const char *desc) {
    std::cerr << "[ERR] GLFW error " << code << ": " << desc << std::endl;
}

void englobingRectangle(const int n, int &w, int &h) {
    h = int(sqrt(n)) & ~1;
    w = n / h;
}
