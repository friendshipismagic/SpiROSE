/**
 * Synthesize algorithm, vertex shader.
 * Role: passthrough
 */

layout(location = 0) in vec2 in_Pos;
layout(location = 1) in vec2 in_UV;

out vec2 ex_UV;

void main() {
    gl_Position = vec4(in_Pos, 0.0, 1.0);
    ex_UV = in_UV;
}
