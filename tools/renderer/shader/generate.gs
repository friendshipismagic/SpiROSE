#version 410 core

layout(points) in;
layout(triangle_strip, max_vertices = 14) out;

uniform mat4 matProjection, matView;
uniform sampler2D voxels;

void emit(in vec3 v) {
    gl_Position = matProjection * matView * vec4(v, 1);
    EmitVertex();
}

vec3 v[8] = vec3[](vec3(1, 1, 0) / 32, vec3(0, 1, 0) / 32, vec3(1, 0, 0) / 32,
                   vec3(0, 0, 0) / 32, vec3(1, 1, 1) / 32, vec3(0, 1, 1) / 32,
                   vec3(0, 0, 1) / 32, vec3(1, 0, 1) / 32);

// Thanks to the following paper on how to make a cube with a single triangle
// strip http://www.cs.umd.edu/gvil/papers/av_ts.pdf
void cube(in vec3 p) {
    emit(p + v[3]);
    emit(p + v[2]);
    emit(p + v[6]);
    emit(p + v[7]);
    emit(p + v[4]);
    emit(p + v[2]);
    emit(p + v[0]);
    emit(p + v[3]);
    emit(p + v[1]);
    emit(p + v[6]);
    emit(p + v[5]);
    emit(p + v[4]);
    emit(p + v[1]);
    emit(p + v[0]);
    EndPrimitive();
}

void main() {
    // Fetching back our bit
    vec3 p = gl_in[0].gl_Position.xyz;
    cube(p);
    EndPrimitive();
    return;

    /*
	vec3 vert;

	if (abs(vert.z) > 1) return;

	ivec4 c = ivec4(texture(voxels, vert.xy * 2 - vec2(1)) * 256);
	int bits = c.r | (c.g << 8) | (c.b << 16) | (c.a << 24);

	if ((bits & (1 << (1 - int((vert.z + 1) / 2)))) != 0) cube(vert);
}

