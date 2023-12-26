#ifdef GL_ES
precision mediump float;
#endif
uniform sampler2D al_tex;
uniform float timeIndex;
uniform vec4 al_pos;		// not working? = 0
//uniform vec2 screenPos; // mine. start of render. But what about start position + texture position?
uniform vec3 tint;		// mine
//in vec4 gl_FragCoord https://registry.khronos.org/OpenGL-Refpages/gl4/html/gl_FragCoord.xhtml
varying vec4 varying_color;
varying vec2 varying_texcoord;

void main()
	{
	vec4 tmp = varying_color * texture2D(al_tex, varying_texcoord);
	tmp.r *= tint.r;
	tmp.g *= tint.g;
	tmp.b *= tint.b;

	if(gl_FragCoord.x == 10.0) 
		{
		tmp.r *= 0.0;
		tmp.g *= 0.0;
		tmp.b *= 0.0;
		}

	gl_FragColor = tmp;
	}
