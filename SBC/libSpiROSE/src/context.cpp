#include "context.h"

namespace spirose {

Context::Context(int resW, int resH, int resC, glm::mat4 matrixWorld) {
    // TODO
}
Context::~Context() {
    // TODO
}

void Context::clearVoxels() {
    // TODO
}
void Context::clearScreen(glm::vec4 color) {
    // TODO
}

void Context::voxelize(Object object) {
    // TODO
}
void Context::synthesize(glm::vec4 color) {
    // TODO
}
void Context::visualize(glm::vec4 color, glm::mat4 matrixMVP) {
    // TODO
}

void Context::display() {
    // TODO
}

bool Context::dumpPNG(std::string filename) {
    // TODO
    return false;
}

}
