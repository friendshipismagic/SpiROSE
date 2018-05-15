/* * Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément
 * Decoodt, Alexandre Janniaux, Adrien Marcenat
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#ifndef _SPIROSE_OBJECT_H
#define _SPIROSE_OBJECT_H

#include <glm/glm.hpp>

#include "gl.h"

namespace spirose {

class Object {
    public:
    /**
     * @brief Constructor of the Object class. Creates a new 3D object to be
     *        voxelized. Internally, this will create a VBO to store the
     *        vertices and a VAO to hold it together, with the proper shader
     *        inputs.
     * @param float*    vertices    Array of vertices in the mesh, in
     *                              x0, y0, z0, x1, y1, z1 format
     * @param int       nVertices   Vertex count present in vertices
     * @param int*      indices     Array of indices for the various faces
     *                              in the mesh
     * @param int       nIndices    Index count present in indices
     * @param glm::mat4 matrixModel Model transformation matrix of the
     *                              model. Defaults to the identity matrix.
     */
    Object(float *vertices, int nVertices, int *indices, int nIndices,
           glm::mat4 matrixModel = glm::mat4(1.f));
    /**
     * @brief Releases resources associated with an object.
     */
    ~Object();

    /**
     * @brief Renders the VAO of the object.
     */
    void draw() const;

    /**
     * Model transformation matrix to be used during voxelization.
     */
    glm::mat4 matrixModel;

    private:
    /**
     * @brief Vertex Array object to bundle together the various buffers
     */
    GLuint vao;

    /**
     * @brief Vertex buffer object holding vertex data
     */
    GLuint vbo;

    /**
     * @brief Index buffer object holding indices
     */
    GLuint ibo;

    /**
     * @brief Index count
     */
    int nIndices;
};

}  // namespace spirose

#endif  // defined(_SPIROSE_OBJECT_H)
