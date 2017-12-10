in vec4 fPosition;
in vec3 fColor;
layout(location = 0) out vec4 fragColor0;
layout(location = 1) out vec4 fragColor1;
layout(location = 2) out vec4 fragColor2;
layout(location = 3) out vec4 fragColor3;
layout(location = 4) out vec4 fragColor4;
layout(location = 5) out vec4 fragColor5;
layout(location = 6) out vec4 fragColor6;
layout(location = 7) out vec4 fragColor7;

// Used in non-xor mode
void setOutput(in float z, in int layer, out vec4 frag) {
    frag.r = step(z, (float(layer) * 4.0 + 0.0) / 32.0) / 255.0;
    frag.g = step(z, (float(layer) * 4.0 + 1.0) / 32.0) / 255.0;
    frag.b = step(z, (float(layer) * 4.0 + 2.0) / 32.0) / 255.0;
    frag.a = step(z, (float(layer) * 4.0 + 3.0) / 32.0) / 255.0;
}

void main() {
    // Determine a bitmask from the z position (aka distance from camera aka
    // distance from the top)
    // Camera's pointing down, so z is actually upside down
    float z = -fPosition.z / 2.0 + 0.5;

    setOutput(z, 0, fragColor0);
    setOutput(z, 1, fragColor1);
    setOutput(z, 2, fragColor2);
    setOutput(z, 3, fragColor3);
    setOutput(z, 4, fragColor4);
    setOutput(z, 5, fragColor5);
    setOutput(z, 6, fragColor6);
    setOutput(z, 7, fragColor7);
}
