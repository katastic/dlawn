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
import atlasmod;

const int TILE_W = 32;
const int TILE_H = 32; // beware some stuff assumed TILE_W=TILE_H so they just used TILE_W everywhere.
const int MAP_W = 256;
const int MAP_H = 256;

alias idx = size_t; /// alias for an index into an array. so int myTeamIndex; becomes idx myTeam; and it's obvious it's a lookup number.

/**
	cachedAA

	First time accessed, it passes through the const char to the AA. Then it caches the resulting pointer

	issues
		- we're no longer using the AA. But we are still using the const char (hopefully! not a string!)
		value. Though that's a pointer to the static segment, right? So it's just a 64-bit value passed, yielding a new 64-bit value.
		
		- pure performance: we do have an if, however, 99.999% of CPUs are going to notice the branch is always taken (after the
		 inital value settles) so that should become a nop
		 
		 - how do we link it to a specific AA? constructor? Then we can't one-liner it right?
		 - can we use as struct so we don't have to allocate? Also how does a class
			automatically store cached values?! 
		- what if we need to lookup multiple values?
		- maybe this would be better built into the atlas/object/etc handler itself? (using a re-usable template for all three)
			so that the handler itself stores a list of cache 
		- i mean, why not just store the value yourself in the using function? We have to initalize it. WE have to store it. We have to NEVER accidentally call it with two different values. (Calling it once with a new string once cached will implicity with NO ERROR only give you the first one!)
*/
alias cstr = const char *;

// how do we detect the same one quickly without basically re-implementing a hashmap?
// we keep track of which ones we have recieved, and then use a pointer to the value. But...
// It feels like that's just... a hashmap to a hashmap value. But isn't there SOME kind of context
// clue? What if, at COMPILE TIME, we marked all accesses? But that might be WAY too complex for D.
// we basically grepping for any atlasHandler[""] accesses, finding the unique ones, and assigning an index.
// then we put them all next to each other and use an array[indexOffset] to access them so that the
// COMPILED CODE is just like, an enum access.

/+
like 

enum AtlasHandlerValues
	{
	"red":1,
	"grass":2,
	"goblin":3
	}

but the code sees "red" etc and replaces it

	myArray["goblin"] 
		becomes
	myArray[3]




what if we do something cheeky. for any cached value we can of course, just 
store the cached value in our object/class/whatever. So, can we have 
template mixin magic automatically add the fields to the struct?

struct
	{
	void test()
		{
		cached!int temp["salgkdndkslagna"];
		}
	}

becomes:

struct
	{
	cached!int temp;
	void test()
		{
		cached!int temp["salgkdndkslagna"];
		}
	}
	
is there any way we can just have like a singular

cachedHandler inside our objects? But then again, it needs to redirect to the right one.

What is the easiest way to do this with compile time introspection?

+/

class cachedHandler(T) 
	{
	T[] indexedArray;
	T[cstr] myAA;
	
	int nextUnusedIndex()
		{
		
		}
	
	
	}

class cachedAA(T) 
	{
	bool isCached=false;
	T cachedValue;
	T[cstr] myAA;
	//https://dlang.org/library/object/op_equals.html
	
	this(T[cstr] AA)
		{
		myAA = AA;
		}
	
	T get(cstr key)	// could override square bracket AA notation using opequals/whatever
		{
		// todo range checking
		if(isCached)
			{
			writeln("using cached");
			return cachedValue;
			}
		isCached = true;
		cachedValue = myAA[key];
		return cachedValue;
		}
	}
	
void testCachedAA()
	{
	int[cstr] myAA;
	myAA["taco"] = 1;
	
	auto c = new cachedAA!int(myAA);
	writeln("---");
	writeln(c.get("taco"));
	writeln("---");
	writeln(c.get("taco"));
	writeln("---");
	myAA["taco"] = 1212;
	writeln(c.get("taco"));
	}


//ALLEGRO_CONFIG* 		cfg;  //whats this used for?
ALLEGRO_DISPLAY* 		al_display;
ALLEGRO_EVENT_QUEUE* 	queue;
ALLEGRO_TIMER* 			fps_timer;
ALLEGRO_TIMER* 			screencap_timer;

FONT* 	font1;

int SCREEN_W = 1360;
int SCREEN_H = 700;
enum DIR { UP, DOWN, LEFT, RIGHT, UPLEFT, UPRIGHT, DOWNRIGHT, DOWNLEFT, NONE=0};

intrinsicGraph!float testGraph;
intrinsicGraph!float testGraph2;

bitmapHandler bh;
atlasHandler ah;
atlasHandler2 ah2;

world_t world;
viewport[2] viewports;

void loadResources()
	{
	font1 = getFont("./data/DejaVuSans.ttf", 18);

	bh = new bitmapHandler();
	ah = new atlasHandler();
	ah2 = new atlasHandler2("./data/atlasManifest.json");
	bh.loadJSON();
	ah.load();
	ah.loadMeta();
	}
	
void unloadResources()
	{
	ah2.unload();
	}

/// need some sort of timing mechanism/server so we can do stuff like timeouts for throwing an item and picking it back up again.
/// auto myTimeout = new timeout();

/+ myTimeout.setSeconds(5);
if(myTimeout) //returns false until its ready
 {
 }

all timeouts are handled by a handler that has a list of them and handled as they become available.

+/

// do we combine event and LEVEL trigger timers together in here? Or separate structs and arrays?
struct timeout
	{
	static timeoutHandler handler; 
	int totalLength=0; // in frames? in milliseconds? Frames makes upkeep simple.
	int remaining=0;
	bool isReady=false;
	
	alias isReady this;
	
	this(int frames) // how do we select frames or seconds
		{
		totalLength = frames;
		remaining = frames;
		handler.add(this);
		}
	
	static this()
		{
		handler = th;
		}
		
	void delegate () callbackFunction;
	} // there is ONE issue, if we NEED a CLOCK TIME, and 
	// the GAME LOGIC RATES stutter for some reason then the CLOCK times will be delayed.
	// if we NEED clock times to be exact, we need a framerate agnostic method (ala Allegro timers)
	
	
// -- ISSUE: How do we handle/clean a dead timeout? 
// If it's an EVENT timer we fire the event.
// but what if it's a level timer? How do we know we're done with it? 
// If we manually clean them up from the object using them, we better find a way to determine if they're ORPHANS due to OPT-IN resource allocation!
struct timeoutHandler
	{
	timeout[] myLevelChildren; // these have to be dealt with. AND, can they be reset?
	timeout[] myEventChildren; // these clean up instantly.
	
	void add(timeout t)
		{
		myLevelChildren ~= t;
		}
		
	timeout* addLevelTimeout(float time) //constructs timeout and returns pointer to it
		{
		timeout t;
		myLevelChildren ~= t;
		return &myLevelChildren[$-1];
		}

	timeout* addEdgeTimeout(int time, void delegate() _callbackFunction) //constructs timeout and returns pointer to it
		{
		timeout t;
		t.remaining = time;
		t.isReady = false;
		t.callbackFunction = _callbackFunction;
		myEventChildren ~= t;
		return &myEventChildren[$-1];
		}
	
	void onTick()
		{
		foreach(t; myLevelChildren)
			{
			if(!t.isReady)
				{
				t.remaining--;
				if(t.remaining < 0)t.isReady = true; // if(t.pushEvent !is null)t.pushEvent();
				}
			}
		
		foreach(i, t; myEventChildren)
			{
			if(!t.isReady)
				{
//				writeln(t.remaining);
				myEventChildren[i].remaining--; //can't mutate t inside foreach
				if(t.remaining < 0)
					{
					myEventChildren[i].isReady = true;
					myEventChildren[i].callbackFunction();
					con.log("Calling callback function");
					}
				}
			}
		}
	// we could support 'push' notifications as opposed to polling here. do we need it though?
	
	}

timeoutHandler th; // if we don't have this singleton we can't use 
// static this binding for children for auto registration.

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
