#include <iostream>

#include "context.h"
#include "object.h"

namespace spirose {

Context::Context(int resW, int resH, int resC, glm::mat4 matrixWorld) {
    /* Determine the optimum draw buffer count. A single buffer (~texture) can
     * hold 4 voxel layers. Thus, we'd ideally use resH/4 buffers. However,
     * we have a maximum of color attachemnts (render targets). Thus, fit as
     * many as we can in this amount, while still using all buffers in a single
     * pass.
     */
    glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &nVoxelBuffer);
    /* This is guaranteed to end since nVoxelBuffer >= 4 and any number is
     * dividable by one.
     */
    while ((resH / 4) % nVoxelBuffer) nVoxelBuffer--;

    // TODO: shader loading and compiling
    // TODO: uniform loading

    // FBO color attachments binding points
    std::vector<GLenum> drawBuffers(nVoxelBuffer);
    glGenFramebuffers(1, &fboVoxel);
    glBindFramebuffer(GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING, fboVoxel);
    textureVoxel.reserve(nVoxelBuffer);
    glGenTextures(nVoxelBuffer, &textureVoxel[0]);
    for (int i = 0; i < nVoxelBuffer; i++) {
        // Initialize textures
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, textureVoxel[i]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, resW * nVoxelPass, resW, 0,
                     GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

        // Bind it to the FBO color attachment
        drawBuffers[i] = GL_COLOR_ATTACHMENT0 + i;
        glFramebufferTexture2D(GL_FRAMEBUFFER, drawBuffers[i], GL_TEXTURE_2D,
                               textureVoxel[i], 0);
    }
    glDrawBuffers(nVoxelBuffer, &drawBuffers[0]);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        std::cerr << "[ERR] Incomplete framebuffer object" << std::endl;
        exit(-1);
    }
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

}  // namespace spirose
