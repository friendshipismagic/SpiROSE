in vec4 fPosition;
in vec3 fColor;
layout(location = 0) out vec4 fragColor;

void main() {
    // Determine a bitmask from the z position (aka distance from camera aka
    // distance from the top)
    // Camera's pointing down, so z is actually upside down
    float z = -fPosition.z / 2.0 + 0.5;

    ivec4 val = ivec4(0.0);
    for (int r = 0; r < 8; r++)
        if (z > float(r) / 32.0) val.r |= 1 << (r - 0);
    for (int g = 8; g < 16; g++)
        if (z > float(g) / 32.0) val.g |= 1 << (g - 8);
    for (int b = 16; b < 24; b++)
        if (z > float(b) / 32.0) val.b |= 1 << (b - 16);
    for (int a = 24; a < 32; a++)
        if (z > float(a) / 32.0) val.a |= 1 << (a - 24);

    fragColor = vec4(val) / 255.0;
}
