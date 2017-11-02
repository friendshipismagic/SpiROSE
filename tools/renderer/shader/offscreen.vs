#version 330 core

in vec2 in_Pos;
in vec2 in_UV;

out vec2 ex_UV;

void main() {
    gl_Position = vec4(in_Pos, 0, 1);
    ex_UV = in_UV;
}
