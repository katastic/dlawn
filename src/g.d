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
import std.exception;

import helper;
import objects;
import viewportsmod;
import graph;
import particles;
import bulletsmod;
import mapmod;
import molto;
import console;
import worldmod;

const int TILE_W = 32;
//const int TILE_H = 32;
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

int SCREEN_W = 1360;
int SCREEN_H = 700;

intrinsicGraph!float testGraph;
intrinsicGraph!float testGraph2;

/// Bitmap handler
///=============================================================================
/+
	- do we want to merge/support bitmap atlas handler functionality? 
	- how do we want to handle multiple frame animations?
+/
class bitmapHandler 
	{
	bool usePrettyConsole=false; // We lose stdout/stderr ordering when we pipe to pretty printer. Not terrible, but different.
	
	// - ADD list of bools for each to track whether they were ever used for trimming unused assets
	// - we can also keep track of number of requests for a bitmap. Not sure of how that's useful information?
	// - 
	bitmap*[string] data;
//	alias data this;

	bitmap* opIndex(string key)
		{
		return *(key in data);
		}
	
	bitmap* get(string name)
		{
		bitmap** b;
		b = name in data;
		if(b is null)
			{
			// shouldn't we just dump to con.log and have the con.settings set it to STDOUT?
			if(usePrettyConsole)con.log(format("Attempting to get a bitmap [%s] that wasn't loaded!", name));
			else writefln("Attempting to get a bitmap [%s] that wasn't loaded!", name);
			assert(false);
			}
		return *b;
		}
	
	void loadJSON(string jsonpath="./data/manifest.json")
		{
		import std.json : JSONValue, parseJSON;
		import std.file : readText;
		string s = readText(jsonpath);
		JSONValue js = parseJSON(s);
		foreach(i, j; js["files"].array)
			{
//			writeln(i, " ", j, " ", j.type, " ", j[0], " ", j[1]);
			string name = j[0].str; 
			string path = j[1].str;
//			writefln("[%s]", name);
//			writefln("[%s]", path);
			load(name, path);
			}
		}
	
	void load(string name, string path) /// assert/exception guarded bitmap load
		{
		assert((name in data) is null, "Overwriting an existing bitmap detected! Duplicates in manifest? TODO. std.format errors.");
		data[name] = getBitmap(path);
		}
		
	void loadAA(immutable string[string] aa) /// associated array bulk load
		{
		// Do we want immutable? Can we still send a non-immutable to an immutable function? We just want to verify WE won't modify it.
		foreach(t; aa.byKeyValue)
			{
			string name = t.key;
			string path = t.value;
			load(name, path);
			}		
		}
		
	void loadTuple(T)(T[] tp) /// NOT TESTED. needed?
		{
		foreach(t; tp)
			{
			string name = t[0];
			string path = t[1];
			load(name, path);
			}
		}
		
	void list() /// List all active bitmaps
		{
		import std.array : byPair;
		foreach(b; data.byPair)writeln(b); //key and pair struct
		}

	void remove(string name)
		{
		al_destroy_bitmap(data[name]); 
		data.remove(name);
		}
	}

bitmapHandler bh;

// 'immutable' 
//  error associative arrays must be initialized at runtime: https://dlang.org/spec/hash-map.html#runtime_initialization
// https://dlang.org/spec/hash-map.html#runtime_initialization
/+immutable string[string] bhc;

shared static this() // we're setting (setting up) an IMMUTABLE string which is so confusing conceptually
	{
	// wait, doesn't this also blow away any possibility of COMPILE-TIME type-safe lookup here???
	// I mean, I guess it's not the end of the world, any BITMAP INVOCATION is going to be WAY EXPENSIVE to draw
	// than a single hash lookup, right? But at this point, why don't we just scrap this and move to RUN-TIME PARSING
	// a JSON object.
	
	bhc = [ 
		  "cow": "./data/cow.png",
		  "rain": "./data/rain.png",
		  "explosion": "./data/explosion.png",
		  "sand": "./data/wall2.png",
		  "asteroid": "./data/asteroid2.png"
		];
	}
+/
void loadResources()
	{
	bh = new bitmapHandler();
	bh.loadJSON();
	font1 = getFont("./data/DejaVuSans.ttf", 18);
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

void drawHealthBar(float x, float y, viewport v, float hp, float max)
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
	statValue[string] data;

	statValue* opIndex(string key)
		{
//		writeln("opIndex(string key)");
//		writeln("  ", key);
		auto p = (key in data);
//		writeln("  P:", p);
		if(p is null)data[key] = statValue(0,0);
		auto p2 = (key in data);
//		writeln("  P:", *p2);
//		writeln("  data[key]: ", data[key]);
		return p2;
		}
		
	void inc(string key) /// increment
		{
//		writeln("test1 - inc(string key)");
		statValue* p = opIndex(key);
//		writeln("test2");
		(*p).drawn += 1;
//		writeln("test3");
//		writeln(key, " is now: ", (*p).drawn);
		}
		
	void incClipped(string key) /// increment
		{
		statValue* p = opIndex(key);
		(*p).clipped += 1;
		}
		
	void list() /// list all keys
		{
		writeln("list of stats keys");
		foreach(name, k; data)
			{
			writeln(" - ", name, " ", k);
			}
		}

	ulong numberLogEntries=0;
	
	ulong fps=0;
	ulong framesPassed=0; // RESET every second. For FPS counter.
	ulong totalFramesPassed=0;
	StopWatch swGameStart;
	StopWatch swLogic;
	StopWatch swDraw;
	StopWatch swLogging;
	float msLogic=0;
	float nsDraw=0;
	float nsLogging=0; //needed?
	
	void reset() // reset counters
		{ // note we do NOT reset fps and frames_passed here as they are cumulative or handled elsewhere.

		foreach(key, val; data) //TEST foreach isn't supposed to modify collections?
			{
			data[key] = statValue(0,0);
			}
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
