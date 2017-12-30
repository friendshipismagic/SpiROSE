in vec2 ex_UV;

layout(location = 0) out vec4 out_Color;

uniform sampler2D tex;
uniform bool doPizza;

const float M_PI = 3.14159265359;

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
        (refreshPos.y * DISP_INTERLACE_H + refreshPos.x) / float(RES_C);

    /* Pack coordinates in a vector
     * As our current y value represents how deep we are in the voxels, it is
     * our 3D z position.
     * And xy will be xy in 3D :)
     */
    vec3 fragPos = vec3(refreshNo, refreshMod.x * DISP_INTERLACE_H,
                        refreshMod.y * DISP_INTERLACE_W);

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

    // As usual, decode our voxel thingy
    ivec4 color = ivec4(texture(tex, fragPos.xy) * 255.0);

    int p = 1 << int(mod(fragPos.z * 32.0, 8.0));
    int v;
    if (fragPos.z < 0.25)
        v = color.r;
    else if (fragPos.z < 0.50)
        v = color.g;
    else if (fragPos.z < 0.75)
        v = color.b;
    else
        v = color.a;

    out_Color = vec4(0.0);
    if ((v & p) != 0) out_Color = vec4(1.0);
}
