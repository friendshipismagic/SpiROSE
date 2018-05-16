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
    context.visualize(glm::vec4(1.f, 0.f, 0.f, 1.f),
                      glm::perspective(glm::radians(90.f), 2.f, .1f, 10.f) *
                          glm::lookAt(glm::vec3(1.f), glm::vec3(0.f),
                                      glm::vec3(0.f, 1.f, 0.f)));

    context.dumpPNG(testName + ".png");
}
