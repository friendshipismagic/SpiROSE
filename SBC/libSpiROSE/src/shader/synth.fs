/**
 * Synthesize algorithm, fragment shader.
 * Role: generate microblocks
 */

in vec2 ex_UV;

layout(location = 0) out vec4 out_Color;

// Voxel buffers
uniform sampler2D voxels[N_VOXEL_BUFFER];

#define M_PI 3.14159265359;
const float nVoxelPass = float(N_VOXEL_PASS);

void main() {
    // Get our coordinates in a micro-block
    vec2 refreshMod = mod(ex_UV, 1.0 / vec2(SYNTH_W, SYNTH_H));
    // Get the micro-block coordinates
    vec2 refreshPos = (ex_UV - refreshMod) * vec2(SYNTH_W, SYNTH_H);
    // Number in [0, 1] telling at which refresh stop we are
    float refreshNo =
        (refreshPos.y * float(SYNTH_W) + refreshPos.x) / float(RES_C);

    /* Pack coordinates in a vector
     * As our current y value represents how deep we are in the voxels, it is
     * our 3D z position.
     */
    vec3 fragPos = vec3(refreshNo, refreshMod.x * float(SYNTH_W),
                        refreshMod.y* float(SYNTH_H));

    // Convert refreshNo to the angle of the panel
    refreshNo *= 2.0 * M_PI;
    // Rotate the panel around the (0.5, 0.5) point
    fragPos.xy =
        0.5 + vec2(sin(refreshNo), -cos(refreshNo)) * (fragPos.y - 0.5);

    float modZ = mod(fragPos.z, 1.0 / nVoxelPass) * float(RES_H / 4);
    vec2 modST = fragPos.xy / vec2(nVoxelPass, 1.0) +
                 vec2(floor(fragPos.z * nVoxelPass) / nVoxelPass, 0.0);

    /* Sample the proper texture depending on our height. We *still* need the
     * conditions as most GL implementations do not support dynamic indexing
     * of sampler arrays
     */
    vec4 color;
    if (modZ < 1.0)
        color = texture(voxels[0], modST);
    else if (modZ < 2.0)
        color = texture(voxels[1], modST);
    else if (modZ < 3.0)
        color = texture(voxels[2], modST);
    else if (modZ < 4.0)
        color = texture(voxels[3], modST);
#if N_VOXEL_BUFFER > 4
    else if (modZ < 5.0)
        color = texture(voxels[4], modST);
#endif
#if N_VOXEL_BUFFER > 5
    else if (modZ < 6.0)
        color = texture(voxels[5], modST);
#endif
#if N_VOXEL_BUFFER > 6
    else if (modZ < 7.0)
        color = texture(voxels[6], modST);
#endif
#if N_VOXEL_BUFFER > 7
    else if (modZ < 8.0)
        color = texture(voxels[7], modST);
#endif

    // Get our height in the layer pack to use the proper color channel
    float z = mod(fragPos.z * float(RES_H / 4), 1.0);
    float v;
    if (z < 0.25)
        v = color.r;
    else if (z < 0.5)
        v = color.g;
    else if (z < 0.75)
        v = color.b;
    else
        v = color.a;

    out_Color = vec4(0.0);
    if (abs(mod(v * 255.0, 2.0) - 1.0) < 0.1) out_Color = vec4(1.0);
}
