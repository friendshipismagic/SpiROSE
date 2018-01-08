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

const float nVoxelPass = float(N_VOXEL_PASS);

void main() {
    // The .1 is there cuz' I'm stupid. The points are EXACTLY on the boundaries
    // of voxels, thus there is a slight rounding error, either above or below.
    // This sometimes caused the incorrect layer to be sampled, which resulted
    // in ... very visible visual glitches
    gl_Position = matModel * vec4(in_Pos + vec3(0.0, 0.0, 0.001), 1.0);

    // Map back to [0, 1]
    float resRatio = float(RES_H) / float(RES_W);
    vec3 p = (gl_Position.xyz * vec3(resRatio, resRatio, 1.0)) / 2.0 + 0.5;

    vec4 c;
    float modZ = mod(p.z, 1.0 / nVoxelPass) * float(RES_H / 4);
    vec2 modST = p.xy / vec2(nVoxelPass, 1.0) +
                 vec2(floor(p.z * nVoxelPass) / nVoxelPass, 0.0);

    // Fetch the texel that concerns us.
    if (modZ < 1.0)
        c = texture(voxels0, modST);
    else if (modZ < 2.0)
        c = texture(voxels1, modST);
    else if (modZ < 3.0)
        c = texture(voxels2, modST);
    else if (modZ < 4.0)
        c = texture(voxels3, modST);
    else if (modZ < 5.0)
        c = texture(voxels4, modST);
    else if (modZ < 6.0)
        c = texture(voxels5, modST);
    else if (modZ < 7.0)
        c = texture(voxels6, modST);
    else if (modZ < 8.0)
        c = texture(voxels7, modST);
    else if (modZ < 9.0)
        c = texture(voxels8, modST);
    else if (modZ < 10.0)
        c = texture(voxels9, modST);
    else if (modZ < 11.0)
        c = texture(voxels10, modST);
    else if (modZ < 12.0)
        c = texture(voxels11, modST);
    else if (modZ < 13.0)
        c = texture(voxels12, modST);
    else if (modZ < 14.0)
        c = texture(voxels13, modST);
    else if (modZ < 15.0)
        c = texture(voxels14, modST);
    else if (modZ < 16.0)
        c = texture(voxels15, modST);

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
