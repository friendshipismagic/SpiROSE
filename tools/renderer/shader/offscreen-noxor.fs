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
uniform sampler2D tex8;
uniform sampler2D tex9;
uniform sampler2D tex10;
uniform sampler2D tex11;
uniform sampler2D tex12;
uniform sampler2D tex13;
uniform sampler2D tex14;
uniform sampler2D tex15;

void main() {
    // Modulus coordinates
    vec2 uv = mod(ex_UV * vec2(1.0, 4.0), 1.0);

    // BST like structure
    if (ex_UV.y < 0.25)
        out_Color = texture(tex0, uv);
    else if (ex_UV.y < 0.5)
        out_Color = texture(tex1, uv);
    else if (ex_UV.y < 0.75)
        out_Color = texture(tex2, uv);
    else
        out_Color = texture(tex3, uv);

    out_Color *= 20.0;
}
