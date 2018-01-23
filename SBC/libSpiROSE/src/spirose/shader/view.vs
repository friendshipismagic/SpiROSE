/**
 * View algorithm, vertex shader.
 * Role: sample voxels and "discard" vertices
 */

layout(location = 0) in vec3 in_Pos;

uniform mat4 matMVP;
uniform sampler2D voxels[N_VOXEL_BUFFER];

const float nVoxelPass = float(N_VOXEL_PASS);

void main() {
    // Map back to [0, 1]
    float resRatio = float(RES_H) / float(RES_W);
    vec3 p = (in_Pos * vec3(resRatio, resRatio, 1.0)) / 2.0 + 0.5;

    float modZ = mod(p.z, 1.0 / nVoxelPass) * float(RES_H / 4);
    vec2 modST = p.xy / vec2(nVoxelPass, 1.0) +
                 vec2(floor(p.z * nVoxelPass) / nVoxelPass, 0.0);

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
    float z = mod(p.z * float(RES_H / 4), 1.0);
    float v;
    if (z < 0.25)
        v = color.r;
    else if (z < 0.5)
        v = color.g;
    else if (z < 0.75)
        v = color.b;
    else
        v = color.a;

    if (abs(mod(v * 255.0, 2.0) - 1.0) >= 0.1)
        gl_Position = vec4(1000.0);
    else
        gl_Position = matMVP * vec4(in_Pos, 1.0);
    gl_PointSize = 10.0;
}
