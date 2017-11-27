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

GLuint loadShader(GLenum type, const std::string &filename);

typedef struct RenderOptions {
    bool wireframe, pause, pizza;
} RenderOptions;
RenderOptions renderOptions = {
    .wireframe = false, .pause = false, .pizza = false};

bool clicking = false;
float t = 0.f;
GLuint progVoxel, progOffscreen, progGenerate, progInterlace;

// Camera data
float yaw = 0.f, pitch = M_PI / 4.f, zoom = 2.f;
glm::vec3 camForward, camRight, camLook;

// Real framebuffer width and height taking high-DPI scaling into account
int fbWidth, fbHeight;

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
    char c;
    while ((c = getopt(argc, argv, "wpc")) != -1) switch (c) {
            case 'w':
                renderOptions.wireframe = true;
                break;
            case 'p':
                renderOptions.pause = true;
                break;
            case 'c':
                renderOptions.pizza = true;
                break;

            case '?':
            default:
                return -1;
                break;
        }

    // Load GLFW
    glfwInit();

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);

    GLFWwindow *window = glfwCreateWindow(1280, 720, "ROSE", nullptr, nullptr);
    glfwMakeContextCurrent(window);
    glfwGetFramebufferSize(window, &fbWidth, &fbHeight);

    glfwSetInputMode(window, GLFW_STICKY_KEYS, GLFW_TRUE);
    glfwSetKeyCallback(window, onKey);
    glfwSetMouseButtonCallback(window, onButton);
    glfwSetCursorPosCallback(window, onMove);

#ifndef OS_OSX
    // Load GLEW
    glewExperimental = GL_TRUE;
    glewInit();
#endif

    glViewport(0, 0, fbWidth, fbHeight);
    // glEnable(GL_DEPTH_TEST);

    // Load suzanne
    tinyobj::attrib_t attrib;
    std::vector<tinyobj::shape_t> shapes;
    std::vector<tinyobj::material_t> materials;
    std::string err;
    bool ret = tinyobj::LoadObj(&attrib, &shapes, &materials, &err,
                                "mesh/suzanne-tight.obj");
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
          matPPosition = glGetUniformLocation(progVoxel, "matProjection"),
          doPizzaPosition = glGetUniformLocation(progVoxel, "doPizza");
    GLint matMPositionGen = glGetUniformLocation(progGenerate, "matModel"),
          matVPositionGen = glGetUniformLocation(progGenerate, "matView"),
          matPPositionGen = glGetUniformLocation(progGenerate, "matProjection"),
          doPizzaPositionGen = glGetUniformLocation(progGenerate, "doPizza");
    GLint doPizzaPositionInt = glGetUniformLocation(progInterlace, "doPizza");

    // Matricies
    glm::mat4 matModel = glm::mat4(1.f), matView = glm::mat4(1.f),
              matProjection =
                  glm::perspective(glm::radians(90.f), 16.f / 9.f, .1f, 100.f),
              matOrtho = glm::ortho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f);

    glUniformMatrix4fv(matVPosition, 1, GL_FALSE, &matView[0][0]);
    glUniformMatrix4fv(matPPosition, 1, GL_FALSE, &matProjection[0][0]);

    // Framebuffer to store our voxel thingy
    GLuint fbo, texVoxelBuf;
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glGenTextures(1, &texVoxelBuf);
    glBindTexture(GL_TEXTURE_2D, texVoxelBuf);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 32, 32, 0, GL_RGB, GL_UNSIGNED_BYTE,
                 NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                           texVoxelBuf, 0);

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
    GLint inSquarePosLoc = glGetAttribLocation(progOffscreen, "in_Pos"),
          inSquareUVLoc = glGetAttribLocation(progOffscreen, "in_UV");
    glVertexAttribPointer(inSquarePosLoc, 2, GL_FLOAT, GL_FALSE,
                          4 * sizeof(float), 0);
    glVertexAttribPointer(inSquareUVLoc, 2, GL_FLOAT, GL_FALSE,
                          4 * sizeof(float), (void *)(2 * sizeof(float)));
    glEnableVertexAttribArray(inSquarePosLoc);
    glEnableVertexAttribArray(inSquareUVLoc);

    // Set of points to render the voxels
    float voxPoints[32 * 32 * 32 * 3] = {0.f};
    for (int i = 0; i < 32; i++)
        for (int j = 0; j < 32; j++)
            for (int k = 0; k < 32; k++) {
                voxPoints[3 * (32 * (i * 32 + j) + k) + 0] =
                    (float(i) - 16.f) / 16.f;
                voxPoints[3 * (32 * (i * 32 + j) + k) + 1] =
                    (float(j) - 16.f) / 16.f;
                voxPoints[3 * (32 * (i * 32 + j) + k) + 2] =
                    (float(k) - 16.f) / 16.f;
            }
    GLuint vaoVox, vboVox;
    glGenVertexArrays(1, &vaoVox);
    glBindVertexArray(vaoVox);
    glGenBuffers(1, &vboVox);
    glBindBuffer(GL_ARRAY_BUFFER, vboVox);
    glBufferData(GL_ARRAY_BUFFER, sizeof(voxPoints), voxPoints, GL_STATIC_DRAW);
    GLint inVoxPosLoc = glGetAttribLocation(progGenerate, "in_Pos");
    glVertexAttribPointer(inVoxPosLoc, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(inVoxPosLoc);

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
        glfwSetWindowTitle(window, title.c_str());

        //// Voxelization
        glBindVertexArray(vao);
        glUseProgram(progVoxel);
        glUniformMatrix4fv(matPPosition, 1, GL_FALSE, &matOrtho[0][0]);
        glUniform1ui(doPizzaPosition, renderOptions.pizza);

        matView = glm::lookAt(glm::vec3(0.f), glm::vec3(0.f, 0.f, -1.f),
                              glm::vec3(0.f, 1.f, 0.f));
        glUniformMatrix4fv(matVPosition, 1, GL_FALSE, &matView[0][0]);

        glUniform1f(timePosition, t / 10.f);
        matModel = glm::translate(glm::vec3((float)sin(t / 3.f) / 2.f,
                                            (float)sin(t * 5.f) / 20.f, 0.f));
        matModel = glm::rotate(matModel, t, glm::vec3(0, 0, 1));
        glUniformMatrix4fv(matMPosition, 1, GL_FALSE, &matModel[0][0]);

        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

        glEnable(GL_COLOR_LOGIC_OP);
        glLogicOp(GL_XOR);
        glDisable(GL_DEPTH_TEST);

        // Rendering
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glBindVertexArray(vao);
        glDrawElements(GL_TRIANGLES, mesh.indices.size(), GL_UNSIGNED_INT, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);

        glDisable(GL_COLOR_LOGIC_OP);
        //// Display 3D voxels
        glViewport(0, 0, fbWidth, fbHeight);
        glEnable(GL_DEPTH_TEST);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        if (renderOptions.wireframe)
            glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        else
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        glUseProgram(progGenerate);

        glUniformMatrix4fv(matPPositionGen, 1, GL_FALSE, &matProjection[0][0]);
        matView = glm::lookAt(camLook * -zoom, glm::vec3(0.f),
                              -glm::cross(camRight, camLook));
        glUniformMatrix4fv(matVPositionGen, 1, GL_FALSE, &matView[0][0]);
        matModel = glm::mat4(1.f);
        glUniformMatrix4fv(matMPositionGen, 1, GL_FALSE, &matModel[0][0]);
        glUniform1ui(doPizzaPositionGen, renderOptions.pizza);

        glBindVertexArray(vaoVox);
        glDrawArrays(GL_POINTS, 0, sizeof(voxPoints) / sizeof(float) / 3);

        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        //// Interlace voxels
        glViewport(32, 0, 32 * 8, 32 * 4);
        glBindVertexArray(vaoSquare);
        glUseProgram(progInterlace);
        glUniform1ui(doPizzaPositionInt, renderOptions.pizza);
        glDrawArrays(GL_TRIANGLES, 0, sizeof(vert) / sizeof(float));

        //// Displaying the voxel texture
        glViewport(0, 0, 32, 32);
        glBindVertexArray(vaoSquare);
        glUseProgram(progOffscreen);
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
                                                {GL_GEOMETRY_SHADER, "gs"},
                                                {GL_FRAGMENT_SHADER, "fs"}};
    std::string path = "shader/" + filename + "." + exts.at(type), source;
    readFile(path, source);
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
    glAttachShader(progVoxel, loadShader(GL_VERTEX_SHADER, "voxel"));
    glAttachShader(progVoxel, loadShader(GL_GEOMETRY_SHADER, "voxel"));
    glAttachShader(progVoxel, loadShader(GL_FRAGMENT_SHADER, "voxel"));
    glBindFragDataLocation(progVoxel, 0, "fragColor");
    glLinkProgram(progVoxel);
    glUseProgram(progVoxel);

    progOffscreen = glCreateProgram();
    glAttachShader(progOffscreen, loadShader(GL_VERTEX_SHADER, "offscreen"));
    glAttachShader(progOffscreen, loadShader(GL_FRAGMENT_SHADER, "offscreen"));
    glBindFragDataLocation(progOffscreen, 0, "out_Color");
    glLinkProgram(progOffscreen);
    glUseProgram(progOffscreen);

    progGenerate = glCreateProgram();
    glAttachShader(progGenerate, loadShader(GL_VERTEX_SHADER, "generate"));
    glAttachShader(progGenerate, loadShader(GL_GEOMETRY_SHADER, "generate"));
    glAttachShader(progGenerate, loadShader(GL_FRAGMENT_SHADER, "generate"));
    glBindFragDataLocation(progGenerate, 0, "out_Color");
    glLinkProgram(progGenerate);
    glUseProgram(progGenerate);

    progInterlace = glCreateProgram();
    glAttachShader(progInterlace, loadShader(GL_VERTEX_SHADER, "offscreen"));
    glAttachShader(progInterlace, loadShader(GL_FRAGMENT_SHADER, "interlace"));
    glBindFragDataLocation(progInterlace, 0, "out_Color");
    glLinkProgram(progInterlace);
    glUseProgram(progInterlace);
}
