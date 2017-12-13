in vec3 position;

#ifndef GL_GEOMETRY_SHADER
out vec4 fPosition;
out vec3 fColor;
#else
out vec3 color;
#endif
out vec2 tex;

uniform float time;
uniform mat4 matModel;

#ifndef GL_GEOMETRY_SHADER
uniform mat4 matProjection, matView;
#endif

void main() {
    gl_Position = matModel * vec4(position, 1.0);
#ifdef GL_GEOMETRY_SHADER
    color.b = 0.0;
    color.rg = (gl_Position.xy + vec2(0.5));
#else
    gl_Position = matProjection * matView * gl_Position;
    fPosition = gl_Position;
    fColor.b = 0.0;
    fColor.rg = (gl_Position.xy + vec2(0.5));
#endif

    tex = vec2(0.0);
}
