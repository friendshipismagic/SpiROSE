#version 330 core

in vec3 position;
out vec3 color;

uniform float time;
uniform mat4 matModel;

void main() {
    gl_Position = matModel * vec4(position, 1.0);
    color.b = 0;
    color.rg = (gl_Position.xy + vec2(0.5));
}
