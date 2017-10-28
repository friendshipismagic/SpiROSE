#version 410 core

layout(triangles) in;
layout(triangle_strip, max_vertices = 8) out;

void main() {
    vec3 vecX = vec3(gl_in[0].gl_Position.x, gl_in[1].gl_Position.x,
                     gl_in[2].gl_Position.x);

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
            a = gl_in[0].gl_Position.xyz;
            b = gl_in[1].gl_Position.xyz;
            c = gl_in[2].gl_Position.xyz;
        } else if (vecX.y == 0) {
            a = gl_in[1].gl_Position.xyz;
            b = gl_in[0].gl_Position.xyz;
            c = gl_in[2].gl_Position.xyz;
        } else {
            a = gl_in[2].gl_Position.xyz;
            b = gl_in[0].gl_Position.xyz;
            c = gl_in[1].gl_Position.xyz;
        }

        gl_Position = vec4(a, 1);
        EmitVertex();
        gl_Position = vec4(b, 1);
        EmitVertex();
        gl_Position = vec4((b + c) / 2, 1);
        EmitVertex();
        EndPrimitive();
        gl_Position = vec4((b + c) / 2, 1);
        EmitVertex();
        gl_Position = vec4(c, 1);
        EmitVertex();
        gl_Position = vec4(a, 1);
        EmitVertex();
        EndPrimitive();
        return;
    }

    for (int i = 0; i < 3; i++) {
        gl_Position = gl_in[i].gl_Position;
        EmitVertex();
    }
    EndPrimitive();
}
