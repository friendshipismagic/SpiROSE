in vec2 ex_UV;

out vec4 out_Color;

uniform sampler2D tex;

void main() { out_Color = texture(tex, ex_UV); }
