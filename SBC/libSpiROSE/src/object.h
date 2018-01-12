#ifndef _SPIROSE_OBJECT_H
#define _SPIROSE_OBJECT_H

#include <glm/glm.hpp>

#include "spirose.h"

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
};

}  // namespace spirose

#endif  // defined(_SPIROSE_OBJECT_H)
