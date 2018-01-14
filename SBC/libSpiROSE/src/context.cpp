#include <iostream>
#include <map>

#include <glm/gtx/transform.hpp>

#include "context.h"
#include "object.h"
#include "spirose.h"
#include "utils.h"

namespace spirose {

Context::Context(int resW, int resH, int resC, glm::mat4 matrixView)
    : matrixView(matrixView), resW(resW), resH(resH), resC(resC) {
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
    nVoxelPass = (resH / 4) / nVoxelBuffer;

    // Get synthesized resolution
    glm::ivec2 synthResolution =
        windowSize(resW, resH, resC) / glm::ivec2(resW, resH);
    synthW = synthResolution.x;
    synthH = synthResolution.y;

    loadShaders();
    loadUniforms();

    // FBO color attachments binding points
    std::vector<GLenum> drawBuffers(nVoxelBuffer);
    glGenFramebuffers(1, &fboVoxel);
    glBindFramebuffer(GL_FRAMEBUFFER, fboVoxel);
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
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        std::cerr << "[ERR] Incomplete framebuffer object" << std::endl;
        exit(-1);
    }

    // 2D square for offscreen multipass
    glGenVertexArrays(1, &vaoSquare);
    glBindVertexArray(vaoSquare);
    glGenBuffers(1, &vboSquare);
    glBindBuffer(GL_ARRAY_BUFFER, vboSquare);
    static const float square[] = {// Interleave position and UV
                                   -1, -1, 0, 0, 1, 1, 1, 1, -1, 1,  0, 1,
                                   -1, -1, 0, 0, 1, 1, 1, 1, 1,  -1, 1, 0};
    glBufferData(GL_ARRAY_BUFFER, sizeof(square), square, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, false, 4 * sizeof(float), 0);
    glVertexAttribPointer(1, 2, GL_FLOAT, false, 4 * sizeof(float),
                          (void *)(2 * sizeof(float)));
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);

    // 3D points cloud for the visualisation
    glGenVertexArrays(1, &vaoPoints);
    glBindVertexArray(vaoPoints);
    glGenBuffers(1, &vboPoints);
    glBindBuffer(GL_ARRAY_BUFFER, vboPoints);
    glm::vec3 resD2(float(resW / 2), float(resW / 2), float(resH / 2)),
        resHD2(float(resH / 2));
    std::vector<glm::vec3> points(resW * resW * resH);
    for (int x = 0; x < resW; x++)
        for (int y = 0; y < resW; y++)
            for (int z = 0; z < resH; z++)
                points[resH * (x * resW + y) + z] =
                    /* Without any offset, points would be exactly on the edge
                     * of a voxel. When we fetch the voxel from the textures,
                     * we sometimes have rounding errors making the point land
                     * in the wrong voxel, thus creating very noticable visual
                     * glitches. That's the story begind the .01f.
                     */
                    (glm::vec3(x, y, z) - resD2) / resHD2 + .01f;
    glBufferData(GL_ARRAY_BUFFER, points.size() * 3 * sizeof(float), &points[0],
                 GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, false, 0, 0);
    glEnableVertexAttribArray(0);

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    float resRatio = float(resW) / float(resH);
    /* Projection matrix for the voxelisation.
     * We bundle a lookAt in it because the relation between the ortho
     * parameters and the lookAt ones is touchy.
     */
    matrixProjection =
        // resRatio allows us to have a voxelization volume always 2 units high
        glm::ortho(-resRatio, resRatio, -resRatio, resRatio, -1.f, 1.f) *
        // voxelize for z in [-1, 1], from the top, with the camera "up" being y
        glm::lookAt(glm::vec3(0.f), glm::vec3(0.f, 0.f, -1.f),
                    glm::vec3(0.f, 1.f, 0.f));

    // Upload texture bindings to the shaders
    gl::useProgram(shaderSynth);
    for (int i = 0; i < nVoxelBuffer; i++)
        glUniform1i(uniforms.synth.voxels[i], i);
    gl::useProgram(shaderView);
    for (int i = 0; i < nVoxelBuffer; i++)
        glUniform1i(uniforms.view.voxels[i], i);
}
Context::~Context() {
    // Release shaders
    glDeleteProgram(shaderVoxel);
    glDeleteProgram(shaderSynth);
    glDeleteProgram(shaderView);

    // Release FBO
    glDeleteBuffers(1, &fboVoxel);
    glDeleteTextures(nVoxelBuffer, &textureVoxel[0]);

    // Release VAOs and VBOs
    glDeleteBuffers(1, &vboSquare);
    glDeleteVertexArrays(1, &vaoSquare);
    glDeleteBuffers(1, &vboPoints);
    glDeleteVertexArrays(1, &vaoPoints);
}

void Context::clearVoxels() {
    gl::bindFramebuffer(fboVoxel);
    glClear(GL_COLOR_BUFFER_BIT);
}
void Context::clearScreen(glm::vec4 color) {
    gl::bindFramebuffer(0);
    glDisable(GL_SCISSOR_TEST);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void Context::voxelize(Object &object) {
    gl::bindFramebuffer(fboVoxel);

    // Config shader
    glm::mat4 matMVP = matrixProjection * matrixView * object.matrixModel;
    gl::useProgram(shaderVoxel);
    glUniformMatrix4fv(uniforms.voxel.matrixMVP, 1, false, &matMVP[0][0]);

    // Additive blending to simulate the XOR algorithm
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);

    glDisable(GL_DEPTH_TEST);
    glEnable(GL_SCISSOR_TEST);

    // Render object
    for (int i = 0; i < nVoxelPass; i++) {
        glViewport(resW * i, 0, resW, resW);
        glScissor(resW * i, 0, resW, resW);
        glUniform1i(uniforms.voxel.passNo, i);
        object.draw();
    }
}
void Context::synthesize(glm::vec4 color) {
    gl::bindFramebuffer(0);

    // Config shader
    gl::useProgram(shaderSynth);
    glUniform4fv(uniforms.synth.color, 1, &color[0]);

    // Config GL
    glDisable(GL_SCISSOR_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_DEPTH_TEST);
    glViewport(0, 0, resW * synthW, resH * synthH);

    gl::bindVertexArray(vaoSquare);
    glDrawArrays(GL_TRIANGLES, 0, 6 * 4);
}
void Context::visualize(glm::vec4 color, glm::mat4 matrixMVP) {
    gl::bindFramebuffer(0);

    // Config shader
    gl::useProgram(shaderView);
    glUniformMatrix4fv(uniforms.view.matrixMVP, 1, false, &matrixMVP[0][0]);
    glUniform4fv(uniforms.view.color, 1, &color[0]);

    // Config GL
    glDisable(GL_SCISSOR_TEST);
    glDisable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
#ifndef GLES
    glPointSize(10.f);
#endif
    glViewport(0, 0, resW * synthW, resH * synthH);

    gl::bindVertexArray(vaoPoints);
    glDrawArrays(GL_POINTS, 0, resW * resW * resH);
}

bool Context::dumpPNG(std::string filename) {
    std::vector<GLuint> pixels(resW * synthW * resH * synthH * 4);

    // Align to byte boundaries
    glPixelStorei(GL_PACK_ALIGNMENT, 1);

    gl::bindFramebuffer(0);
    glReadBuffer(GL_COLOR_ATTACHMENT0);
    glReadPixels(0, 0, resW * synthW, resH * synthH, GL_RGBA, GL_UNSIGNED_BYTE,
                 &pixels[0]);
    return savePNG(filename, resW * synthW, resH * synthH,
                   (uint8_t *)&pixels[0]);
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
    uniforms.voxel.matrixMVP = glGetUniformLocation(shaderVoxel, "matMVP");
    uniforms.voxel.passNo = glGetUniformLocation(shaderVoxel, "passNo");

    uniforms.synth.voxels.reserve(nVoxelBuffer);
    for (int i = 0; i < nVoxelBuffer; i++)
        uniforms.synth.voxels[i] = glGetUniformLocation(
            shaderSynth, ("voxels[" + std::to_string(i) + "]").c_str());
    uniforms.synth.color = glGetUniformLocation(shaderSynth, "in_Color");

    uniforms.view.matrixMVP = glGetUniformLocation(shaderView, "matMVP");
    uniforms.view.voxels.reserve(nVoxelBuffer);
    for (int i = 0; i < nVoxelBuffer; i++)
        uniforms.view.voxels[i] = glGetUniformLocation(
            shaderView, ("voxels[" + std::to_string(i) + "]").c_str());
    uniforms.view.color = glGetUniformLocation(shaderView, "in_Color");
}

}  // namespace spirose
