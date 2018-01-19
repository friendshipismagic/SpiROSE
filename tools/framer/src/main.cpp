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
    std::cout << "[INFO] Scene has " << scene->mNumMaterials << " materials."
              << std::endl;

    // Extract colors from material
    std::vector<glm::vec4> colors(scene->mNumMaterials);
    for (unsigned int i = 0; i < scene->mNumMaterials; i++) {
        aiColor3D color(1.f, 1.f, 1.f);
        scene->mMaterials[i]->Get(AI_MATKEY_COLOR_DIFFUSE, color);
        colors[i].r = color.r;
        colors[i].g = color.g;
        colors[i].b = color.b;
        scene->mMaterials[i]->Get(AI_MATKEY_OPACITY, colors[i].a);
    }

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
