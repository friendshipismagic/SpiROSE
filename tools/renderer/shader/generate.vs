layout(location = 0) in vec3 in_Pos;
out vec4 vColor;

uniform mat4 matModel;
uniform sampler2D voxels;

void main() {
    gl_Position = matModel * vec4(in_Pos, 1.0);

    // Fetch the texel that concerns us.
    vColor = texture(voxels, (gl_Position.xy / 2.0 + 0.5));
}
