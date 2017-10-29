#version 410 core

layout(triangles) in;
layout(triangle_strip, max_vertices = 42) out;

in vec3 color[];  // Output from vertex shader for each vertex
in vec2 tex[];

out vec3 fColor;  // Output to fragment shader
out vec2 fTexture;

struct Vertex {
    vec3 p;  // Position
    vec3 c;  // Color
    vec2 t;  // Texture
};

vec3 intersect(in vec3 p1, in vec3 p2) {
    float d = -p1.x / (p2 - p1).x;
    return d * (p2 - p1) + p1;
}
Vertex intersect(in Vertex v1, in Vertex v2) {
    float d = -v1.p.x / (v2.p - v1.p).x;
    return Vertex(d * (v2.p - v1.p) + v1.p, d * (v2.c - v1.c) + v1.c,
                  d * (v2.t - v1.t) + v1.t);
}
Vertex intersect(in Vertex v1, in Vertex v2, in Vertex v3) {
    vec2 p = vec2(0), p0 = v1.p.xy, p1 = v2.p.xy, p2 = v3.p.xy;

    vec2 e0 = p1 - p0, e1 = p2 - p0, e2 = p - p0;
    float d00 = dot(e0, e0), d01 = dot(e0, e1), d11 = dot(e1, e1),
          d20 = dot(e2, e0), d21 = dot(e2, e1);
    float d = d00 * d11 - d01 * d01;
    float v = (d11 * d20 - d01 * d21) / d, w = (d00 * d21 - d01 * d20) / d,
          u = 1.0 - v - w;

    return Vertex(vec3(0, 0, u * v1.p.z + v * v2.p.z + w * v3.p.z),
                  u * v1.c + v * v2.c + w * v3.c,
                  u * v1.t + v * v2.t + w * v3.t);
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
bool isInTriangle(in vec2 p, in Vertex p0, in Vertex p1, in Vertex p2) {
    return isInTriangle(p, p0.p.xy, p1.p.xy, p2.p.xy);
}

void emit(in vec3 v) {
    gl_Position = vec4(v, 1);
    EmitVertex();
}
void emit(in Vertex v) {
    gl_Position = vec4(v.p, 1);
    fColor = v.c;
    fTexture = v.t;
    EmitVertex();
}

bool doTransform = true;

// Does the magic
const float M_PI = 3.14159265359;
vec3 transform(in vec3 v, in vec3 ref) {
    if (!doTransform) return v;

    float l = length(v), angle = atan(ref.x / -ref.y);

    if (ref.y == 0) angle = ref.x > 0 ? M_PI / 2 : 3 * M_PI / 2;
    if (ref.y > 0) angle += M_PI;
    if (ref.y < 0 && ref.x < 0) angle += 4 * M_PI / 2;

    return vec3(angle / (2 * M_PI) / 2, l, v.z) + vec3(0.5, 0, 0);
}
vec3 transform(in vec3 v, in float sign) {
    if (!doTransform) return v;

    return vec3(max(sign, 0) / 2, length(v), v.z) + vec3(0.5, 0, 0);
}
vec3 transform(in vec3 v) { return transform(v, v); }

Vertex transform(in Vertex v, in Vertex ref) {
    return Vertex(transform(v.p, ref.p), v.c, v.t);
}
Vertex transform(in Vertex v, in float sign) {
    return Vertex(transform(v.p, sign), v.c, v.t);
}
Vertex transform(in Vertex v) { return Vertex(transform(v.p, v.p), v.c, v.t); }

void swap(inout vec3 v1, inout vec3 v2) {
    vec3 tmp = v1;
    v1 = v2;
    v2 = tmp;
}
void swap(inout Vertex v1, inout Vertex v2) {
    Vertex tmp = v1;
    v1 = v2;
    v2 = tmp;
}

const vec3 zero = vec3(0);
void main() {
    Vertex v1 = Vertex(gl_in[0].gl_Position.xyz, color[0], tex[0]),
           v2 = Vertex(gl_in[1].gl_Position.xyz, color[1], tex[1]),
           v3 = Vertex(gl_in[2].gl_Position.xyz, color[2], tex[2]);

    bool originInTriangle = isInTriangle(vec2(0), v1, v2, v3);

    // Intermediate points to test collisions
    Vertex v12 = intersect(v1, v2), v13 = intersect(v1, v3),
           v23 = intersect(v1, v2);
    bool v12c = v12.p.y <= 0 && v12.p.x >= min(v1.p.x, v2.p.x) &&
                v12.p.x <= max(v1.p.x, v2.p.x) &&
                v12.p.y >= min(v1.p.y, v2.p.y) &&
                v12.p.y <= max(v1.p.y, v2.p.y),
         v13c = v13.p.y <= 0 && v13.p.x >= min(v1.p.x, v3.p.x) &&
                v13.p.x <= max(v1.p.x, v3.p.x) &&
                v13.p.y >= min(v1.p.y, v3.p.y) &&
                v13.p.y <= max(v1.p.y, v3.p.y),
         v23c = v23.p.y <= 0 && v23.p.x >= min(v2.p.x, v3.p.x) &&
                v23.p.x <= max(v2.p.x, v3.p.x) &&
                v23.p.y >= min(v2.p.y, v3.p.y) &&
                v23.p.y <= max(v2.p.y, v3.p.y);

    // If the triangle is not being cut
    if ((v1.p.x >= 0 && v2.p.x >= 0 && v3.p.x >= 0) ||
        (v1.p.x <= 0 && v2.p.x <= 0 && v3.p.x <= 0) ||
        (v1.p.y >= 0 && v2.p.y >= 0 && v3.p.y >= 0) ||
        !(v12c || v13c || v23c) && !originInTriangle) {
#ifdef DISABLE_OTHERS
        return;
#endif
        // Emit it without modification
        emit(transform(v1));
        emit(transform(v2));
        emit(transform(v3));
        EndPrimitive();
        doTransform = false;
        emit(transform(v1));
        emit(transform(v2));
        emit(transform(v3));
        EndPrimitive();
        return;
    }

    // Simple case : one vertex is opposite of the y = 0 plane AND origin is in
    // the triangle
    if (originInTriangle) {
        // Find the two that intersect the cut plane
        Vertex d1, d2, u;

        if (v1.p.y < v2.p.y && v1.p.y < v3.p.y) {
            d1 = v1;
            d2 = v2;
            u = v3;
        }
        if (v2.p.y < v1.p.y && v2.p.y < v3.p.y) {
            d1 = v2;
            d2 = v3;
            u = v1;
        }
        if (v3.p.y < v1.p.y && v3.p.y < v2.p.y) {
            d1 = v3;
            d2 = v1;
            u = v2;
        }

        // If d1 and d2 are on the same side, swap u and d2
        if (d1.p.x * d2.p.x > 0) swap(u, d2);
        // If d2 and u are on the same side and u is lower than d2, swap them
        if (d2.p.x * u.p.x > 0 && u.p.y < d2.p.y) swap(u, d2);

        Vertex m = intersect(d1, d2), zero = intersect(v1, v2, v2);

        emit(transform(zero, -sign(d1.p.x)));
        emit(transform(m, -sign(d1.p.x)));
        emit(transform(zero, d1));
        emit(transform(d1));
        emit(transform(zero, u));
        emit(transform(u));
        emit(transform(zero, d2));
        emit(transform(d2));
        emit(transform(zero, -sign(d2.p.x)));
        emit(transform(m, -sign(d2.p.x)));
        EndPrimitive();
        doTransform = false;
        emit(transform(zero, -sign(d1.p.x)));
        emit(transform(m, -sign(d1.p.x)));
        emit(transform(zero, d1));
        emit(transform(d1));
        emit(transform(zero, u));
        emit(transform(u));
        emit(transform(zero, d2));
        emit(transform(d2));
        emit(transform(zero, -sign(d2.p.x)));
        emit(transform(m, -sign(d2.p.x)));
        EndPrimitive();
        return;
    }

    // Simple case : one vertex is on the slicing plane
    if (v1.p.x == 0 || v2.p.x == 0 || v3.p.x == 0) {
        Vertex a, b, c;

        if (v1.p.x == 0) {
            a = v1;
            b = v2;
            c = v3;
        } else if (v2.p.x == 0) {
            a = v2;
            b = v1;
            c = v3;
        } else {
            a = v3;
            b = v1;
            c = v2;
        }

        Vertex d = intersect(b, c);

        emit(transform(b));
        emit(transform(a, -sign(b.p.x)));
        emit(transform(d, -sign(b.p.x)));
        EndPrimitive();
        emit(transform(c));
        emit(transform(a, -sign(c.p.x)));
        emit(transform(d, -sign(c.p.x)));
        EndPrimitive();
        doTransform = false;
        emit(transform(b));
        emit(transform(a, -sign(b.p.x)));
        emit(transform(d, -sign(b.p.x)));
        EndPrimitive();
        emit(transform(c));
        emit(transform(a, -sign(c.p.x)));
        emit(transform(d, -sign(c.p.x)));
        EndPrimitive();
        return;
    }

    // Vertices on each side. Whatever the real side is, we'll consider that
    // left is the side with two vertices.
    Vertex l1, l2, r;

    if (v1.p.x * v2.p.x > 0) {
        l1 = v1;
        l2 = v2;
        r = v3;
    }
    if (v1.p.x * v3.p.x > 0) {
        l1 = v1;
        l2 = v3;
        r = v2;
    }
    if (v2.p.x * v3.p.x > 0) {
        l1 = v2;
        l2 = v3;
        r = v1;
    }

    // Middle-ground vertices
    Vertex m1 = intersect(r, l1), m2 = intersect(r, l2);

    // Rightmost triangle
    emit(transform(r));
    emit(transform(m1, -sign(r.p.x)));
    emit(transform(m2, -sign(r.p.x)));
    EndPrimitive();
    emit(transform(m1, -sign(l1.p.x)));
    emit(transform(m2, -sign(l2.p.x)));
    emit(transform(l1));
    emit(transform(l2));
    EndPrimitive();

    emit(r);
    emit(m1);
    emit(m2);
    EndPrimitive();
    emit(m1);
    emit(m2);
    emit(l1);
    emit(l2);
    EndPrimitive();
}
