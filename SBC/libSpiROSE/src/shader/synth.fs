/**
 * Synthesize algorithm, fragment shader.
 * Role: generate microblocks
 */

in vec2 ex_UV;

/* origin_upper_left:
 *     coordinates origin is at the top left corner of the screen rather than
 *     the bottom left. This is the desired behaviour since we want to send the
 *     first slice first, and video output starts at the top left.
 * pixel_center_integer:
 *     by default, coordinates are the pixel's corner. However, the math was
 *     written (and tested) for pixel-center coordinates.
 */
layout(origin_upper_left, pixel_center_integer) in vec4 gl_FragCoord;

layout(location = 0) out vec4 out_Color;

// Voxel buffers
uniform sampler2D voxels[N_VOXEL_BUFFER];
uniform vec4 in_Color;

#define M_PI 3.14159265359;
const float nVoxelPass = float(N_VOXEL_PASS);

const float w = float(RES_W * SYNTH_W / 2), h = float(RES_H * SYNTH_H);
const float resW = float(RES_W / 2), resH = float(RES_H), resC = float(RES_C);
const float nPixels = resW * resH;

void main() {
    /* Fetch the pixel number. If we view our screen as a 1D buffer where all
     * lines follow each other, this is our X coordinate.
     */
    float pixelNo = gl_FragCoord.x + gl_FragCoord.y * w;
    // ublock we are in, and which pixel no of the ublock we are
    float ublockNo = floor(pixelNo / nPixels),
          ublockPixelNo = mod(pixelNo, nPixels);

    // Get our coordinates in a micro-block
    vec2 refreshMod =
        (vec2(mod(ublockPixelNo, resW), floor(ublockPixelNo / resW)) + 0.5) /
        vec2(resW, resH);

    // Number in [0, 1] telling at which refresh stop we are
    float refreshNo = ublockNo / resC;

    /* Pack coordinates in a vector
     * As our current y value represents how deep we are in the voxels, it is
     * our 3D z position.
     */
    vec3 fragPos = vec3(refreshNo, refreshMod.x, 1.0 - refreshMod.y);

    // We need to flip the second half of the slices
    float flip = step(0.5, refreshNo) * 2.0 - 1.0;
    // Convert refreshNo to the angle of the panel
    refreshNo *= 2.0 * M_PI;
    /* Rotate the panel around the (0.5, 0.5) point
     * Adding 0.5/RES_W allows us to shift by half a texel, and because a voxel
     * texture has 2x more pixels than the synth output, this will effectively
     * sample even columns, except for the second half where odd will be sampled
     * thanks to the flip.
     * The last flip is used to flip the output horizontally for the second half
     * of a turn.
     */
    fragPos.xy = 0.5 + vec2(sin(refreshNo), -cos(refreshNo)) *
                           (fragPos.y - 0.5 + (flip * 0.5 / float(RES_W))) *
                           flip;

    float modZ = mod(fragPos.z, 1.0 / nVoxelPass) * float(RES_H / 4);
    vec2 modST = fragPos.xy / vec2(nVoxelPass, 1.0) +
                 vec2(floor(fragPos.z * nVoxelPass) / nVoxelPass, 0.0);

    /* Sample the proper texture depending on our height. We *still* need the
     * conditions as most GL implementations do not support dynamic indexing
     * of sampler arrays
     */
    vec4 color;
    if (modZ < 1.0)
        color = texture(voxels[0], modST);
    else if (modZ < 2.0)
        color = texture(voxels[1], modST);
    else if (modZ < 3.0)
        color = texture(voxels[2], modST);
    else if (modZ < 4.0)
        color = texture(voxels[3], modST);
#if N_VOXEL_BUFFER > 4
    else if (modZ < 5.0)
        color = texture(voxels[4], modST);
#endif
#if N_VOXEL_BUFFER > 5
    else if (modZ < 6.0)
        color = texture(voxels[5], modST);
#endif
#if N_VOXEL_BUFFER > 6
    else if (modZ < 7.0)
        color = texture(voxels[6], modST);
#endif
#if N_VOXEL_BUFFER > 7
    else if (modZ < 8.0)
        color = texture(voxels[7], modST);
#endif

    // Get our height in the layer pack to use the proper color channel
    float z = mod(fragPos.z * float(RES_H / 4), 1.0);
    float v;
    if (z < 0.25)
        v = color.r;
    else if (z < 0.5)
        v = color.g;
    else if (z < 0.75)
        v = color.b;
    else
        v = color.a;

    out_Color = in_Color;
    if (abs(mod(v * 255.0, 2.0) - 1.0) >= 0.1) discard;
}
