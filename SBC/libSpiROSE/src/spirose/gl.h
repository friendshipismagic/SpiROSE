#ifndef _SPIROSE_GL_H
#define _SPIROSE_GL_H

/**
 * This file is a shorthand for the inclusion of GL related headers.
 */

// Include GLFW headers and the correct OpenGL headers
#ifdef GLES
#define GLFW_INCLUDE_ES31
#else
#define GLFW_INCLUDE_GLCOREARB
#include <GL/glew.h>
#endif
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>

#endif
