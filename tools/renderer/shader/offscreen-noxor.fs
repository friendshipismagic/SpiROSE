in vec2 ex_UV;

layout(location = 0) out vec4 out_Color;

uniform sampler2D tex[N_DRAW_BUFFER];

void main() {
    // Modulus coordinates
    vec2 uv = mod(ex_UV * vec2(1.0, 4.0), 1.0);

    // BST like structure
    if (ex_UV.y < 0.25)
        out_Color = texture(tex[0], uv);
    else if (ex_UV.y < 0.5)
        out_Color = texture(tex[1], uv);
    else if (ex_UV.y < 0.75)
        out_Color = texture(tex[2], uv);
    else
        out_Color = texture(tex[3], uv);

    out_Color *= 20.0;
}
