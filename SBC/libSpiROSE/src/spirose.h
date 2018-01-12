#ifndef _SPIROSE_LIBSPIROSE_H
#define _SPIROSE_LIBSPIROSE_H

// Include GLFW headers and the correct OpenGL headers
#ifdef GLES
#define GLFW_INCLUDE_ES31
#else
#define GLFW_INCLUDE_GLCOREARB
#endif
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>

// For convenience for the end user, include the context and object classes
#include "context.h"
#include "object.h"

namespace spirose {

/**
 * @brief Creates a window with an OpenGL context fitting the interlaced render
 *        result.
 * @param int resW Horizontal voxel resolution
 * @param int resH Vertical voxel resolution
 * @param int resC Circular resolution, aka slice count
 */
GLFWwindow* createWindow(int resW, int resH, int resC);

/**
 * @brief Computes the dimensions the window needs to display the final
 *        synthesized buffer depending on the voxelization resolution.
 * @param int resW Horizontal voxel resolution
 * @param int resH Vertical voxel resolution
 * @param int resC Circular resolution, aka slice count
 * @returns glm::vec2 Size of the window
 */
glm::vec2 windowSize(int resW, int resH, int resC);

}  // namespace spirose

#endif  // defined(_SPIROSE_LIBSPIROSE_H)
