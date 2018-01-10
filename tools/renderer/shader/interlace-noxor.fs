in vec2 ex_UV;

layout(location = 0) out vec4 out_Color;

uniform sampler2D tex[N_DRAW_BUFFER];
uniform bool doPizza;

const float M_PI = 3.14159265359;
const float nVoxelPass = float(N_VOXEL_PASS);

void main() {
    // Get our coordinates in the texture
    // For now, we'll do a 2D array of images, each image representing a panel
    // refresh
    vec2 refreshMod =
        mod(ex_UV, 1.0 / vec2(DISP_INTERLACE_H, DISP_INTERLACE_W));
    vec2 refreshPos =
        (ex_UV - refreshMod) * vec2(DISP_INTERLACE_H, DISP_INTERLACE_W);
    // Angle would be more correct, since this value is in [0, 1]
    float refreshNo =
        (refreshPos.y * float(DISP_INTERLACE_H) + refreshPos.x) / float(RES_C);

    /* Pack coordinates in a vector
     * As our current y value represents how deep we are in the voxels, it is
     * our 3D z position.
     * And xy will be xy in 3D :)
     */
    vec3 fragPos = vec3(refreshNo, refreshMod.x * float(DISP_INTERLACE_H),
                        refreshMod.y* float(DISP_INTERLACE_W));

    if (doPizza) {
        /* In pizza mode, the voxel texture only represents half of a slice.
         * Thus make fetch another part of the texture for the left half of the
         * slice
         */
        if (fragPos.y < 0.5) fragPos.x += 0.5;
        fragPos.y = abs(fragPos.y - 0.5) * 2.0;
    } else
        // Just polar coordinates from the (0.5, 0.5) point as origin
        fragPos.xy =
            0.5 + vec2(sin(refreshNo), -cos(refreshNo)) * (fragPos.y - 0.5);

    float modZ = mod(fragPos.z, 1.0 / nVoxelPass) * float(RES_H / 4);
    vec2 modST = fragPos.xy / vec2(nVoxelPass, 1.0) +
                 vec2(floor(fragPos.z * nVoxelPass) / nVoxelPass, 0.0);

    // As usual, decode our voxel thingy. This may look stupid to do conditions
    // on the value of modZ if this very same value is our index. But most GL
    // implementations don't allow dynamic indexing of sampler arrays, neither
    // does OpenGL ES (whatever the version is).
    vec4 color;
    if (modZ < 1.0)
        color = texture(tex[0], modST);
    else if (modZ < 2.0)
        color = texture(tex[1], modST);
    else if (modZ < 3.0)
        color = texture(tex[2], modST);
    else if (modZ < 4.0)
        color = texture(tex[3], modST);
#if N_DRAW_BUFFER >= 5
    else if (modZ < 5.0)
        color = texture(tex[4], modST);
#endif
#if N_DRAW_BUFFER >= 6
    else if (modZ < 6.0)
        color = texture(tex[5], modST);
#endif
#if N_DRAW_BUFFER >= 7
    else if (modZ < 7.0)
        color = texture(tex[6], modST);
#endif
#if N_DRAW_BUFFER >= 8
    else if (modZ < 8.0)
        color = texture(tex[7], modST);
#endif

    // Get our height in the texture
    float z = mod(fragPos.z * float(RES_H / 4), 1.0);
    float v;
    if (z < 0.25)
        v = color.r;
    else if (z < 0.50)
        v = color.g;
    else if (z < 0.75)
        v = color.b;
    else
        v = color.a;

    out_Color = vec4(0.0);
    if (abs(mod(v * 255.0, 2.0) - 1.0) < 0.1) out_Color = vec4(1.0);
}
