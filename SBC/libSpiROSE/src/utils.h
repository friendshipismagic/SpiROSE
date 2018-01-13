#ifndef _SPIROSE_UTILS_H
#define _SPIROSE_UTILS_H

#include <string>

#include "gl.h"

namespace spirose {

namespace gl {

/**
 * @brief Binds a FBO, and avoids redundant binds by keeping track of the
 *        last bound buffer.
 * @param GLuint framebuffer Specifies the name of the framebuffer object
 *                           to bind.
 */
inline void bindFramebuffer(const GLuint framebuffer) {
    // By default, FBO 0 is bound
    static GLuint current = 0;

    if (current != framebuffer) {
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        current = framebuffer;
    }
}
/**
 * @brief Bind a vertex array object. Avoids redundant rebinds by keeping track
 *        of the last bound buffer.
 * @param GLuint array Specifies the name of the vertex array to bind.
 */
inline void bindVertexArray(GLuint array) {
    static GLuint current = 0;

    if (current != array) {
        glBindVertexArray(array);
        current = array;
    }
}
/**
 * @brief Set the program, and avoid redundant rebinds by keeping track of the
 *        last bound buffer.
 * @param GLuint program Specifies the handle of the program object whose
 *                       executables are to be used as part of current rendering
 *                       state.
 */
inline void useProgram(GLuint program) {
    /* No program is bound by default, so any valid program ID will bind on
     * first call
     */
    static GLuint current = -1;

    if (current != program) {
        glUseProgram(program);
        current = program;
    }
}

}  // namespace gl

/**
 * @brief Saves pixels in an RGBA PNG file named filename.
 * @param std::string filename Relative path of the PNG file
 * @param int         width    Width of the image in pixels
 * @param int         height   Height of the image in pixels
 * @param uint8_t     pixels   Pixels to save
 * @returns bool Whether the save was a success.
 */
bool savePNG(const std::string &filename, const int width, const int height,
             const uint8_t *pixels);

}  // namespace spirose

#endif
