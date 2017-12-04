#version 330 core

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

uniform bool useXor;

void main() {
    gl_Position = matModel * vec4(in_Pos, 1);

    // Fetch the texel that concerns us.
    if (useXor)
        vColor = texture(voxels0, (gl_Position.xy / 2 + 0.5));
    else {
        if (gl_Position.z < 1/8)      vColor = texture(voxels0, (gl_Position.xy / 2 + 0.5));
        else if (gl_Position.z < 2/8) vColor = texture(voxels1, (gl_Position.xy / 2 + 0.5));
        else if (gl_Position.z < 3/8) vColor = texture(voxels2, (gl_Position.xy / 2 + 0.5));
        else if (gl_Position.z < 4/8) vColor = texture(voxels3, (gl_Position.xy / 2 + 0.5));
        else if (gl_Position.z < 5/8) vColor = texture(voxels4, (gl_Position.xy / 2 + 0.5));
        else if (gl_Position.z < 6/8) vColor = texture(voxels5, (gl_Position.xy / 2 + 0.5));
        else if (gl_Position.z < 7/8) vColor = texture(voxels6, (gl_Position.xy / 2 + 0.5));
        else if (gl_Position.z < 8/8) vColor = texture(voxels7, (gl_Position.xy / 2 + 0.5));
    }
}
