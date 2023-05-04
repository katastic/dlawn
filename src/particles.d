import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import g;
import molto;
import viewportsmod;
import objects;
import helper;
import console;

import std.stdio;
import std.math;
import std.random;

struct rainWeatherHandler
	{
	void onTick()
		{
		for(int i = 0; i < 1; i++)
			{
			particle p = particle(uniform(0, 1366), 0, 1, 3, 0, 1000, bh["rain"]);
			p.doScaling = false;
			p.doDieOnHit = true;
			p.doTinting = false;
			g.world.particles ~= p;
//			con.log("etstessteste");
			}
		}
	}

struct particle
	{
	float x=0, y=0;
	float vx=0, vy=0;
	int type=0;
	int lifetime=0;
	int maxLifetime=0;
	int rotation=0;
	bool doScaling=true;
	bool doTinting=true;
	bool isDead=false;
	bool doDieOnHit=false;
	bool flipHorizontal, flipVertical;
	bitmap* bmp;

	//particle(x, y, vx, vy, 0, 5);
	/// spawn smoke without additional unit u
	this(float _x, float _y, float _vx, float _vy, int _type, int  _lifetime)
		{
		import std.math : cos, sin;
		x = _x;
		y = _y;
		vx = _vx + uniform!"[]"(-.1, .1);
		vy = _vy + uniform!"[]"(-.1, .1);
		type = _type;
		lifetime = _lifetime;
		maxLifetime = _lifetime;
		rotation = uniform!"[]"(0, 3);
		bmp = g.bh["smoke"];
		assert(bmp !is null);
		flipHorizontal = flipCoin();
		flipVertical = flipCoin();
		}
	
	this(float _x, float _y, float _vx, float _vy, int _type, int  _lifetime, bitmap* _bmp)
		{
		import std.math : cos, sin;
		x = _x;
		y = _y;
		vx = _vx + uniform!"[]"(-.1, .1);
		vy = _vy + uniform!"[]"(-.1, .1);
		type = _type;
		lifetime = _lifetime;
		maxLifetime = _lifetime;
		rotation = uniform!"[]"(0, 3);
		bmp = _bmp;
		assert(bmp !is null);
		flipHorizontal = flipCoin();
		flipVertical = flipCoin();
		}
/+
	// do we need this? why do we also specify _vx, and _vy then???
	/// spawn smoke with acceleration from unit u
	this(float _x, float _y, float _vx, float _vy, int _type, int  _lifetime, unit u)
		{
		import std.math : cos, sin;
		float thrustAngle = u.angle;
		float thrustDistance = -30;
		float thrustVelocity = -3;
		
		x = _x + cos(thrustAngle)*thrustDistance;
		y = _y + sin(thrustAngle)*thrustDistance;
		vx = _vx + uniform!"[]"(-.1, .1) + cos(thrustAngle)*thrustVelocity;
		vy = _vy + uniform!"[]"(-.1, .1) + sin(thrustAngle)*thrustVelocity;
		type = _type;
		lifetime = _lifetime;
		maxLifetime = _lifetime;
		rotation = uniform!"[]"(0, 3);
		bmp = bh["smoke"];
		assert(bmp !is null);
		flipHorizontal = flipCoin();
		flipVertical = flipCoin();
		}
	+/	
	bool draw(viewport v)
		{
		assert(bmp !is null);
		BITMAP *b = bmp;
		ALLEGRO_COLOR c = color(1,1,1,1);
		if(doTinting)c = color(1,1,1,cast(float)lifetime/cast(float)maxLifetime);
		float cx = x + v.x - v.ox;
		float cy = y + v.y - v.oy;
		float scaleX = (cast(float)lifetime/cast(float)maxLifetime) * b.w;
		float scaleY = (cast(float)lifetime/cast(float)maxLifetime) * b.h;
		doScaling=false;
		if(!doScaling){scaleX = 1; scaleY = 1;}
		if(!isInsideScreen(cx, cy, v))
			{
			c = red; // DEBUG. show partially clipped:
			return true; //if !debug
			}
			
			al_draw_tinted_scaled_rotated_bitmap(b, c,
			   bmp.w/2, 
			   bmp.h/2, 
			   
			   cx, 
			   cy, 
			   
			   scaleX, 
			   scaleY,
			   0,  //angle
			   flipHorizontal & flipVertical);

/+				
			al_draw_tinted_scaled_bitmap2(b, c,
				0, 0, 
				b.w, b.h,
				cx - b.w/2, cy - b.h/2, 
				scaleX, scaleY, 
				rotation);+/
		//	return true;
			//}
		return false;
		}
	
	void onTick() 
		{
		if(!g.world.map2.isValidMovement(pair(x + vx, y + vy)))
			{
			vx=0;
			vy=0;
			if(doDieOnHit)isDead=true;
			}
		lifetime--;
		if(lifetime == 0)
			{
			isDead=true;
			}else{
			x += vx;
			y += vy;
			}
		}	
	}
	
