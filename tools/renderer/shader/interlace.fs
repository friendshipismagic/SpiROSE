#version 330 core

in vec2 ex_UV;

out vec4 out_Color;

uniform sampler2D tex;
uniform bool doPizza;

const float M_PI = 3.14159265359;

void main() {
    // Get our coordinates in the texture
    // For now, we'll do a 2D array of images, each image representing a panel
    // refresh
    vec2 refreshMod = mod(ex_UV, 1.0 / vec2(8.0, 4.0));
    vec2 refreshPos = (ex_UV - refreshMod) * vec2(8.0, 4.0);
    float refreshNo = (refreshPos.y * 8.0 + refreshPos.x) / 32.0;

    vec3 fragPos = vec3(refreshNo, refreshMod.x * 8, refreshMod.y * 4);

    if (doPizza && 1 == 2) {
        fragPos.x *= M_PI * 4;
        fragPos.xy =
            vec2(sin(fragPos.x), -cos(fragPos.x)) * fragPos.y / 2.0 + 0.5;
    }

    ivec4 color = ivec4(texture(tex, fragPos.xy) * 255);
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
