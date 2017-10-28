#version 440 core

in vec2 position;

uniform float time;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);

    gl_Position.x += sin(time) / 2;
    gl_Position.y += sin(time * 5.3) / 20;
}
