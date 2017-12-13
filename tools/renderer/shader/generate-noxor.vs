in vec3 in_Pos;

#ifndef HAS_GEOMETRY_SHADER
out vec4 color;
#else
out vec4 vColor;
#endif

uniform mat4 matModel;
#ifndef HAS_GEOMETRY_SHADER
uniform mat4 matProjection, matView;
#endif

uniform sampler2D voxels0;
uniform sampler2D voxels1;
uniform sampler2D voxels2;
uniform sampler2D voxels3;
uniform sampler2D voxels4;
uniform sampler2D voxels5;
uniform sampler2D voxels6;
uniform sampler2D voxels7;

void main() {
    gl_Position = matModel * vec4(in_Pos, 1.0);

    // Map back to [0, 1]
    vec3 p = gl_Position.xyz / 2.0 + 0.5;

    vec4 c;
    // Fetch the texel that concerns us.
    if (p.z < 1.0 / 8.0)
        c = texture(voxels0, p.xy);
    else if (p.z < 2.0 / 8.0)
        c = texture(voxels1, p.xy);
    else if (p.z < 3.0 / 8.0)
        c = texture(voxels2, p.xy);
    else if (p.z < 4.0 / 8.0)
        c = texture(voxels3, p.xy);
    else if (p.z < 5.0 / 8.0)
        c = texture(voxels4, p.xy);
    else if (p.z < 6.0 / 8.0)
        c = texture(voxels5, p.xy);
    else if (p.z < 7.0 / 8.0)
        c = texture(voxels6, p.xy);
    else if (p.z < 8.0 / 8.0)
        c = texture(voxels7, p.xy);

#ifndef HAS_GEOMETRY_SHADER
    color = vec4(gl_Position.xyz / 2.0 + vec3(0.5), 1.0);

    // Map back to [0, 1]
    float z = mod((gl_Position.z / 2.0 + 0.5) * 8.0, 1.0);

    // Fetch the correct channel
    // Note, this can be done without a single if by using the step function and
    // a bunch of multiplications
    float v;
    if (z < 0.25)
        v = c.r;
    else if (z < 0.50)
        v = c.g;
    else if (z < 0.75)
        v = c.b;
    else
        v = c.a;

    if (abs(mod(v * 255.0, 2.0) - 1.0) >= 0.005)
        gl_Position = vec4(1000.0);
    else
        gl_Position = matProjection * matView * gl_Position;
#else
    vColor = c;
#endif
}
