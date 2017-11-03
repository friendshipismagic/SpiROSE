#version 330 core

in vec3 in_Pos;

uniform mat4 matModel;

void main() { gl_Position = matModel * vec4(in_Pos, 1); }
