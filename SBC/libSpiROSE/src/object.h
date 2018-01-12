#ifndef _SPIROSE_OBJECT_H
#define _SPIROSE_OBJECT_H

#include <glm/glm.hpp>

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
     * @param int*      indices     Array of indices for the various faces
     *                              in the mesh
     * @param glm::mat4 matrixModel Model transformation matrix of the
     *                              model. Defaults to the identity matrix.
     */
    Object(float *vertices, float *indices,
           glm::mat4 matrixModel = glm::mat4(1.f));
    /**
     * @brief Releases resources associated with an object.
     */
    ~Object();

    /**
     * Model transformation matrix to be used during voxelization.
     */
    glm::mat4 matrixModel;
};

}  // namespace spirose

#endif  // defined(_SPIROSE_OBJECT_H)
