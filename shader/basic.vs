#version 440 core

in vec2 position;

uniform float time;
uniform mat4 matMV;

void main() { gl_Position = matMV * vec4(position, 0.0, 1.0); }
