#include <iostream>
#include <map>

#include "context.h"
#include "object.h"

namespace spirose {

Context::Context(int resW, int resH, int resC, glm::mat4 matrixWorld)
    : resW(resW), resH(resH), resC(resC) {
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

    // Get synthesized resolution
    glm::vec2 synthResolution =
        windowSize(resW, resH, resC) / glm::vec2(resW, resH);
    synthW = synthResolution.x;
    synthH = synthResolution.y;
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

GLuint Context::compileShader(const GLenum type, const char *source) const {
    // Set of defines to add to the shader
    std::map<std::string, int> defines = {{"N_VOXEL_BUFFER", nVoxelBuffer},
                                          {"N_VOXEL_PASS", nVoxelPass},
                                          {"RES_W", resW},
                                          {"RES_H", resH},
                                          {"RES_C", resC},
                                          {"SYNTH_W", synthW},
                                          {"SYNTH_H", synthH}};
    // Build a usable string
    std::string definesStr;
    for (auto &define : defines)
        definesStr += "#define " + define.first + " " +
                      std::to_string(define.second) + "\n";

    // Final shader source
    const char *finalSource[] = {
#ifdef GLES
        // GL and GLES have different #version syntaxes...
        "#version 330 es\n",
        // GLES needs an explicit float precision declaration
        "presicion highp float;\n",
#else
        "#version 330 core\n",
#endif
        definesStr.c_str(), source};

    // Shader compilation
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, sizeof(finalSource) / sizeof(char *), finalSource,
                   nullptr);
    glCompileShader(shader);

    // Check compilation
    GLint isOk;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &isOk);
    if (!isOk) {
        std::cerr << "[ERR] Shader compilation error." << std::endl;
        std::cerr << "[ERR] Source:" << std::endl;

        // Dump final source
        for (unsigned int i = 0; i < sizeof(finalSource) / sizeof(char *); i++)
            std::cout << finalSource[i];
        std::cout << std::endl;

        // Get and print error
        GLint len = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);
        GLchar *buf = new GLchar[len];
        if (!buf) {
            std::cerr << "[ERR] Failed to allocate " << len
                      << " bytes to fetch the error." << std::endl;
            exit(-2);
        }
        glGetShaderInfoLog(shader, len, nullptr, buf);
        std::cerr << buf << std::endl;
        delete buf;

        exit(-3);
    }

    return shader;
}
void Context::loadShaders() {
    // Declare the sources as static to avoid blowing up the stack
    static const char *srcVoxelV =
#include "shader/voxel.vss"
        ;
    static const char *srcVoxelF =
#include "shader/voxel.fss"
        ;
    static const char *srcSynthV =
#include "shader/synth.vss"
        ;
    static const char *srcSynthF =
#include "shader/synth.fss"
        ;
    static const char *srcViewV =
#include "shader/view.vss"
        ;
    static const char *srcViewF =
#include "shader/view.fss"
        ;

    shaderVoxel = glCreateProgram();
    glAttachShader(shaderVoxel, compileShader(GL_VERTEX_SHADER, srcVoxelV));
    glAttachShader(shaderVoxel, compileShader(GL_FRAGMENT_SHADER, srcVoxelF));
    glLinkProgram(shaderVoxel);

    shaderSynth = glCreateProgram();
    glAttachShader(shaderSynth, compileShader(GL_VERTEX_SHADER, srcSynthV));
    glAttachShader(shaderSynth, compileShader(GL_FRAGMENT_SHADER, srcSynthF));
    glLinkProgram(shaderSynth);

    shaderView = glCreateProgram();
    glAttachShader(shaderView, compileShader(GL_VERTEX_SHADER, srcViewV));
    glAttachShader(shaderView, compileShader(GL_FRAGMENT_SHADER, srcViewF));
    glLinkProgram(shaderView);
}

void Context::loadUniforms() {
    // TODO
}

}  // namespace spirose
