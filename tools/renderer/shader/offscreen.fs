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
		// Modulus coordinates
		vec2 uv = mod(ex_UV * vec2(4, 2), vec2(4, 2)) / vec2(4, 2);

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
		}
		else {
			if (ex_UV.x < 0.25)
				out_Color = texture(tex4, uv);
			else if (ex_UV.x < 0.5)
				out_Color = texture(tex5, uv);
			else if (ex_UV.x < 0.75)
				out_Color = texture(tex6, uv);
			else
				out_Color = texture(tex7, uv);
		}
    }
}
