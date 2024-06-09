#version 300 es
precision highp float;
out vec4 fragColor;
in vec2 v_texcoord;
in vec3 v_color;

uniform sampler2D texture_Y;
uniform sampler2D texture_U;
uniform sampler2D texture_V;

void main()
{
    highp float y = texture(texture_Y, v_texcoord).r;
    highp float u = texture(texture_U, v_texcoord).r - 0.5;
    highp float v = texture(texture_V, v_texcoord).r - 0.5;
    highp float r = y + 1.402 * v;
    highp float g = y - 0.344 * u - 0.714 * v;
    highp float b = y + 1.772 * u;
    fragColor = vec4(r, g, b, 1.0);
}
