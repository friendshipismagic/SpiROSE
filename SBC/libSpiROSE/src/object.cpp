#include "object.h"
#include "utils.h"

namespace spirose {

Object::Object(float *vertices, int nVertices, int *indices, int nIndices,
               glm::mat4 matrixModel)
    : matrixModel(matrixModel), nIndices(nIndices) {
    // Create the VAO
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    // Create VBO
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, nVertices * 3 * sizeof(float), vertices,
                 GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, false, 0, 0);
    glEnableVertexAttribArray(0);

    // Create IBO
    glGenBuffers(1, &ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, nIndices * sizeof(int), indices,
                 GL_STATIC_DRAW);

    glBindVertexArray(0);
}
/**
 * @brief Releases resources associated with an object.
 */
Object::~Object() {
    glDeleteBuffers(1, &ibo);
    glDeleteBuffers(1, &vbo);
    glDeleteVertexArrays(1, &vao);
}

void Object::draw() const {
    gl::bindVertexArray(vao);
    glDrawElements(GL_TRIANGLES, nIndices, GL_UNSIGNED_INT, 0);
}

}  // namespace spirose
