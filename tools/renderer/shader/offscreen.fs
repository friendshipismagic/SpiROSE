#version 330 core

in vec2 ex_UV;

out vec4 out_Color;

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;

uniform bool useXor;

void main() {
    if (useXor)
        out_Color = texture(tex0, ex_UV);
    else {
        if (ex_UV.y < 0.5)
            out_Color = texture(tex0, ex_UV / vec2(1, 2));
        else
            out_Color = texture(tex0, ex_UV / vec2(1, 2) + vec2(0, 0.5));
    }
}
