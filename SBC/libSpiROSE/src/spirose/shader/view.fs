/**
 * View algorithm, fragment shader.
 * Role: output a color.
 */

layout(location = 0) out vec4 out_Color;

uniform vec4 in_Color;

void main() { out_Color = in_Color; }
