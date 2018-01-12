#ifndef _SPIROSE_CONTEXT_H
#define _SPIROSE_CONTEXT_H

#include <string>

#include <glm/glm.hpp>

namespace spirose {

// Forward-declaration of the Object class
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
            glm::mat4 matrixWorld = glm::mat4(1.f));
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
     * @brief Updates the display by swapping the draw and display buffer.
     */
    void display();

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
};

}  // namespace spirose

#endif  // defined(_SPIROSE_CONTEXT_H)
