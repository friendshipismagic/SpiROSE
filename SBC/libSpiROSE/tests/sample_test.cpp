#include <glm/gtx/transform.hpp>
#include <iostream>

#include <spirose/spirose.h>

void onKey(GLFWwindow *window, int key, int scancode, int action, int mods) {
    if (action == GLFW_PRESS && key == GLFW_KEY_ESCAPE)
        glfwSetWindowShouldClose(window, true);
}

void runTest(const std::string &testName, GLFWwindow *window,
             spirose::Context &context) {
    glfwSetKeyCallback(window, onKey);

    float vertices[] = {1.f, 1.f, 0.f, 0.f, 1.f, 0.f, 1.f, 0.f,
                        0.f, 0.f, 0.f, 0.f, 1.f, 1.f, 1.f, 0.f,
                        1.f, 1.f, 0.f, 0.f, 1.f, 1.f, 0.f, 1.f};
    int indices[] = {3, 2, 6, 2, 6, 7, 6, 7, 4, 7, 4, 2, 4, 2, 0, 2, 0, 3,
                     0, 3, 1, 3, 1, 6, 1, 6, 5, 6, 5, 4, 5, 4, 1, 4, 1, 0};
    spirose::Object cube(vertices, 8, indices, sizeof(indices) / sizeof(int));

    glm::vec2 res(spirose::windowSize(80, 48, 128));
    glm::mat4 matMVP(1.f);
    matMVP = glm::lookAt(glm::vec3(1.f, 1.f, 1.f), glm::vec3(0.f),
                         glm::vec3(0.f, 0.f, 1.f)) *
             matMVP;
    matMVP = glm::perspective(glm::radians(90.f), res.x / res.y, .1f, 100.f) *
             matMVP;

    while (!glfwWindowShouldClose(window)) {
        context.clearVoxels();

        cube.matrixModel =
            glm::rotate(float(glfwGetTime()), glm::vec3(0.f, 1.f, 0.f)) *
            glm::translate(glm::vec3(-.5f));
        context.voxelize(cube);

        context.clearScreen();
        glm::mat4 m(
            glm::rotate(float(glfwGetTime()), glm::vec3(0.f, 0.f, 1.f)));
        // context.synthesize(glm::vec4(1.f, 1.f, 0.f, 1.f));
        context.visualize(glm::vec4(1.f, 1.f, 0.f, 1.f), matMVP * m);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    context.dumpPNG(testName + ".png");
}
