import std.stdio;
import std.conv;
import std.string;
import std.format;
import std.json : JSONValue, parseJSON, JSONException;
import std.file : readText;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import molto;
import helper;
import main;
import g;

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

	this(string filepath)
		{
		load(filepath);
		}

	final void load(string filepath="./data/atlasManifest.json")
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
		processManifest();
		}
	
	void processManifest()
		{
		con.log("attempting to loading atlas(s) based on manifest");

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

	void unload()
		{
		foreach(b; bmps)
			{
			al_destroy_bitmap(b);
			}
		foreach(b; sources)
			{
			al_destroy_bitmap(b);
			}
		// TODO
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
