in vec3 in_Pos;
out vec4 vColor;

uniform mat4 matModel;
uniform sampler2D voxels0;
uniform sampler2D voxels1;
uniform sampler2D voxels2;
uniform sampler2D voxels3;
uniform sampler2D voxels4;
uniform sampler2D voxels5;
uniform sampler2D voxels6;
uniform sampler2D voxels7;

void main() {
    gl_Position = matModel * vec4(in_Pos, 1);

    // Map back to [0, 1]
    vec3 p = gl_Position.xyz / 2 + 0.5;

    // Fetch the texel that concerns us.
    if (p.z < 1.0 / 8.0)
        vColor = texture(voxels0, p.xy);
    else if (p.z < 2.0 / 8.0)
        vColor = texture(voxels1, p.xy);
    else if (p.z < 3.0 / 8.0)
        vColor = texture(voxels2, p.xy);
    else if (p.z < 4.0 / 8.0)
        vColor = texture(voxels3, p.xy);
    else if (p.z < 5.0 / 8.0)
        vColor = texture(voxels4, p.xy);
    else if (p.z < 6.0 / 8.0)
        vColor = texture(voxels5, p.xy);
    else if (p.z < 7.0 / 8.0)
        vColor = texture(voxels6, p.xy);
    else if (p.z < 8.0 / 8.0)
        vColor = texture(voxels7, p.xy);
}
