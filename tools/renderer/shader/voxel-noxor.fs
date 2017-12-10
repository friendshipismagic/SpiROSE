in vec4 fPosition;
in vec3 fColor;
out vec4 fragColor0;
out vec4 fragColor1;
out vec4 fragColor2;
out vec4 fragColor3;
out vec4 fragColor4;
out vec4 fragColor5;
out vec4 fragColor6;
out vec4 fragColor7;

// Used in non-xor mode
void setOutput(in float z, in int layer, out vec4 frag) {
    frag.r = step(z, float(layer * 4 + 0) / 32) / 255;
    frag.g = step(z, float(layer * 4 + 1) / 32) / 255;
    frag.b = step(z, float(layer * 4 + 2) / 32) / 255;
    frag.a = step(z, float(layer * 4 + 3) / 32) / 255;
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
