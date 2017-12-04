#version 330 core

in vec2 ex_UV;

out vec4 out_Color;

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform bool doPizza;
uniform bool useXor;

const float M_PI = 3.14159265359;

void main() {
    // Get our coordinates in the texture
    // For now, we'll do a 2D array of images, each image representing a panel
    // refresh
    vec2 refreshMod = mod(ex_UV, 1.0 / vec2(8.0, 4.0));
    vec2 refreshPos = (ex_UV - refreshMod) * vec2(8.0, 4.0);
    // Angle would be more correct, since this value is in [0, 1]
    float refreshNo = (refreshPos.y * 8.0 + refreshPos.x) / 32.0;

    /* Pack coordinates in a vector
     * As our current y value represents how deep we are in the voxels, it is
     * our 3D z position.
     * And xy will be xy in 3D :)
     */
    vec3 fragPos = vec3(refreshNo, refreshMod.x * 8, refreshMod.y * 4);

    if (doPizza) {
        /* In pizza mode, the voxel texture only represents half of a slice.
         * Thus make fetch another part of the texture for the left half of the
         * slice
         */
        if (fragPos.y < 0.5) fragPos.x += 0.5;
        fragPos.y = abs(fragPos.y - 0.5) * 2;
    } else
        // Just polar coordinates from the (0.5, 0.5) point as origin
        fragPos.xy =
            0.5 + vec2(sin(refreshNo), -cos(refreshNo)) * (fragPos.y - 0.5);

    // As usual, decode our voxel thingy
    ivec4 color;

    if (useXor)
        color = ivec4(texture(tex0, fragPos.xy) * 255);
    else {
        if (fragPos.z < 1/8)      color = ivec4(texture(tex0, fragPos.xy) * 255);
        else if (fragPos.z < 2/8) color = ivec4(texture(tex1, fragPos.xy) * 255);
        else if (fragPos.z < 3/8) color = ivec4(texture(tex2, fragPos.xy) * 255);
        else if (fragPos.z < 4/8) color = ivec4(texture(tex3, fragPos.xy) * 255);
        else if (fragPos.z < 5/8) color = ivec4(texture(tex4, fragPos.xy) * 255);
        else if (fragPos.z < 6/8) color = ivec4(texture(tex5, fragPos.xy) * 255);
        else if (fragPos.z < 7/8) color = ivec4(texture(tex6, fragPos.xy) * 255);
        else if (fragPos.z < 8/8) color = ivec4(texture(tex7, fragPos.xy) * 255);
    }

    int p = 1 << int(mod(fragPos.z * 32, 8));
    int v;
    if (fragPos.z < 0.25)
        v = color.r;
    else if (fragPos.z < 0.50)
        v = color.g;
    else if (fragPos.z < 0.75)
        v = color.b;
    else
        v = color.a;

    out_Color = vec4(0);
    if ((v & p) != 0) out_Color = vec4(1);
}
