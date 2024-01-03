#version 150 // for gl_FragCoord
#ifdef GL_ES
precision mediump float;
#endif
uniform sampler2D al_tex;
uniform float timeIndex;
uniform vec4 al_pos;		// not working? = 0
//uniform vec2 screenPos; // mine. start of render. But what about start position + texture position?
uniform vec3 tint;		// mine
in vec4 gl_FragCoord; // https://registry.khronos.org/OpenGL-Refpages/gl4/html/gl_FragCoord.xhtml
varying vec4 varying_color;
varying vec2 varying_texcoord; // this is the ENTIRE texture not the subbitmap?!

void main()
	{
	vec4 tmp = varying_color * texture2D(al_tex, varying_texcoord);
	tmp.r *= tint.r;
	tmp.g *= tint.g;
	tmp.b *= tint.b;

//	if(gl_FragCoord.x == 10.0) 
//	if(mod(al_pos.x,8.0) == 0.0) 
			//mod(timeIndex,2.0)
	
//	if(mod(gl_FragCoord.x, 32.0) < 1)
	if(any(greaterThan(tmp.rgb, vec3(.9))))
		{
		tmp.r = tmp.r + sin(timeIndex/256.0*2.0*3.1415926);
		tmp.g = tmp.g + sin(timeIndex/256.0*2.0*3.1415926);
		tmp.b = tmp.b + sin(timeIndex/256.0*2.0*3.1415926);
		}

	gl_FragColor = tmp;
	}
