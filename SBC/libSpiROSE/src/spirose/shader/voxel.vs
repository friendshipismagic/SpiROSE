/**
 * Voxelization algorithm, vertex shader.
 * Role: apply MVP
 */

layout(location = 0) in vec3 position;

// We have to transmit the fragment's z position to the fragment shader.
out float z;

uniform mat4 matMVP;

void main() {
    gl_Position = matMVP * vec4(position, 1.0);

    /* The camera's looking down, so z is upside down. Moreover, we need it in
     * [0, 1], not in [-1, 1].
     */
    z = -gl_Position.z / 2.0 + 0.5;
}
