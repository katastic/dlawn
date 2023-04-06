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
import planetsmod;
import bulletsmod;
import mapmod;
import molto;
import console;
import worldmod;

const int TILE_W = 32;
const int TILE_H = 32;
const int MAP_W = 256;
const int MAP_H = 256;

alias idx = size_t; /// alias for an index into an array. so int myTeamIndex; becomes idx myTeam; and it's obvious it's a lookup number.

immutable float PLANET_MASS = 4000;
immutable float PLANET_MASS_FOR_BULLETS = 20_000;

//ALLEGRO_CONFIG* 		cfg;  //whats this used for?
ALLEGRO_DISPLAY* 		al_display;
ALLEGRO_EVENT_QUEUE* 	queue;
ALLEGRO_TIMER* 			fps_timer;
ALLEGRO_TIMER* 			screencap_timer;

FONT* 	font1;

BITMAP* ship_bmp;
BITMAP* freighter_bmp;
BITMAP* smoke_bmp;
BITMAP* small_asteroid_bmp;
BITMAP* medium_asteroid_bmp;
BITMAP* large_asteroid_bmp;
BITMAP* space_bmp;
BITMAP* bullet_bmp;
BITMAP* dude_bmp;
BITMAP* trailer_bmp;
BITMAP* turret_bmp;
BITMAP* turret_base_bmp;
BITMAP* satellite_bmp;

BITMAP* chest_bmp;
BITMAP* chest_open_bmp;
BITMAP* dwarf_bmp;
BITMAP* goblin_bmp;
BITMAP* boss_bmp;
BITMAP* fountain_bmp;
BITMAP* tree_bmp;
BITMAP* wall_bmp;
BITMAP* grass_bmp;
BITMAP* lava_bmp;
BITMAP* water_bmp;
BITMAP* wood_bmp;
BITMAP* stone_bmp;
BITMAP* reinforced_wall_bmp;
BITMAP* sword_bmp;
BITMAP* carrot_bmp;
BITMAP* potion_bmp;
BITMAP* blood_bmp;

BITMAP* bmp_cow; // switching order for easier IDE searching. todo convert others other.
BITMAP* bmp_rain;

int SCREEN_W = 1360;
int SCREEN_H = 700;

intrinsicGraph!float testGraph;
intrinsicGraph!float testGraph2;

void loadResources()	
	{
	font1 = getFont("./data/DejaVuSans.ttf", 18);

	bullet_bmp  			= getBitmap("./data/bullet.png");
	ship_bmp			  	= getBitmap("./data/ship.png");
	freighter_bmp		  	= getBitmap("./data/freighter.png");
	small_asteroid_bmp  	= getBitmap("./data/small_asteroid.png");
	medium_asteroid_bmp  	= getBitmap("./data/medium_asteroid.png");
	large_asteroid_bmp  	= getBitmap("./data/large_asteroid.png");
	smoke_bmp  				= getBitmap("./data/smoke.png");
	space_bmp  				= getBitmap("./data/seamless_space.png");
	bullet_bmp  			= getBitmap("./data/bullet.png");
	dude_bmp	  			= getBitmap("./data/dude.png");
	trailer_bmp	  			= getBitmap("./data/trailer.png");
	turret_bmp	  			= getBitmap("./data/turret.png");
	turret_base_bmp			= getBitmap("./data/turret_base.png");
	satellite_bmp			= getBitmap("./data/satellite.png");
	
	sword_bmp  			= getBitmap("./data/sword.png");
	carrot_bmp  		= getBitmap("./data/carrot.png");
	potion_bmp  		= getBitmap("./data/potion.png");
	chest_bmp  			= getBitmap("./data/chest.png");
	chest_open_bmp  	= getBitmap("./data/chest_open.png");

	dwarf_bmp  		= getBitmap("./data/dwarf.png");
	goblin_bmp  	= getBitmap("./data/goblin.png");
	boss_bmp 	 	= getBitmap("./data/boss.png");

	wall_bmp  		= getBitmap("./data/wall.png");
	grass_bmp  		= getBitmap("./data/grass.png");
	lava_bmp  		= getBitmap("./data/lava.png");
	water_bmp  		= getBitmap("./data/water.png");
	fountain_bmp  	= getBitmap("./data/fountain.png");
	wood_bmp  		= getBitmap("./data/wood.png");
	stone_bmp  		= getBitmap("./data/brick.png");
	tree_bmp  		= getBitmap("./data/tree.png");
	blood_bmp  		= getBitmap("./data/blood.png");
	reinforced_wall_bmp  	= getBitmap("./data/reinforced_wall.png");	

	bmp_cow  	= getBitmap("./data/cow.png");	
	bmp_rain  	= getBitmap("./data/rain.png");	
	}

world_t world;
viewport[2] viewports;

// there may be an existing API for this
bool isAlmost(float val, float equals, float fudge=.01)
	{
	if( val > equals - fudge &&
		val < equals + fudge) return true; else return false;
	}

bool isZero(float val, float fudge=.01)
	{
	return isAlmost(val, 0, fudge);
	}

enum DIR { UP, DOWN, LEFT, RIGHT, UPLEFT, UPRIGHT, DOWNRIGHT, DOWNLEFT, NONE=0};

/// Draw a shield! ring
void drawShield(pair pos, viewport v, float radius, float thickness, COLOR c, float shieldCoefficent)
	{
	al_draw_circle(pos.x + v.x - v.ox, pos.y + v.y - v.oy, radius, COLOR(0,0,.5,.50), thickness*shieldCoefficent);	
	al_draw_circle(pos.x + v.x - v.ox, pos.y + v.y - v.oy, radius, COLOR(0,0,1,1), thickness*shieldCoefficent*.50);	
	}

void draw_hp_bar(float x, float y, viewport v, float hp, float max)
	{
	float _x = x;
	float _y = y - 10;
	float _hp = hp/max*20.0;

	if(hp != max)
		al_draw_filled_rectangle(
			_x - 20/2 + v.x - v.ox, 
			_y + v.y - v.oy, 
			_x + _hp/2  + v.x - v.ox, 
			_y + 5 + v.y - v.oy, 
			ALLEGRO_COLOR(1, 0, 0, 0.70));
	}

class player
	{
	idx myTeam;
	int money=1000; //we might have team based money accounts. doesn't matter yet.
	int kills=0;
	int aikills=0;
	int deaths=0;
	
	this()
		{
		}
		
	void onTick()
		{
		}
				
	}
	
class team
	{
	int money=0;
	int aikills=0;
	int kills=0;
	int deaths=0;
	COLOR color;
	
	this(player p, COLOR teamColor)
		{
		color = teamColor;
		}
	}
	
// this can generate an array but what about automatically adding ondraw and ontick functions?
// and what about the draw and/or logic order?
// we'd have to store this information in a list then have inside world->draw, we have a 
//
//	DrawSelected!TheList
//
// and in logic
//
//	TickSelected!TheList
//
// and finally:
//
//  PruneSelected!TheList
//
// we also need a STATISTICS variable setup but what if we haven't decided which STAT category each one is in?
// what if one is in BOTH or SOME or another combination etc? easist for that is simply... don't use templates for it.
//
// also, WHAT ARE WE GAINING for all this template muck? 5 lines here and 5 lines there? Doesn't seem worth it.
// I think it's just a "too see if I can do it" and learn more meta programming.

template GenList(T)	// test:   writes lawnMower[] lawnMowers;  etc
	{
    const char[] GenList = T.stringof ~"[] " ~ T.stringof ~"s;";
	pragma(msg, GenList);
	}

template GenList2(string T)	// using array of strings
	{
    const char[] GenList2 = T ~"[] " ~ T ~"s;";
	pragma(msg, GenList2);
	}
		
void worldmaker(U...)(U u)
	{
	mixin GenList!lawnMower;
	
//	pragma(msg, u);
		
	foreach(t; u)
		{
//		mixin
		}
	}
	
import std.meta;
alias listOfObjects = AliasSeq!(structure, unit);
immutable auto listOfObjects2 = ["structure", "unit"];
/+
void testWorldMaker()
	{
	static foreach(l; listOfObjects)
		{
		pragma(msg, l);
		mixin(GenList!(l));
		}

/+
	static foreach(l; listOfObjects2)
		{
		pragma(msg, l);
		mixin(GenList2!(l));
		}
+/
//	worldmaker("lawnMower");
	}
+/	

logger con;

struct statValue
	{
	int drawn=0;
	int clipped=0;
	}

struct statistics_t
	{ 
	// why not use an associated array? runtime add statistics and enumerate them?
	// but how do we draw them before they "exist" in the stats dialog? One way,
	// in the dialog, on read, we also go if(name is null)name = 0;
	// but also note we have paired statistics of normal vs clipped variables.
		
	// per frame statistics
	statValue numberUnits;
	statValue numberParticles;
	statValue numberStructures;
	statValue numberBullets;
	statValue numberDudes;
	
	ulong numberLogEntries=0;
	
	ulong fps=0;
	ulong framesPassed=0; // RESET every second. For FPS counter.
	ulong totalFramesPassed=0;
	StopWatch swGameStart;
	StopWatch swLogic;
	StopWatch swDraw;
	StopWatch swLogging;
	float msLogic;
	float nsDraw;
	float nsLogging; //needed?
	
	void reset()
		{ // note we do NOT reset fps and frames_passed here as they are cumulative or handled elsewhere.
		numberUnits = statValue.init;
		numberParticles = statValue.init;
		numberStructures = statValue.init;
		numberBullets = statValue.init;
		numberDudes = statValue.init;
		}
	}

statistics_t stats;

int mouse_x = 0; //cached, obviously. for helper routines.
int mouse_y = 0;
int mouse_lmb = 0;
int mouse_in_window = 0;
bool key_w_down = false;
bool key_s_down = false;
bool key_a_down = false;
bool key_d_down = false;
bool key_q_down = false;
bool key_e_down = false;
bool key_f_down = false;
bool key_space_down = false;

bool key_i_down = false;
bool key_j_down = false;
bool key_k_down = false;
bool key_l_down = false;
bool key_m_down = false;
