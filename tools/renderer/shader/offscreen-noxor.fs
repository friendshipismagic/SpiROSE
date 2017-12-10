in vec2 ex_UV;

layout(location = 0) out vec4 out_Color;

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;

void main() {
    // Modulus coordinates
    vec2 uv = mod(ex_UV * vec2(4.0, 2.0), 1.0);

    // BST like structure
    if (ex_UV.y < 0.5) {
        if (ex_UV.x < 0.25)
            out_Color = texture(tex0, uv);
        else if (ex_UV.x < 0.5)
            out_Color = texture(tex1, uv);
        else if (ex_UV.x < 0.75)
            out_Color = texture(tex2, uv);
        else
            out_Color = texture(tex3, uv);
    } else {
        if (ex_UV.x < 0.25)
            out_Color = texture(tex4, uv);
        else if (ex_UV.x < 0.5)
            out_Color = texture(tex5, uv);
        else if (ex_UV.x < 0.75)
            out_Color = texture(tex6, uv);
        else
            out_Color = texture(tex7, uv);
    }

    out_Color *= 20.0;
}
