in vec4 fPosition;
in vec3 fColor;

/* We don't need to check the first 4 as this number will always be at least 4,
 * as per the spec.
 */
layout(location = 0) out vec4 fragColor0;
#if N_DRAW_BUFFER > 1
layout(location = 1) out vec4 fragColor1;
#endif
#if N_DRAW_BUFFER > 2
layout(location = 2) out vec4 fragColor2;
#endif
#if N_DRAW_BUFFER > 3
layout(location = 3) out vec4 fragColor3;
#endif
#if N_DRAW_BUFFER > 4
layout(location = 4) out vec4 fragColor4;
#endif
#if N_DRAW_BUFFER > 5
layout(location = 5) out vec4 fragColor5;
#endif
#if N_DRAW_BUFFER > 6
layout(location = 6) out vec4 fragColor6;
#endif
#if N_DRAW_BUFFER > 7
layout(location = 7) out vec4 fragColor7;
#endif

uniform int nPass;

// Used in non-xor mode
void setOutput(in float z, in int layer, out vec4 frag) {
    frag.r = step(z, (float(layer) * 4.0 + 0.0) / float(RES_H)) / 255.0;
    frag.g = step(z, (float(layer) * 4.0 + 1.0) / float(RES_H)) / 255.0;
    frag.b = step(z, (float(layer) * 4.0 + 2.0) / float(RES_H)) / 255.0;
    frag.a = step(z, (float(layer) * 4.0 + 3.0) / float(RES_H)) / 255.0;
}

void main() {
    // Determine a bitmask from the z position (aka distance from camera aka
    // distance from the top)
    // Camera's pointing down, so z is actually upside down
    float z = -fPosition.z / 2.0 + 0.5;

    int offset = nPass * N_DRAW_BUFFER;
    setOutput(z, 0 + offset, fragColor0);
#if N_DRAW_BUFFER > 1
    setOutput(z, 1 + offset, fragColor1);
#endif
#if N_DRAW_BUFFER > 2
    setOutput(z, 2 + offset, fragColor2);
#endif
#if N_DRAW_BUFFER > 3
    setOutput(z, 3 + offset, fragColor3);
#endif
#if N_DRAW_BUFFER > 4
    setOutput(z, 4 + offset, fragColor4);
#endif
#if N_DRAW_BUFFER > 5
    setOutput(z, 5 + offset, fragColor5);
#endif
#if N_DRAW_BUFFER > 6
    setOutput(z, 6 + offset, fragColor6);
#endif
#if N_DRAW_BUFFER > 7
    setOutput(z, 7 + offset, fragColor7);
#endif
}
