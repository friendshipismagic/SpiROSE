#version 410 core

in vec4 fPosition;
in vec3 fColor;
out vec4 fragColor;

void main() {
    // Determine a bitmask from the z position (aka distance from camera aka
    // distance from the top)
    ivec4 val = ivec4(0);
    for (int r = 0; r < 8; r++)
        if (fPosition.z > float(r) / 32) val.r |= 1 << r;
    for (int g = 8; g < 16; g++)
        if (fPosition.z > float(g) / 32) val.g |= 1 << g;
    for (int b = 16; b < 24; b++)
        if (fPosition.z > float(b) / 32) val.b |= 1 << b;
    for (int a = 24; a < 32; a++)
        if (fPosition.z > float(a) / 32) val.a |= 1 << a;

    fragColor = vec4(val) / 256.0;
}
