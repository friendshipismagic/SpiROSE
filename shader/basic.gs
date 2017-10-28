#version 410 core

layout(triangles) in;
layout(triangle_strip, max_vertices = 9) out;

in vec3 vColor[];  // Output from vertex shader for each vertex
out vec3 fColor;   // Output to fragment shader

vec3 intersect(in vec3 p1, in vec3 p2) {
    float d = -p1.x / (p2 - p1).x;
    return d * (p2 - p1) + p1;
}

bool isInTriangle(in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2) {
    float area = (-p1.y * p2.x + p0.y * (p2.x - p1.x) + p0.x * (p1.y - p2.y) +
                  p1.x * p2.y) /
                 2,
          sA = sign(area),
          s = (p0.y * p2.x - p0.x * p2.y + (p2.y - p0.y) * p.x +
               (p0.x - p2.x) * p.y) *
              sA,
          t = (p0.x * p1.y - p0.y * p1.x + (p0.y - p1.y) * p.x +
               (p1.x - p0.x) * p.y) *
              sA;
    return s > 0 && t > 0 && (s + t) < 2 * area * sA;
}

void main() {
    fColor = vec3(1);

    vec3 v1 = gl_in[0].gl_Position.xyz, v2 = gl_in[1].gl_Position.xyz,
         v3 = gl_in[2].gl_Position.xyz;
    bool originInTriangle = isInTriangle(vec2(0), v1.xy, v2.xy, v3.xy);

    // Intermediate points to test collisions
    vec3 v12 = intersect(v1, v2), v13 = intersect(v1, v3),
         v23 = intersect(v1, v2);
    bool v12c =
             v12.y <= 0 && v12.x >= min(v1.x, v2.x) && v12.x <= max(v1.x, v2.x),
         v13c =
             v13.y <= 0 && v13.x >= min(v1.x, v3.x) && v13.x <= max(v1.x, v3.x),
         v23c =
             v23.y <= 0 && v23.x >= min(v1.x, v2.x) && v23.x <= max(v1.x, v2.x);

    // If the triangle is not being cut
    if ((v1.x >= 0 && v2.x >= 0 && v3.x >= 0) ||
        (v1.x <= 0 && v2.x <= 0 && v3.x <= 0) ||
        (v1.y >= 0 && v2.y >= 0 && v3.y >= 0) ||
        !(v12c || v13c || v23c) && !originInTriangle) {
        // Emit it without modification
        for (int i = 0; i < 3; i++) {
            gl_Position = gl_in[i].gl_Position;
            EmitVertex();
        }
        EndPrimitive();
        return;
    }

    // Simple case : one vertex is opposite of the y = 0 plane AND origin is in
    // the triangle
    if (originInTriangle) {
        // Find the two that intersect the cut plane
        vec3 d1, d2, u;

        if (v1.y < v2.y && v1.y < v3.y) {
            d1 = v1;
            d2 = v2;
            u = v3;
        }
        if (v2.y < v1.y && v2.y < v3.y) {
            d1 = v2;
            d2 = v3;
            u = v1;
        }
        if (v3.y < v1.y && v3.y < v2.y) {
            d1 = v3;
            d2 = v1;
            u = v2;
        }

        // If d1 and d2 are on the same side, swap u and d2
        if (d1.x * d2.x > 0) {
            vec3 temp = u;
            u = d2;
            d2 = temp;
        }
        // If d2 and u are on the same side and u is lower than d2, swap them
        if (d2.x * u.x > 0 && u.y < d2.y) {
            vec3 temp = u;
            u = d2;
            d2 = temp;
        }

        gl_Position = vec4(u, 1);
        EmitVertex();
        gl_Position = vec4(d1, 1);
        EmitVertex();
        gl_Position = vec4(0, 0, 0, 1);
        EmitVertex();
        gl_Position = vec4(intersect(d1, d2), 1);
        EmitVertex();
        EndPrimitive();
        gl_Position = vec4(intersect(d1, d2), 1);
        EmitVertex();
        gl_Position = vec4(0, 0, 0, 1);
        EmitVertex();
        gl_Position = vec4(d2, 1);
        EmitVertex();
        gl_Position = vec4(u, 1);
        EmitVertex();
        EndPrimitive();

        return;
    }

    // Simple case : one vertex is on the slicing plane
    if (v1.x == 0 || v2.x == 0 || v3.x == 0) {
        vec3 a, b, c;

        if (v1.x == 0) {
            a = v1.xyz;
            b = v2.xyz;
            c = v3.xyz;
        } else if (v2.x == 0) {
            a = v2.xyz;
            b = v1.xyz;
            c = v3.xyz;
        } else {
            a = v3.xyz;
            b = v1.xyz;
            c = v2.xyz;
        }

        vec3 d = intersect(b, c);

        gl_Position = vec4(b, 1);
        EmitVertex();
        gl_Position = vec4(a, 1);
        EmitVertex();
        gl_Position = vec4(d, 1);
        EmitVertex();
        gl_Position = vec4(c, 1);
        EmitVertex();
        EndPrimitive();
        return;
    }

#ifdef DISABLE_OTHERS
    return;
#endif
    // Vertices on each side. Whatever the real side is, we'll consider that
    // left is the side with two vertices.
    vec3 l1, l2, r, right = vec3(1, 0, 0);

    if (v1.x * v2.x > 0) {
        l1 = v1;
        l2 = v2;
        r = v3;
    }
    if (v1.x * v3.x > 0) {
        l1 = v1;
        l2 = v3;
        r = v2;
    }
    if (v2.x * v3.x > 0) {
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
    gl_Position = vec4(l1, 1);
    EmitVertex();
    gl_Position = vec4(l2, 1);
    EmitVertex();
    EndPrimitive();
}
