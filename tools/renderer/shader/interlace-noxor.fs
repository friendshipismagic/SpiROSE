in vec2 ex_UV;

layout(location = 0) out vec4 out_Color;

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform bool doPizza;

const float M_PI = 3.14159265359;

void main() {
    // Get our coordinates in the texture
    // For now, we'll do a 2D array of images, each image representing a panel
    // refresh
    vec2 refreshMod = mod(ex_UV, 1.0 / vec2(4.0, 8.0));
    vec2 refreshPos = (ex_UV - refreshMod) * vec2(4.0, 8.0);
    // Angle would be more correct, since this value is in [0, 1]
    float refreshNo = (refreshPos.y * 4.0 + refreshPos.x) / 32.0;

    /* Pack coordinates in a vector
     * As our current y value represents how deep we are in the voxels, it is
     * our 3D z position.
     * And xy will be xy in 3D :)
     */
    vec3 fragPos = vec3(refreshNo, refreshMod.x * 4.0, refreshMod.y * 8.0);

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
    vec4 color;
    if (fragPos.z < 1.0 / float(N_DRAW_BUFFER))
        color = texture(tex0, fragPos.xy);
    else if (fragPos.z < 2.0 / float(N_DRAW_BUFFER))
        color = texture(tex1, fragPos.xy);
    else if (fragPos.z < 3.0 / float(N_DRAW_BUFFER))
        color = texture(tex2, fragPos.xy);
    else if (fragPos.z < 4.0 / float(N_DRAW_BUFFER))
        color = texture(tex3, fragPos.xy);
    else if (fragPos.z < 5.0 / float(N_DRAW_BUFFER))
        color = texture(tex4, fragPos.xy);
    else if (fragPos.z < 6.0 / float(N_DRAW_BUFFER))
        color = texture(tex5, fragPos.xy);
    else if (fragPos.z < 7.0 / float(N_DRAW_BUFFER))
        color = texture(tex6, fragPos.xy);
    else if (fragPos.z < 8.0 / float(N_DRAW_BUFFER))
        color = texture(tex7, fragPos.xy);

    // Get our height in the texture
    float z = mod(fragPos.z * float(N_DRAW_BUFFER), 1.0);
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
    if (abs(mod(v * 255.0, 2.0) - 1.0) < 0.005) out_Color = vec4(1.0);
}
