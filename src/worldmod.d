/+
	note we can have multiple "worlds" for different scenes, levels, etc
	and stream them in as needed. We will at some point need to be able to
	transfer objects from one to another for scene changes.
+/
import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import std.stdio;
import std.math;
import std.conv;
import std.string;
import std.random;
import std.algorithm : remove;
import std.datetime;
import std.datetime.stopwatch : benchmark, StopWatch, AutoStart;

import helper;
import objects;
import viewportsmod;
import graph;
import particles;
import bulletsmod;
import mapmod;
import molto;
import console;
import g;
import main : shader;

import datajack; // gamemodule
import gui;

class world_t {
	gridWindow grids;

	//	pixelMap map;
	tileMap map2;
	//	isometricFlatMap map3d;
	objectHandler oh;
	player[] players;
	team[] teams;

	import main : memoryPool;

	static if (true) {
		memoryPool!BaseObject objects; // other stuff
		memoryPool!particle particles;
	} else {
		BaseObject[] objects; // other stuff TODO
		particle[] particles;
	}
	unit[] units;
	item[] items;
	structure[] structures; // should all structures be owned by a planet? are there 'free floating' structures we'd have? an asteroid structure that's just a structure?
	Bullet[] bullets;
	//	meteor[] meteors;
	rainWeatherHandler rain;

	this() {
		//		grid = new dragAndDropGrid;
		grids = new gridWindow(pair(550, 150));

		players ~= new player(); //CHICKEN OR EGG.
		players[0].myTeam = 0; // teams[0];

		//		map = new pixelMap(idimen(4096, 4096));
		map2 = new tileMap();
		//map3d = new isometricFlatMap();

		oh = new objectHandler("./data/maps/objectmap.toml"); //NYI

		import datajack, aimod;

		// UNITS
		// -------------------------------------------------------
		{
			auto u = cast(unit) new runner(pair(730, 420)); // what is this for?
			u.isDebugging = true;
			units ~= u;
		}

		// OBJECTS
		// -------------------------------------------------------
		{
			auto t = new dude(pair(740, 420));
			t.isDebugging = true;
			objects ~= t;
		}
		{
			auto t = new cow(pair(750, 420));
			objects ~= t;
		}
		{
			auto t = new dude(pair(740, 420));
			t.usingAI = true;
			objects ~= t;
		}
		{
			auto t = new dude(pair(780, 320));
			t.usingAI = true;
			objects ~= t;
		}

		for (int i = 0; i < 1500; i++) {
			auto t = new bigMeteor(pair(uniform(1, 1000), uniform(1, 100)));
			objects ~= t;
		}
		for (int i = 0; i < 10; i++) {
			auto t = new blimp(pair(uniform(1, 1000), uniform(200, 300)));
			objects ~= t;
		}
		for (int i = 0; i < 2; i++) {
			auto u = cast(unit) new bug(pair(uniform(1, 1000), uniform(1, 1000)));
			units ~= u;
		}

		con.log("hello love 2023");

		//structures ~= new structure(700, 400, bh["fountain"]);

		graphs ~= new intrinsicGraph!float("Draw (ms) ", g.stats.nsDraw, 100, 150, COLOR(1, 0, 0, 1), 1_000_000);
		graphs ~= new intrinsicGraph!float("Logic (ms)", g.stats.nsLogic, 100, 260, COLOR(1, 0, 0, 1), 1_000_000);
		graphs ~= new intrinsicGraph!float("Allocations", g.stats["objects"].allocationsPerSecond, 100, 370, COLOR(1, 0, 0, 1), 1);

		viewports[0] = new viewport(0, 0, g.SCREEN_W, g.SCREEN_H, 0, 0);
		assert(units[0]!is null);
		assert(objects[0]!is null);
		viewports[0].attach(&objects[0]);
		setViewport2(viewports[0]);

		stats.swLogic = StopWatch(AutoStart.no);
		stats.swDraw = StopWatch(AutoStart.no);

		stats.swGameStart = StopWatch(AutoStart.yes);
	}

	void onDraw(viewport v) {
		stats.swDraw.start();

		void drawStat3(T, U)(ref T obj, ref U stat) {
			foreach (ref o; obj) {
				if (o.onDraw(v)) {
					stat.drawn++;
				} else {
					stat.clipped++;
				}
			}
		}

		void drawStat4(T)(ref T obj, string name) {
			al_hold_bitmap_drawing(true);
			foreach (ref o; obj) {
				if (o.onDraw(v)) {
					stats[name].drawn++;
				} else {
					stats[name].clipped++;
				}
			}
			al_hold_bitmap_drawing(false);
		}

		import main : timeIndex;

		//		map.onDraw(viewports[0]);
		timeIndex += 4;
		if (timeIndex > 256)
			timeIndex = 0;
		al_use_shader(shader);

		void setShaderFloat(const char* name, float value) {
			assert(al_set_shader_float(name, value) == 0);
		}

		al_set_shader_float("timeIndex", timeIndex);
		map2.onDraw(viewports[0]);
		al_use_shader(null);
		//map3d.onDraw(viewports[0]);

		drawStat4(bullets, "bullets");
		drawStat4(particles, "particles");
		drawStat4(units, "units");
		drawStat4(objects, "objects");
		drawStat4(structures, "structures");
		drawStat4(items, "items");

		//		map.drawMinimap(pair(SCREEN_W-300,50));

		grids.onDraw(v);

		foreach (g; graphs)
			g.onDraw(v);
		stats.swDraw.stop();
		stats.nsDraw = stats.swDraw.peek.total!"nsecs";
		stats.swDraw.reset();
	}

	int timer = 0;
	void logic() {
		stats.swLogic.start();
		foreach (g; graphs)
			g.onTick();

		viewports[0].onTick();
		players[0].onTick();

		timer++;
		if (timer > 200) {
		}

		auto p = objects[0];

		// Note these are LEVEL triggers, not EDGE triggers! They will continue to fire as long as the key is down.
		if (key_w_down)
			p.actionUp();
		if (key_s_down)
			p.actionDown();
		if (key_a_down)
			p.actionLeft();
		if (key_d_down)
			p.actionRight();

		if (key_m_down) {
			import aimod;

			for (int i = 1; i < units.length; i++) {
				message m;
				m.isSoundEvent = true;
				m.pos = pair(viewports[0].ox + mouse_x, viewports[0].oy + mouse_y);
				units[i].ai.messages ~= m;
			}
		}
		/+
		if(key_i_down)viewports[0].oy += 2;
		if(key_k_down)viewports[0].oy -= 2;
		if(key_j_down)viewports[0].ox -= 2;
		if(key_l_down)viewports[0].ox += 2;
+/
		rain.onTick();
		tick(particles);
		tick(bullets);
		tick(units);
		tick(objects);
		tick(items);
		th.onTick();

		prune(units);
		prune(particles);
		prune(bullets);
		prune(objects);
		prune(items);

		stats.swLogic.stop();
		stats.nsLogic = stats.swLogic.peek.total!"nsecs";
		stats.swLogic.reset();
	}

	void tick(T)(ref T obj) {
		foreach (ref o; obj) {
			o.onTick();
		}
	}

	//prune ready-to-delete entries (copied from g)
	void prune(T)(ref T obj) {
		import std.algorithm : remove;

		for (size_t i = obj.length; i-- > 0;) {
			if (obj[i].isDead)
				obj = obj.remove(i);
			continue;
		}
		//see https://forum.dlang.org/post/sagacsjdtwzankyvclxn@forum.dlang.org
	}
}

/+ dlawn/asteroid version
class world_t
	{	
//	pixelMap map;
	tileMap map2;
	isometricFlatMap map3d;
	objectHandler oh;
	player[] players;
	team[] teams;
				
	dude[] objects; // other stuff
	unit[] units;
	item[] items;
 	structure[] structures; // should all structures be owned by a planet? are there 'free floating' structures we'd have? an asteroid structure that's just a structure?
	particle[] particles;
	bullet[] bullets;
	meteor[] meteors;

//	rainWeatherHandler rain;

	this()
		{		
		players ~= new player(); //CHICKEN OR EGG.
		players[0].myTeam = 0; // teams[0];

//		map = new pixelMap(idimen(4096, 4096));
		map2 = new tileMap();
		map3d = new isometricFlatMap();
		
		oh = new objectHandler("./data/maps/objectmap.toml");
		
		objects ~= new dude(pair(750, 400));
		objects[0].isDebugging = true;
		objects[0].testCreateItems(this);
		objects ~= new dude(pair(850, 400));
		objects[1].usingAI = true;
		
		objects ~= new cow(pair(900, 400));
		objects ~= new cow(pair(1200, 400));
		objects ~= new cow(pair(1400, 400));

		con.log("'ello love 2023");

		structures ~= new structure(700, 400, bh["fountain"]);
		
		testGraph  = new intrinsicGraph!float("Draw (ms) ", g.stats.nsDraw , 100, 200, COLOR(1,0,0,1), 1_000_000);
		testGraph2 = new intrinsicGraph!float("Logic (ms)", g.stats.msLogic, 100, 320, COLOR(1,0,0,1), 1_000_000);
		
		import std.random : uniform;
		for(int i =0; i< 100;i++)
			{
			if(percent(90))
				meteors ~= new meteor   (pair(uniform(0,map2.w*TILE_W-1),uniform(0,map2.h*TILE_W-1))); //test 
			else
				meteors ~= new bigMeteor(pair(uniform(0,map2.w*TILE_W-1),uniform(0,map2.h*TILE_W-1))); //test 
				
			}		
		viewports[0] = new viewport(0, 0, 1366, 768, 0, 0);
		assert(objects[0] !is null);
		viewports[0].attach(&objects[0]);
		setViewport2(viewports[0]);

		stats.swLogic = StopWatch(AutoStart.no);
		stats.swDraw = StopWatch(AutoStart.no);
		
		stats.swGameStart = StopWatch(AutoStart.yes);
		}

	void onDraw(viewport v)
		{
		stats.swDraw.start();

		void onDraw(T)(ref T obj)
			{
			foreach(ref o; obj)
				{
				o.onDraw(v);
				}
			}
		
		void drawStat(T, U)(ref T obj, ref U stat)
			{
			foreach(ref o; obj)
				{
				stat++;
				o.onDraw(v);
				}
			}

		void drawStat2(T, U)(ref T obj, ref U stat, ref U clippedStat)
			{
			foreach(ref o; obj)
				{
				if(o.onDraw(v))
					{
					stat++;
					}else{
					clippedStat++;
					}
				}
			}
			
		void drawStat3(T, U)(ref T obj, ref U stat)
			{
			foreach(ref o; obj)
				{
				if(o.onDraw(v))
					{
					stat.drawn++;
					}else{
					stat.clipped++;
					}
				}
			}

		void drawStat4(T)(ref T obj, string name)
			{
			al_hold_bitmap_drawing(true);
			foreach(ref o; obj)
				{
				if(o.onDraw(v))
					{
					stats[name].drawn++;
					}else{
					stats[name].clipped++;
					}
				}
			al_hold_bitmap_drawing(false);
			}
		import main:timeIndex;
//		map.onDraw(viewports[0]);
		timeIndex++;
		if(timeIndex > 256)timeIndex = 0;
		al_use_shader(shader);
		al_set_shader_float("timeIndex", timeIndex);
			map2.onDraw(viewports[0]);
		al_use_shader(null);
		map3d.onDraw(viewports[0]);

		drawStat4(bullets	, "bullets");
		drawStat4(particles	, "particles");
		drawStat4(units		, "units");
		drawStat4(objects	, "objects");
		drawStat4(structures, "structures");
		drawStat4(meteors	, "meteors");		
		drawStat4(items		, "items");		

//		map.drawMinimap(pair(SCREEN_W-300,50));

		testGraph.onDraw(v);
		testGraph2.onDraw(v);
		stats.swDraw.stop();
		stats.nsDraw = stats.swDraw.peek.total!"nsecs";
		stats.swDraw.reset();
		}
		
	int timer=0;
	void logic()
		{
		stats.swLogic.start();
		assert(testGraph !is null);
		testGraph.onTick();
		testGraph2.onTick();
		
		viewports[0].onTick();
		players[0].onTick();
		
		timer++;
		if(timer > 200)
			{
			}

		auto p = objects[0];
		
		// Note these are LEVEL triggers, not EDGE triggers! They will continue to fire as long as the key is down.
		if(key_w_down)p.actionUp();
		if(key_s_down)p.actionDown();
		if(key_a_down)p.actionLeft();
		if(key_d_down)p.actionRight();
		
/+
		if(key_i_down)viewports[0].oy += 2;
		if(key_k_down)viewports[0].oy -= 2;
		if(key_j_down)viewports[0].ox -= 2;
		if(key_l_down)viewports[0].ox += 2;
+/
		// rain.onTick();
		tick(particles);
		tick(bullets);
		tick(units);
		tick(objects);
		tick(meteors);
		tick(items);
		th.onTick();
			
		prune(units);
		prune(particles);
		prune(bullets);
		prune(objects);
		prune(meteors);
		prune(items);
		
		stats.swLogic.stop();
		stats.msLogic = stats.swLogic.peek.total!"msecs";
		stats.swLogic.reset();
		}
		
	void tick(T)(ref T obj)
		{
		foreach(ref o; obj)
			{
			o.onTick();
			}
		}

	//prune ready-to-delete entries (copied from g)
	void prune(T)(ref T obj)
		{
		import std.algorithm : remove;
		for(size_t i = obj.length ; i-- > 0 ; )
			{
			if(obj[i].isDead)obj = obj.remove(i); continue;
			}
		//see https://forum.dlang.org/post/sagacsjdtwzankyvclxn@forum.dlang.org
		}
	}
+/
