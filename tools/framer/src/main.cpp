#include <spirose/spirose.h>
#include <iostream>
#include <vector>

#include <glm/gtx/transform.hpp>

#include <assimp/postprocess.h>
#include <assimp/scene.h>
#include <assimp/Importer.hpp>

int main(int argc, char *argv[]) {
    glfwInit();
    GLFWwindow *window = spirose::createWindow(80, 48, 256);
    spirose::Context context(80, 48, 256);
    context.clearScreen();

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

    // Iterate over objects
    for (int m = 0; m < scene->mNumMeshes; m++) {
        const aiMesh *mesh = scene->mMeshes[m];

        // Build index buffer. Assimp gives indices on a per-face basis
        std::vector<int> indices(mesh->mNumFaces * 3);
        for (unsigned int i = 0; i < mesh->mNumFaces; i++) {
            const aiFace &face = mesh->mFaces[i];
            indices[i * 3 + 0] = face.mIndices[0];
            indices[i * 3 + 1] = face.mIndices[1];
            indices[i * 3 + 2] = face.mIndices[2];
        }

        // Build object
        spirose::Object object(&mesh->mVertices[0].x, mesh->mNumVertices,
                               &indices[0], indices.size());

        // Voxelization
        context.clearVoxels();
        context.voxelize(object);

        // Synthesis
        context.synthesize(colors[mesh->mMaterialIndex]);
    }

    context.dumpPNG(argv[2]);

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
