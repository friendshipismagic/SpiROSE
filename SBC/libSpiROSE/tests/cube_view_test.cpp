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
    // Center the cube around (0, 0, 0)
    cube.matrixModel = glm::translate(glm::vec3(-.5f));

    // Voxelize the cube
    context.clearVoxels();
    context.voxelize(cube);

    // Render voxels as slices
    context.clearScreen();
    context.visualize(glm::vec4(1.f),
                      glm::perspective(glm::radians(90.f), 2.f, .1f, 10.f) *
                          glm::lookAt(glm::vec3(1.f), glm::vec3(0.f),
                                      glm::vec3(0.f, 1.f, 0.f)));

    context.dumpPNG(testName + ".png");
}
