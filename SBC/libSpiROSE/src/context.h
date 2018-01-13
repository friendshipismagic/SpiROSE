#ifndef _SPIROSE_CONTEXT_H
#define _SPIROSE_CONTEXT_H

#include <string>
#include <vector>

#include <glm/glm.hpp>

#include "gl.h"

namespace spirose {

class Object;

class Context {
    public:
    /**
     * @brief Constructor of the Context class. Initialises libSpiROSE and
     *        creates needed OpenGL objects. Since it creates OpenGL objects, it
     *        needs a valid OpenGL context to be present.
     * @param int       resW       Horizontal voxel resolution
     * @param int       resH       Vertical voxel resolution
     * @param int       resC       Circular resolution, aka slice count
     * @param glm::mat4 matrixView Initial world transformation matrix (aka
     *                             global model matrix). Defaults to identity.
     */
    Context(int resW, int resH, int resC,
            glm::mat4 matrixView = glm::mat4(1.f));
    /**
     * @brief Releases resources held by libSpiROSE.
     */
    ~Context();

    /**
     * Clears the voxel buffers to either accept the next frame, or to render
     * objects of a different color.
     */
    void clearVoxels();
    /**
     * @brief Clears the display buffer (FBO 0) - both color and depth - to the
     *        specified `color`.
     * @param glm::vec4    color    RGBA color to clear the draw buffer to
     */
    void clearScreen(glm::vec4 color = glm::vec4(0.f));

    /**
     * @brief Triggers the voxelization of the given object in the context.
     * @param Object       object   object to draw
     */
    void voxelize(Object object);
    /**
     * @brief Takes the voxels and generates the final slice structure, along
     *        with any needed column shifting, and gives them the specified
     *        color.
     * @param glm::vec4    color    Color to give to the voxelized objects
     */
    void synthesize(glm::vec4 color);
    /**
     * @brief Visualize the voxelized scene as a set of 3D voxels in a real 3D
     *        view.
     * @param glm::vec4    color     Color to give to the 3D voxels
     * @param glm::mat4    matrixMVP Combined model-view-projection matrix to
     *                               apply to the 3D voxels.
     */
    void visualize(glm::vec4 color, glm::mat4 matrixMVP);

    /**
     * @brief Dumps the synthesized texture to the PNG in filename. Returns true
     *        in case of success.
     * @param std::string   filename  Relative path to the PNG to save.
     *                                Extension is required.
     */
    bool dumpPNG(std::string filename);

    /**
     * @brief A global transformation matrix to be applied to all meshes during
     * voxelization.
     */
    glm::mat4 matrixView;

    private:
    /**
     * @brief Voxelisation draw buffer count. This is how many different render
     *        targets will be used during voxelisation. It is a tradeoff between
     *        available render targets end thr required.
     */
    int nVoxelBuffer;
    /**
     * @brief Voxelisation passes count. This is how many render passes we need
     *        to overcome the lack of render targets.
     */
    int nVoxelPass;
    /**
     * @brief Voxelization resolution
     */
    int resW, resH, resC;
    /**
     * @brief Synthesized output size in pixels
     */
    int synthW, synthH;

    /**
     * @brief Shaders necessary for the voxelisation.
     */
    GLuint shaderVoxel, shaderSynth, shaderView;

    /**
     * @brief Uniforms for the aforementioned shaders
     */
    struct {
        struct {
            GLint matrixMVP, passNo;
        } voxel;
        struct {
            std::vector<GLint> voxels;
        } synth;
        struct {
            std::vector<GLint> voxels;
            GLint matrixMVP;
        } view;
    } uniforms;

    /**
     * @brief Voxel buffer object
     */
    GLuint fboVoxel;

    /**
     * @brief Actual textures holding the voxels. Size is nVoxelBuffer
     */
    std::vector<GLuint> textureVoxel;

    /**
     * @brief Vertex array and vertex buffer objects for the multipass rendering
     *        quad
     */
    GLuint vaoSquare, vboSquare;

    /**
     * @brief Vertex array and vertex buffer objects for the visualisations
     *        points "cloud"
     */
    GLuint vaoPoints, vboPoints;

    /**
     * @brief Projections matrix used for voxelisation
     */
    glm::mat4 matrixProjection;

    /**
     * @brief Compiles a shader
     * @returns Shader ID
     */
    GLuint compileShader(const GLenum type, const char* source) const;
    /**
     * @brief Loads, compiles and links shaders
     */
    void loadShaders();

    /**
     * @brief Loads uniforms
     */
    void loadUniforms();
};

}  // namespace spirose

#endif  // defined(_SPIROSE_CONTEXT_H)
