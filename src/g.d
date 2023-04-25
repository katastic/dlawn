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
import std.json : JSONValue, parseJSON, JSONException;
import std.file : readText;

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

/// this one builds an array/atlas from an [atlasManifest.json] manifest
/// and picks and chooses what bitmaps from anywhere (doesn't HAVE to be from one file or place)

/// ---> Do we need to specify w and h values if they're TILEs? Maybe for a different version
// ---> SCHEMA we could also specify all lookups BY FILE for each column.
//  "bitmap.png":[[0, 0], [32, 0], [32, 32]]
// should this also be including STATS??? If so, do we want all entries organized by bitmap file?

struct fileScanEntry
	{
	string tilename;
	int x, y;
	bool isPassable;
	bool reserved;
	}

// another problem. what are we using for an TILE INDEX?
// otherwise, we cannot TRANSFORM tiles easily if they're all hash lookups
// also that may be slower.
class atlasHandler2 
	{
	fileScanEntry[][string] filesData;
	bitmap*[string] sources; // if we load a source / parent bitmap we have to clean it up later! 
		
	irect[] sourcesMeta;
	bitmap*[string] bmps;
	tileInfo[string] info;
	bool hasLoadedMetaYet=false;

	void loadMeta(string filepath="./data/atlasManifest.json")
		{
		string[] listOfUsedNames;
		
		con.log("Loading atlasMetadata at ["~filepath~"]");
		string s = readText(filepath);
		JSONValue js;
		try{
		js = parseJSON(s);
		}catch(JSONException e){
		writeln(e.toString());
		assert("fuck");
		}
	
		foreach(z, q; js.object)
			{
			writeln("z:", z, " q:", q);
			string filename = z;
			foreach(i, j; q.array)
				{
			writeln("	i:", i, " j:", j);
				foreach(l, m; j.object)
					{
					string tilename = l;
					writeln("tilename: ", tilename);
					writeln("		object l:[", l, "] m:", m);
					foreach(n, o; m.array)
						{
						writeln("			val n:", n, " o:", o);
						size_t idx = n;
						}
					int valx = cast(int)m[0].integer;
					int valy = cast(int)m[1].integer;
					bool valisPassable = cast(bool)m[2].integer;
					bool valreserved   = cast(bool)m[3].integer;
					writeln("x: ", valx);
					writeln("y: ", valy);
					writeln("isPassable: ", valisPassable);	
					
					fileScanEntry f;
						f.tilename = tilename;
						f.x = valx;
						f.y = valy;
						f.isPassable = valisPassable;
						f.reserved = valreserved;
					
					filesData[filename] ~= f;
					writeln(filename, "=",f);
					}
/+				writeln(i, " ", j, " ", j.type, " ", j[0], " ", j[1], " ", j[2], " ", j[3]);
				irect r;
				long 	index = j[0].integer;
				r.x = cast(int)j[0].integer;
				r.y = cast(int)j[1].integer;
				r.w = cast(int)j[2].integer;
				r.h = cast(int)j[3].integer; +/
	//			writefln("[%s]", path);
				
				}
			}
		foreach(i, sz; filesData)
			{
			writeln(i, " = ");
			foreach(j, k; sz)
				{
				writeln("	",j, ",", k);
				}
			}
		hasLoadedMetaYet = true;
		}
	
	// TODO: alternative atlas formats.support variable widths.
	//  squareAtlases (below). Rectangle atlases. Sparse atlases (auto or somehow detect empties? Or simply load it all and only mark the ones that the atlas.json calls for)
	// offset/borders between sprites
	void load() // SQUARE atlas
		{
		if(!hasLoadedMetaYet)assert(false, "Load the meta data!");
		con.log("attempting to loading atlas(s)");
	//	con.log("Loading atlas at ["~filepath~"]");
		// need to load files based on processing the meta. which means we have to load META first!
		foreach(filename, entries; filesData) 
			{
			sources[filename] = getBitmap(r"./data/" ~ filename);
			foreach(entryNumber, meta; entries)
				{
				assert(!(meta.tilename in bmps), "ERROR - Duplicate tilenames in manifest! This would cause accidental overrides! Fix the manifest.");
				bmps[meta.tilename] = al_create_sub_bitmap(sources[filename], meta.x, meta.y, TILE_W, TILE_W);
				tileInfo t;
					t.isPassable = meta.isPassable;
				info[meta.tilename] = t;
				// note: we could merge tileInfo and fileScanEntry structures and skip this step
				}
			}
		writeln(info);
		}
	
	alias bmps this;

	}

/// (manifest) atlas handler
/// - for parsing a manifest.json file list of tiles and their string lookups
///=============================================================================
struct tileInfo
	{
	bool isPassable;
	}

class atlasHandler
	{
	bitmap* atlasbmp;
	bitmap*[256] bmps;
	tileInfo[256] info;
	
	void loadMeta(string filepath="./data/atlas.json")
		{
		con.log("Loading atlasMetadata at ["~filepath~"]");
		import std.json : JSONValue, parseJSON;
		import std.file : readText;
		string s = readText(filepath);
		JSONValue js = parseJSON(s);
		foreach(i, j; js["tiles"].array)
			{
//			writeln(i, " ", j, " ", j.type, " ", j[0], " ", j[1]);
			long 	index = j[0].integer;
			string 	bmpname = j[1].str; 
			bool 	isPassable = j[2].boolean;
//			writefln("[%s]", path);
			}
		}
	
	// TODO: alternative atlas formats.support variable widths.
	//  squareAtlases (below). Rectangle atlases. Sparse atlases (auto or somehow detect empties? Or simply load it all and only mark the ones that the atlas.json calls for)
	// offset/borders between sprites
	void load(string filepath="./data/atlas.png") // SQUARE atlas
		{
		con.log("Loading atlas at ["~filepath~"]");
		atlasbmp = getBitmap(filepath);
		int k = 0;
		for(int i = 0; i < 16; i++)
			for(int j = 0; j < 16; j++)
				{
				bmps[k] = al_create_sub_bitmap(atlasbmp, i*TILE_W, j*TILE_W, TILE_W, TILE_W);
				k++; 
				}
		}
	
	alias bmps this;
	}

/// Bitmap handler
///=============================================================================
/+
	- do we want to merge/support bitmap atlas handler functionality? 
	- how do we want to handle multiple frame animations?

	- todo: ERROR checking. force people to use lowercase for POSIX/windows compatibility, for example. or printable characters only.
+/
class bitmapHandler 
	{
	bool usePrettyConsole=false; // We lose stdout/stderr ordering when we pipe to pretty printer. Not terrible, but different.
	
	// - ADD list of bools for each to track whether they were ever used for trimming unused assets
	// - we can also keep track of number of requests for a bitmap. Not sure of how that's useful information?
	// - 
	bitmap*[string] data;
//	alias data this;

	bitmap* opIndex(string name)
		{
//		return *(key in data);
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
atlasHandler ah;
atlasHandler2 ah2;

void loadResources()
	{
	bh = new bitmapHandler();
	ah = new atlasHandler();
	ah2 = new atlasHandler2();
	bh.loadJSON();
	font1 = getFont("./data/DejaVuSans.ttf", 18);
	ah.load();
	ah.loadMeta();
	ah2.loadMeta(); // meta first
	ah2.load();
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
