#include <glm/gtx/transform.hpp>
#include <iostream>

#include <spirose/spirose.h>

void runTest(const std::string &testName, GLFWwindow *window,
             spirose::Context &context) {
    float vertices[] = {1.f, 1.f, 0.f, 0.f, 1.f, 0.f, 1.f, 0.f,
                        0.f, 0.f, 0.f, 0.f, 1.f, 1.f, 1.f, 0.f,
                        1.f, 1.f, 0.f, 0.f, 1.f, 1.f, 0.f, 1.f};
    int indices[] = {3, 2, 6, 2, 6, 7, 6, 7, 4, 7, 4, 2, 4, 2, 0, 2, 0, 3,
                     0, 3, 1, 3, 1, 6, 1, 6, 5, 6, 5, 4, 5, 4, 1, 4, 1, 0};
    spirose::Object cube(vertices, 8, indices, sizeof(indices) / sizeof(int));

    glm::vec2 res(spirose::windowSize(80, 48, 128));

    context.clearVoxels();

    cube.matrixModel = glm::rotate(float(1.0), glm::vec3(0.f, 1.f, 0.f)) *
                       glm::translate(glm::vec3(-.5f));
    context.voxelize(cube);

    context.clearScreen();
    context.synthesize(glm::vec4(1.f, 1.f, 0.f, 1.f));

    context.dumpPNG(testName + ".png");
}
