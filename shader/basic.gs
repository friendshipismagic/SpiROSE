#version 410 core

layout(triangles) in;
layout(triangle_strip, max_vertices = 9) out;

vec3 intersect(in vec3 p1, in vec3 p2) {
    float d = -p1.x / (p2 - p1).x;
    return d * (p2 - p1) + p1;
}

void main() {
    vec3 v1 = gl_in[0].gl_Position.xyz, v2 = gl_in[1].gl_Position.xyz,
         v3 = gl_in[2].gl_Position.xyz;
    vec3 vecX = vec3(v1.x, v2.x, v3.x);

    // If the triangle is not being cut
    if ((vecX.x >= 0 && vecX.y >= 0 && vecX.z >= 0) ||
        (vecX.x <= 0 && vecX.y <= 0 && vecX.z <= 0)) {
        // Emit it without modification
        for (int i = 0; i < 3; i++) {
            gl_Position = gl_in[i].gl_Position;
            EmitVertex();
        }
        EndPrimitive();
        return;
    }

    // Simple case : one vertex is on the slicing plane
    if (vecX.x == 0 || vecX.y == 0 || vecX.z == 0) {
        vec3 a, b, c;

        if (vecX.x == 0) {
            a = v1.xyz;
            b = v2.xyz;
            c = v3.xyz;
        } else if (vecX.y == 0) {
            a = v2.xyz;
            b = v1.xyz;
            c = v3.xyz;
        } else {
            a = v3.xyz;
            b = v1.xyz;
            c = v2.xyz;
        }

        vec3 d = intersect(b, c);

        gl_Position = vec4(a, 1);
        EmitVertex();
        gl_Position = vec4(b, 1);
        EmitVertex();
        gl_Position = vec4(d, 1);
        EmitVertex();
        EndPrimitive();
        gl_Position = vec4(d, 1);
        EmitVertex();
        gl_Position = vec4(c, 1);
        EmitVertex();
        gl_Position = vec4(a, 1);
        EmitVertex();
        EndPrimitive();
        return;
    }

    // Vertices on each side. Whatever the real side is, we'll consider that
    // left is the side with two vertices.
    vec3 l1, l2, r, right = vec3(1, 0, 0);

    if (vecX.x * vecX.y > 0) {
        l1 = v1;
        l2 = v2;
        r = v3;
    }
    if (vecX.x * vecX.z > 0) {
        l1 = v1;
        l2 = v3;
        r = v2;
    }
    if (vecX.y * vecX.z > 0) {
        l1 = v2;
        l2 = v3;
        r = v1;
    }

    // Middle-ground vertices
    vec3 m1 = intersect(r, l1), m2 = intersect(r, l2);

    // Rightmost triangle
    gl_Position = vec4(r, 1);
    EmitVertex();
    gl_Position = vec4(m1, 1);
    EmitVertex();
    gl_Position = vec4(m2, 1);
    EmitVertex();
    EndPrimitive();

    gl_Position = vec4(l1, 1);
    EmitVertex();
    gl_Position = vec4(m1, 1);
    EmitVertex();
    gl_Position = vec4(m2, 1);
    EmitVertex();
    EndPrimitive();

    gl_Position = vec4(l1, 1);
    EmitVertex();
    gl_Position = vec4(l2, 1);
    EmitVertex();
    gl_Position = vec4(m2, 1);
    EmitVertex();
    EndPrimitive();
}
