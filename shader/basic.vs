#version 410 core

in vec2 position;
out vec3 color;

uniform float time;
uniform mat4 matMV;

void main() {
    gl_Position = matMV * vec4(position, 0.0, 1.0);
    color.b = 0;
    color.rg = (gl_Position.xy + vec2(0.5));
}
