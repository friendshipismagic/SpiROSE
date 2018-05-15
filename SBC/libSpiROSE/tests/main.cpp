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

#include <libgen.h>
#include <spirose/spirose.h>
#include <iostream>

#define RES_W 80
#define RES_H 48
#define RES_C 128

void runTest(const std::string &testName, GLFWwindow *window,
             spirose::Context &context);

int main(int argc, char *argv[]) {
    glfwInit();
    GLFWwindow *window = spirose::createWindow(RES_W, RES_H, RES_C);
    spirose::Context context(RES_W, RES_H, RES_C);

    std::string name(basename(argv[0]));

    runTest(name, window, context);
}
