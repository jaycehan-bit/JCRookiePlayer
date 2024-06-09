#version 300 es
precision highp float;
layout (location = 0) in vec3 position;
layout (location = 1) in vec3 color;
layout (location = 2) in vec2 texcoord;

out vec2 v_texcoord;
out vec3 v_color;

void main()
{
    gl_Position = vec4(position, 1.0);
    v_texcoord = texcoord;
    v_color = color;
}

