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

struct rainWeatherHandler {
	void onTick() {
		for (int i = 0; i < 1; i++) { //note we can draw only around the screen +- some size. this could be a userland particle effect unless we want water to accumlate into tiles.
			float cx = g.world.objects[0].pos.x;
			float cy = g.world.objects[0].pos.y;
			float width = SCREEN_W / 2;
			float height = SCREEN_H / 2;
			particle p = particle(uniform(cx - width, cx + width), uniform(cy - height - 60, cy - height - 30), 1, 3, 0, 1000, bh["rain"]);
			p.doScaling = false;
			p.doDieOnHit = true;
			p.doFadeOverTime = true;
			g.world.particles ~= p;
			//			con.log("etstessteste");
		}
	}
}

struct particle {
	float x = 0, y = 0;
	float vx = 0, vy = 0;
	int type = 0;
	int lifetime = 0;
	int maxLifetime = 0;
	int rotation = 0;
	bool doScaling = false;

	bool doTinting = true;
	color tint;

	bool doFadeOverTime = true;

	bool isDead = false;
	bool doDieOnHit = false;
	bool flipHorizontal, flipVertical;
	bitmap* bmp;

	//particle(x, y, vx, vy, 0, 5);
	/// spawn smoke without additional unit u
	this(float _x, float _y, float _vx, float _vy, int _type, int _lifetime) {
		import std.math : cos, sin;

		stats.incAllocatedSinceReset("particles");
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

	this(float _x, float _y, float _vx, float _vy, int _type, int _lifetime, bitmap* _bmp) {
		import std.math : cos, sin;

		stats.incAllocatedSinceReset("particles");
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

	bool onDraw(viewport v) {
		assert(bmp !is null);
		BITMAP* b = bmp;
		ALLEGRO_COLOR c = color(1, 1, 1, 1);
		if (doFadeOverTime)
			c = color(1, 1, 1, cast(float) lifetime / cast(float) maxLifetime);
		float cx = x + v.x - v.ox;
		float cy = y + v.y - v.oy;
		float scaleX = (cast(float) lifetime / cast(float) maxLifetime) * b.w;
		float scaleY = (cast(float) lifetime / cast(float) maxLifetime) * b.h;
		if (!doScaling) {
			scaleX = 1;
			scaleY = 1;
		}
		if (!isInsideScreen(cx, cy, v)) {
			c = blue; // DEBUG. show partially clipped:
			return true; //if !debug
		}

		al_draw_tinted_scaled_rotated_bitmap(b, c,
			bmp.w / 2, bmp.h / 2,
			cx, cy,
			scaleX, scaleY,
			0, //angle
			flipHorizontal * ALLEGRO_FLIP_HORIZONTAL && flipVertical * ALLEGRO_FLIP_VERTICAL);

		return false;
	}

	void onTick() {
		if (!g.world.map2.isValidMovement(pair(x + vx, y + vy))) {
			vx = 0;
			vy = 0;
			if (doDieOnHit)
				isDead = true;
		}
		lifetime--;
		if (lifetime == 0) {
			isDead = true;
		} else {
			x += vx;
			y += vy;
		}
	}
}
