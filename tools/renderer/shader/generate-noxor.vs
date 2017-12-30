layout(location = 0) in vec3 in_Pos;

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
uniform sampler2D voxels8;
uniform sampler2D voxels9;
uniform sampler2D voxels10;
uniform sampler2D voxels11;
uniform sampler2D voxels12;
uniform sampler2D voxels13;
uniform sampler2D voxels14;
uniform sampler2D voxels15;

void main() {
    gl_Position = matModel * vec4(in_Pos, 1.0);

    // Map back to [0, 1]
    vec3 p =
        (gl_Position.xyz * vec3(1.0, 1.0, float(RES_W) / float(RES_H))) / 2.0 +
        0.5;

    vec4 c;
    // Fetch the texel that concerns us.
    if (p.z < 1.0 / float(RES_H / 4))
        c = texture(voxels0, p.xy);
    else if (p.z < 2.0 / float(RES_H / 4))
        c = texture(voxels1, p.xy);
    else if (p.z < 3.0 / float(RES_H / 4))
        c = texture(voxels2, p.xy);
    else if (p.z < 4.0 / float(RES_H / 4))
        c = texture(voxels3, p.xy);
    else if (p.z < 5.0 / float(RES_H / 4))
        c = texture(voxels4, p.xy);
    else if (p.z < 6.0 / float(RES_H / 4))
        c = texture(voxels5, p.xy);
    else if (p.z < 7.0 / float(RES_H / 4))
        c = texture(voxels6, p.xy);
    else if (p.z < 8.0 / float(RES_H / 4))
        c = texture(voxels7, p.xy);
    else if (p.z < 9.0 / float(RES_H / 4))
        c = texture(voxels8, p.xy);
    else if (p.z < 10.0 / float(RES_H / 4))
        c = texture(voxels9, p.xy);
    else if (p.z < 11.0 / float(RES_H / 4))
        c = texture(voxels10, p.xy);
    else if (p.z < 12.0 / float(RES_H / 4))
        c = texture(voxels11, p.xy);
    else if (p.z < 13.0 / float(RES_H / 4))
        c = texture(voxels12, p.xy);
    else if (p.z < 14.0 / float(RES_H / 4))
        c = texture(voxels13, p.xy);
    else if (p.z < 15.0 / float(RES_H / 4))
        c = texture(voxels14, p.xy);
    else if (p.z < 16.0 / float(RES_H / 4))
        c = texture(voxels15, p.xy);

#ifndef HAS_GEOMETRY_SHADER
    color = vec4(p, 1.0);

    // Map back to [0, 1]
    float z = mod(p.z * float(RES_H / 4), 1.0);

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
    gl_PointSize = 10.0;
#else
    vColor = c;
#endif
}
