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

class world_t
	{	
	pixelMap map;
	tileMap map2;
	player[] players;
	team[] teams;
				
	dude[] objects; // other stuff
	unit[] units;
 	structure[] structures; // should all structures be owned by a planet? are there 'free floating' structures we'd have? an asteroid structure that's just a structure?
	particle[] particles;
	bullet[] bullets;
	meteor[] meteors;

//	rainWeatherHandler rain;

	this()
		{		
		con = new logger(); // WARN this should technically be initialized/owned outside world?
//		units = new unit;
		players ~= new player(); //CHICKEN OR EGG.
		players[0].myTeam = 0; // teams[0];

		map = new pixelMap(idimen(4096, 4096));
		map2 = new tileMap();
		
		objects ~= new dude(pair(750, 400));
		objects[0].isDebugging = true;
		objects ~= new cow(pair(900, 400));
		objects ~= new cow(pair(1200, 400));
		objects ~= new cow(pair(1400, 400));

		con.log("ello love 2302");

		//objects ~= new lawnMower(pair(800, 400));
		structures ~= new structure(700, 400, fountain_bmp);
		
		testGraph  = new intrinsicGraph!float("Draw (ms) ", g.stats.nsDraw , 100, 200, COLOR(1,0,0,1), 1_000_000);
		testGraph2 = new intrinsicGraph!float("Logic (ms)", g.stats.msLogic, 100, 320, COLOR(1,0,0,1), 1_000_000);
		
		import std.random : uniform;
		for(int i =0; i< 300;i++)meteors ~= new meteor(pair(uniform(0,map.data.w-1),uniform(0,map.data.h-1))); //test 
		
		viewports[0] = new viewport(0, 0, 1366, 768, 0, 0);
		assert(objects[0] !is null);
		viewports[0].attach(&objects[0]);
		setViewport2(viewports[0]);

		stats.swLogic = StopWatch(AutoStart.no);
		stats.swDraw = StopWatch(AutoStart.no);
		
		stats.swGameStart = StopWatch(AutoStart.yes);
		}

	void draw(viewport v)
		{
		stats.swDraw.start();

		void draw(T)(ref T obj)
			{
			foreach(ref o; obj)
				{
				o.draw(v);
				}
			}
		
		void drawStat(T, U)(ref T obj, ref U stat)
			{
			foreach(ref o; obj)
				{
				stat++;
				o.draw(v);
				}
			}

		void drawStat2(T, U)(ref T obj, ref U stat, ref U clippedStat)
			{
			foreach(ref o; obj)
				{
				if(o.draw(v))
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
				if(o.draw(v))
					{
					stat.drawn++;
					}else{
					stat.clipped++;
					}
				}
			}
			
//		map.onDraw(viewports[0]);
		map2.onDraw(viewports[0]);
		
		drawStat3(bullets	, stats.numberBullets);
		drawStat3(particles	, stats.numberParticles);
		drawStat3(units		, stats.numberUnits);
		drawStat3(objects	, stats.numberDudes);
		drawStat3(structures, stats.numberStructures);		
		drawStat3(meteors, stats.numberStructures);		

		map.drawMinimap(pair(SCREEN_W-300,50));

		testGraph.draw(v);
		testGraph2.draw(v);
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
/+
		if(key_space_down)players[0].currentShip.actionFire();
		if(key_q_down)players[0].findNextShip();
+/		
		auto p = objects[0];
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
			
		prune(units);
		prune(particles);
		prune(bullets);
		prune(objects);
		prune(meteors);
		
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
