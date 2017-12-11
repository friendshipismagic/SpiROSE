#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 14) out;

uniform mat4 matProjection, matView;
uniform bool doPizza;

in vec4 vColor[];
out vec4 color;

const float M_PI = 3.14159265359;
void emit(in vec3 v) {
    // Reversing the pizza transform ?
    if (doPizza) {
        // Get back x, y in [0, 1] range
        vec2 thetal = v.xy * 0.5 + 0.5;
        // x in [0, 2pi] range
        thetal.x *= M_PI * 2;
        // polar -> cartesian
        v = vec3(sin(thetal.x), -cos(thetal.x), v.z);
        v.xy *= thetal.y;
    }
    gl_Position = matProjection * matView * vec4(v, 1);
    EmitVertex();
}

vec3 v[8] = vec3[](vec3(1, 1, 0) / 16, vec3(0, 1, 0) / 16, vec3(1, 0, 0) / 16,
                   vec3(0, 0, 0) / 16, vec3(1, 1, 1) / 16, vec3(0, 1, 1) / 16,
                   vec3(0, 0, 1) / 16, vec3(1, 0, 1) / 16);

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
    vec3 vert = gl_in[0].gl_Position.xyz;

    // Convert the input float to an int that we can work with
    ivec4 c = ivec4(vColor[0] * 255);
    // Map back to [0, 1]
    float z = vert.z / 2 + 0.5;

    // Get our bitwise position
    int p = 1 << int(mod(z * 32, 8));

    // To help visualisation
    color.rgb = vert.xyz / 2.0 + 0.5;
    color.a = 1;

    // Fetch the correct channel
    // Note, this can be done without a single if by using the step function and
    // a bunch of multiplications
    int v;
    if (z < 0.25)
        v = c.r;
    else if (z < 0.50)
        v = c.g;
    else if (z < 0.75)
        v = c.b;
    else
        v = c.a;

    // If the bit is one, then output a cube
    if ((v & p) != 0) cube(vert);
}
