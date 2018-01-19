#include <spirose/spirose.h>
#include <unistd.h>
#include <iostream>
#include <vector>

#include <glm/gtx/transform.hpp>

#include <assimp/postprocess.h>
#include <assimp/scene.h>
#include <assimp/Importer.hpp>

struct {
    bool verbose;
    std::string meshPath, pngPath;
} options = {.verbose = false, .meshPath = "", .pngPath = ""};

void parseOptions(int argc, char *argv[]);
void printUsage();

int main(int argc, char *argv[]) {
    parseOptions(argc, argv);

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
        options.meshPath.c_str(),
        aiProcess_JoinIdenticalVertices | aiProcess_Triangulate |
            aiProcess_SortByPType | aiProcess_PreTransformVertices);

    if (!scene) {
        std::cerr << "[ERR] Failed to open scene " << options.meshPath << ": "
                  << importer.GetErrorString() << std::endl;
        exit(-1);
    }

    if (options.verbose) {
        std::cout << "[INFO] Scene has " << scene->mNumMeshes << " meshes."
                  << std::endl;
        std::cout << "[INFO] Scene has " << scene->mNumMaterials
                  << " materials." << std::endl;
    }

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
    for (unsigned int m = 0; m < scene->mNumMeshes; m++) {
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

    context.dumpPNG(options.pngPath);

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}

void parseOptions(int argc, char *argv[]) {
    int c, parsed = 0;
    while ((c = getopt(argc, argv, "v")) != -1) {
        switch (c) {
            case 'v':
                options.verbose = true;
                break;

            case '?':
            default:
                printUsage();
                exit(-1);
        }
        parsed++;
    }

    if (argc - parsed < 3) {
        fprintf(stderr,
                "[ERR] Insufficient arguments given. 2 required, got %d.\n",
                argc - parsed - 1);
        printUsage();
        exit(-1);
    }

    options.meshPath = std::string(argv[parsed + 1]);
    options.pngPath = std::string(argv[parsed + 2]);
}

void printUsage() {
    printf(
        "Framer - converts meshes and scenes to interlaced images for "
        "SpiROSE.\n"
        "Usage: ./framer [-v] <source scene> <destination PNG>\n"
        "    -v - verbose: Prints out informations about the scene\n"
        "    source scene: Any scene loadable by Assimp. It can handle multi "
        "mesh scene with multiple colors.\n"
        "    destination PNG: Output PNG to write the frame to.\n");
}
