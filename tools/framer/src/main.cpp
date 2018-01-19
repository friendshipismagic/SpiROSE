#include <spirose/spirose.h>
#include <iostream>
#include <vector>

#include <assimp/postprocess.h>
#include <assimp/scene.h>
#include <assimp/Importer.hpp>

int main(int argc, char *argv[]) {
    glfwInit();
    GLFWwindow *window = spirose::createWindow(80, 48, 256);
    spirose::Context context(80, 48, 256);

    // Load mesh
    Assimp::Importer importer;
    // Ensure we only have triangles
    importer.SetPropertyInteger(AI_CONFIG_PP_SBP_REMOVE,
                                aiPrimitiveType_LINE | aiPrimitiveType_POINT);
    const aiScene *scene = importer.ReadFile(
        argv[1], aiProcess_JoinIdenticalVertices | aiProcess_Triangulate |
                     aiProcess_SortByPType | aiProcess_PreTransformVertices);

    if (!scene) {
        std::cerr << "[ERR] Failed to open scene " << argv[1] << ": "
                  << importer.GetErrorString() << std::endl;
        exit(-1);
    }

    std::cout << "[INFO] Scene has " << scene->mNumMeshes << " meshes."
              << std::endl;

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
