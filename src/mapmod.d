/+
	isometric work:
		- load an isometric map
		- add multiple layer support to map loader. Then we could do top/bottom layer for basic DataJack support.
		
	map work
		--> one thing in favor of NOT JSON is how easy it is to corrupt JSON by forgetting to repeat a comma.
	
	
	
	
	
	
	
	
	
	
		- object loading (kinda game specific)
			- objectID [from a table we add], x, y, health, 
			
		objectMapIDTable =
			[
			myObject, pointer to x field, pointer to y field, etc
			]
			
		so when we save, or load, it knows to grab from/into that specific field
		
		objectMappingIDTable
			[ 000==entry1==[goblin, goblin.x, goblin.y, goblin.hp],
			  001==entry2==[player, player.x, player.y, player.hp],
			  ...
			  ];
			  
		mapfile is like: (say, CSV)
				x	y	 hp
			000,5	, 0, 100
			000,25	, 1, 100
			000,8	,23, 100
			001,34	, 0, 100
			
				// do we support any value for N/A, non-override?
				// for example, we can have a NAME field for bosses
				// and override stats, but otherwise have them NULL for non-bosses
				
				// alternatively, boss/elites get their own objectID. But the schema will still have to change if we want to have MAP specified overrides.
				
				// if not, all overrides will have to be hardcoded or at least specified in another file.
				
		the MAIN BENEFIT to this CSV is extreme simplicity of processing and editing. More objects? Just add a line. 
		
		We may want an OBJID string instead of OBJID# in case we move objects/delete/add objects. So it's a hash instead, just like atlas.
		
		GOBLIN
		PLAYER
		REDMAN
		BLUMAN
		etc.
		
		also don't have to be same length. Easier in code to specify specific versions too, though be careful to have binary code referencing objects that might not be there/subject to change.

		[[loading from map]]
			each entry# in file, look up # in objectMappingIDTable, and then
			create an object of that type, and start setting values for each column
			
			
		---> if we do JSON/YAML/etc
	
		CSV // no support for comments unless we add them, not hard given simplicity.
			000,5	, 0, 100
			000,25	, 1, 100
			000,8	,23, 100
			001,34	, 0, 100
		
		JSON // no support for comments in code
		{"objects":
			[
			{"type":0, "x":5, "y":0, "hp":100},
			{"type":0, "x":25, "y":1, "hp":100},
			{"type":0, "x":8, "y":23, "hp":100},
			{"type":1, "x":34, "y":0, "hp":100, "mapnote":"red player here"},
			{"type":-1, "x":34, "y":0, "hp":100, "mapnote":"don't forget to add blue player"}, 
			{"type":2, "x":34, "y":0} // minimum required values only
			]}
			
			// note we can throw optional fields on the end easily. In fact, any field can be optional technically, though no x,y makes no sense usually even if the object is invisible we want to be able to see it in the editor to edit it. So type, x, and y should all be required.
			
			// negative ID range is special. -1 is a mapnote. But objects can have notes too.


		YAML (the dashes and indention matter!)
		
			https://github.com/dlang-community/D-YAML
			(and maybe others, mir-yaml, etc)
		
#this is a comment
---
objects:
- type: 0
  x: 5
  y: 0
  hp: 100
- type: 0
  x: 25
  y: 1
  hp: 100
- type: 0
  x: 8
  y: 23
  hp: 100
- type: 1
  x: 34
  y: 0
  hp: 100
  mapnote: red player here
- type: -1
  x: 34
  y: 0
  hp: 100
  mapnote: don't forget to add blue player
- type: 2
  x: 34
  y: 0


TOML		(more or less INI format. more for config files but still consider)
	https://code.dlang.org/packages/toml
	
	
	https://toml.io/en/
	
	https://toml.io/en/v1.0.0 reference
	
	double brackets is an ARRAY of tables (with same name)
	
#this is a comment
[[objects]]
type = 0
x = 5
y = 0
hp = 100

[[objects]]
type = 0
x = 25
y = 1
hp = 100

[[objects]]
type = 0
x = 8
y = 23
hp = 100

[[objects]]
type = 1
x = 34
y = 0
hp = 100
mapnote = "red player here"

[[objects]]
type = -1
x = 34
y = 0
hp = 100
mapnote = "don't forget to add blue player"

[[objects]]
type = 2
x = 34
y = 0



 -----> I mean, lots of these don't matter since an editor will be making most of these except for the initial debugging, which I'll be doing. End users don't matter as much.

TOML we can also do

[[object]]
	type = 2
	pos = [23, -23] # just like pairs
[[object]]
	type = 2
	pos = [23, 0] 

there's also shorthand "inline tables" if we care:

objects = [ { type = 1, x = 2, y = 3 },
           { type = 7, x = 8, y = 9 },
           { type = 2, x = 4, y = 8 } ]

see  https://toml.io/en/v1.0.0


https://martin-ueding.de/posts/json-vs-yaml-vs-toml/
+/
/+
	clonk is pixels.
	terreria is 16x16 tiles
	starbound is 8x8	(really?)
	cortex command is pixels?
	
	look at this game, Celeste, tile size: This could still easily be playable:
		8x8 pixels (ingame rendering is 320x180)
		https://images.squarespace-cdn.com/content/v1/608316e08c3eff323f18d9e6/1620424975009-M6W8HZC3B7FT447WBJQA/celeste_forsaken_city_grid.PNG
+/
/+
	byteMap - we may want to add support to chunkify large map bitmaps into 
	smaller power-of-2 chunk textures.

	If we want to, we could [magnify] the pixel maps so instead of 1x1 pixels,
	 each "pixel" is worth 2x2, 3x3, 4x4, ... etc like a tiled map with very 
	 small tiles. This increases the effective size of a map, or, reduces
	 the memory size for an certain size bitmap texture
	 
	 Currently it seems the decompression/asset loading itself is the slowest,
	 not so much the RAM/VRAM usage. 4096x4096x4 (32-bit) = 67,108,864 = 64MiB
	 each full-size layer.

	Also, we want to support a "painted" layer at somepoint. Whatever Worms and 
	Clonk did. We only store [TileType], not raw RGBA values, and then apply
	a texture (either constantly with a shader, or on instantiation).
	
	painting pixels is just simplest to get up and running with a paint program.

	don't forget scrolling layers (and repeating layers) for clouds/weather/etc
+/
import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import g;
import helper;
import viewportsmod;
import molto;
import atlasmod;

import std.stdio;

struct tileInstance
	{
	uint val;
	}
	
struct layer
	{
	string name; // useful? for saving? debugging?
	bitmap* data;
	float scale; 
		/// 1x = 1:1.  
		/// 2x scale = half the pixels per dimension?
		/// 0.5x scale = twice the pixels?
		
		/// scale of 2.0 makes a viewport offset * 2.0, which gives it the effect
		/// of appearing like it's in front of / above everything.
		
	float alpha=1.0; /// layer transparency (0.0 transparent, 1.0 opaque)
	
	this(string _name, string bitmapPath, float _scale=1.0) 	/// "just load the damn thing"
		{
		name = _name;
		data = getBitmap(bitmapPath);
		//data = al_create_bitmap(cast(int)mapSize.w, cast(int)mapSize.h);
		scale = _scale;
		/// "just load the damn thing"
		}
	
	this(string name, string path, idimen mapSize, float _scale=1.0)
		{
//		data = getBitmap(path);
		//data = al_create_bitmap(cast(int)mapSize.w, cast(int)mapSize.h);
	//	scale = _scale;
		assert(false);
		}
		
	this(string name, idimen mapSize, idimen bitmapSize)
		{
		assert(mapSize.w / bitmapSize.w == mapSize.h / bitmapSize.h, "parallax map doesn't scale evenly with map size!");
		scale = mapSize.w / bitmapSize.w; // bigger bitmap, smaller 'scale'
		data = al_create_bitmap(cast(int)bitmapSize.w, cast(int)bitmapSize.h);
		assert(false, "SHOULDNT BE CALLING THIS");
		}
		
	void onDraw(viewport v)
		{
		if(alpha == 0.0)
			{
			drawBitmap(data, pair(	0 + v.x - v.ox*scale, 
									0 + v.y - v.oy*scale));
			}else{
			drawTintedBitmap(data,
								color(1.0, 1.0, 1.0, alpha),
								pair(	0 + v.x - v.ox*scale, 
										0 + v.y - v.oy*scale),
										);
			}
 		}
	}
	
/// Pixel-based map
/+
	note: support for parallax layers
	
	note: we could support highlights. Specular highlights that shimmer based on
	a shader. For every X pixel that has highlight, a rolling wave function
	could be running that draws a resulting brighter pixel.

		- what did Hammerwatch do?

	note: We could, for testing, make layers "3d" in the sense each layer 
	represents some "thing", and that [map] layer could have... well layers
	that make up the constitutent parts. Whether for bump mapping, specular 
	highlights, etc. 
	
	We can even leave markers for things like environment mapping for 
	'reflections'. Those could either be a parallax layer super imposed,
	possibly at an angle or something else.
	
	Also note that the SHADERS could run after all layers are done drawing
	so the shaders also apply those "look for magic pixels" criterea to objects
	walking around with say, a lantern.

	though how this all fits with shadows, lightmaps, and 2d polygonal lighting
	i don't know. One immediate issue is when a transparent "thing" overwrites
	another "thing" pixel. Should they combine? Replace? And what does
	"replace specular" even mean in a real world context?
	
		normal map		[effect: bumps from lighting at hard angles]
		specular map? 	[effect: metalic shineyness]
		
		objects could have a lightmap
		colored lighting
		
	https://www.a23d.co/blog/different-maps-in-pbr-textures/
	physical based rendering
+/

/// 2D array width/height helpers
/// for using .w(idth) and .h(eight) of a 2d array (THESE CLASH WITH BITMAP .W .H)
/// these might collide with the bitmap thing. Also what if we have an ARRAY of BITMAPS? .w for bitmap or array?
// ---> variable arrays only!
size_t width(T)(T[][] array2d) { return array2d[0].length; }
size_t height(T)(T[][] array2d) { return array2d.length; } 

class byteMap
	{
	uint w=0, h=0;
	ubyte[] data;

	void draw(viewport v)
		{
		auto screen = al_get_backbuffer(al_display);
		al_lock_bitmap(screen, ALLEGRO_PIXEL_FORMAT.ALLEGRO_PIXEL_FORMAT_ANY, ALLEGRO_LOCK_WRITEONLY);
//		for(int j = cast(int)v.oy; j < SCREEN_H + cast(int)v.oy; j++)
//		for(int i = cast(int)v.ox; i < SCREEN_W + cast(int)v.ox; i++)
		int vox = cast(int)v.ox;
		int voy = cast(int)v.oy;
		for(int j = voy; j < voy + 200; j++)
		for(int i = vox; i < vox + 200; i++)
			{
			color c;
			if(get(i,j) == 0)c = black;
			else c = white;
			al_draw_pixel(i, j, c);
			}
		al_unlock_bitmap(screen);
		}

	void drawRectangle(irect r, ubyte val)
		{
		with(r)
			{
			assert(x >= 0);
			assert(y >= 0);
			assert(x < this.w);
			assert(y < this.h);
			for(int j = y; j < y + h; j++)
			for(int i = x; i < x + w; i++)
				{
				set(ipair(i,j), val);
				}
			}
		}
		
	void drawCircle(ipair pos, int r, ubyte val)
		{
		import std.math : sqrt;
		for(float i = -r; i < r; i++)
		for(float j = -r; j < r; j++)
			{
			if(sqrt(i^^2 + j^^2) <= r)set(cast(uint)(pos.i + i), cast(uint)(pos.j + j), val);
			}
		}
	
	this(string path) /// load From Bitmap
		{
		bitmap* b = getBitmap(path);
		assert(b !is null);
		w = b.w;
		h = b.h;
		data = new ubyte[w*h];
	
		al_lock_bitmap(b, al_get_bitmap_format(b), ALLEGRO_LOCK_READONLY);
		
		for(int i = 0; i < b.w; i++)
		for(int j = 0; j < b.h; j++)
			{
			color c = al_get_pixel(b,i,j);
			set(i,j, cast(ubyte)(c.r*256));
			}
		al_unlock_bitmap(b);
		}
	
	this(uint _w, uint _h)
		{
		w = _w;
		h = _h;
		assert(w > 0);
		assert(h > 0);
		data = new ubyte[w*h];
		}
	
//	import std.range : chunks;
//		return chunks(data, w); // this would return the whoel chunk...

	ubyte get(ipair pos     ){return data[pos.i + pos.j*w];}
	ubyte get(uint i, uint j){return data[i + j*w];}
		
	final void set(ipair pos     , ubyte val){data[pos.i + pos.j*w] = val;}
	final void set(uint i, uint j, ubyte val){data[i + j*w] = val;}
	}

class pixelMap : mapBase
	{
	string name="test";
	//ubyte[][] data;
	byteMap data;
	layer[] layers;
	
	// with large or huge maps, we'll actually have to scroll the minimap itself
	// also we're doing no object drawing. Could be as simple as a list traversal
	// with colored circles. Not even sure if this feature is needed so for now
	// it's just more of a debug tool.
	void drawMinimap(pair screenPos, float scale=1/16.0) // use implied viewport?
		{
		auto v = IMPLIED_VIEWPORT;
		float cx = screenPos.x; // (dialog position on screen)
		float cy = screenPos.y;
		float offx = v.ox*scale; //offset into x/y
		float offy = v.oy*scale;
		float cw = v.w*scale;
		float ch = v.h*scale;
		// <- add drawing black transparent background?
		al_draw_filled_rectangle(
			cx, 
			cy, 
			cx + dim.w*scale,
			cy + dim.h*scale,
			color(.25,.25,.25,.50));
		al_draw_scaled_bitmap2(layers[1].data, cx, cy, scale, scale, 0);
		al_draw_rectangle(
			cx + offx, 
			cy + offy, 
			cx + offx + cw, 
			cy + offy + ch, 
			white, 1);
		// draw a rectangle at this scale factor too.
		}
		
	bool isValidMovement(pair pos) /// Checks for both physical obstructions, as well as map boundaries
		{
		import std.stdio : writeln;
		if(pos.x < 0 || pos.y < 0)return false;
		if(pos.x >= dim.h || pos.y >= dim.h)return false;

		// holy shit this is slow
	//	color c = al_get_pixel(layers[1].data, cast(int)pos.x, cast(int)pos.y);
//		if(c.g == 0)
	
// if we're using ARRAY DATA:	
		if(data.get(ipair(pos)) == 0) // kinda ugly, but it is a clear "recast" to int if you know the api
			{
//			writeln("0");
			return true;
			}else{
	//		writeln("1");
			return false;
			}
		}
	
	/+
		NOTE: Scrolling layers. clouds basically. But our "shimmer" layer 
		(see below) with the shaders could also apply. Make water, or gold 
		treasure, shimmer.
	
	
		NOTE: If we do parallax layers (for foreground or background)
		they should ideally be non-physical/non-interacting layers because
		they have to be a DIFFERENT SIZE than the rest. 
		
		1/2 scroll rate = 2x bitmap size (right?) 
		
		when you scroll across. So how would you even interact with that
		when pixels are no longer constant size?
		
		One "issue" is if we're using a parallax layer for something that
		gets painted on change, such as "background ground" behind a dug
		mountain. We may be affecting one pixel with physics but we're
		**drawing** to much more. Or worse, the opposite, if we have two
		END pixels that could map back to the same starting physics pixel.
		
		It's not the end of the world, but needs to be examined for the 
		boundary conditions.
	+/
	/+
		Draw order issue:
			we need to have a split (possibly multiple, but possibly only one)
			for object layer to be drawn. Everything before, and everything after.
			We could set an arbitrary draw order using anything negative going
			first, 0.0 being object layer, and anything after, going after.
			
			(though use integers since float comparisons are iffy)
			
			Or, we could just have two separate lists. Background layers and
			foreground layers. Simple enough.
	+/
	
	this(idimen _dim)
		{
		dim = _dim;
//		data = new byteMap(2048, 2048); 
		data = new byteMap("./data/maps/map1layer1.png");
/+		layers ~= layer("sky", idimen(2000, 2000), 1); 
		layers ~= layer("background", idimen(2000, 2000), 1);  /// distant fake mountains
		layers ~= layer("tunnel", idimen(2000, 2000), 1);
		layers ~= layer("foreground", idimen(2000, 2000), 1);
+/
		layers ~= layer("terrain", "./data/maps/map1layer0.png", .9);
		layers ~= layer("terrain", "./data/maps/map1layer1.png", 1);
		layers ~= layer("terrain", "./data/maps/map1layer2.png", 2);
		layers[2].alpha = .5;
		}
		
	void onTick() /// physics
		{
		}
	
	void onDraw(viewport v) //split to onDrawBackground onDrawForeground for before/after objects
 		{
		foreach(l; layers)
			{
			l.onDraw(v);
			}
		//data.draw(v);
		// drawing a shit ton of pixels will be slow in OpenGL/D3D.
		// But we can dump them to a bitmap, and then draw to those bitmaps 
		// only on updates.
		
		// the only thing that's kind of annoying is ALLEGRO_BITMAPS are likely 
		// way slow for massive simple array access with all kinds of checks
		// for stupid stuff like sub-bitmaps and color conversions.
		
		// We could have an array of source data for the pixels. And, when the 
		// pixel array is updated, we also update the associated bitmaps (if
		// there are multiple)
		}
	}

/// Tile map
class tileMap : mapBase
	{
	float w=256, h=256;
	idimen size=idimen(256,256);
	uint[256][256] data;
		
	void drawRectangle(irect r, ubyte val)
		{
		with(r)
			{
			assert(x >= 0);
			assert(y >= 0);
			assert(x < this.w);
			assert(y < this.h);
			for(int j = y; j < y + h; j++)
			for(int i = x; i < x + w; i++)
				{
				set(ipair(i,j), val);
				}
			}
		}
		
	void drawCircle(pair pos, int r, ubyte val)
		{
		import std.math : sqrt;
		for(int i = -r+1; i < r; i++)
		for(int j = -r+1; j < r; j++)
			{
			if(sqrt(cast(float)i^^2 + cast(float)j^^2) < r - 1.0 + 0.4)
				{
				int ci = cast(uint)pos.x/TILE_W + i;
				int cj = cast(uint)pos.y/TILE_W + j;
				set(ipair(ci,cj), val); 
			//	writeln(ci, " ", cj, " - ", sqrt(cast(float)i^^2 + cast(float)j^^2), " < ", r);
				}
			}
		}
	
	this()
		{
		import std.random : uniform;
		int z = 0;
		for(int i = 0; i < dim.w; i++)
			for(int j = 0; j < dim.h; j++)
				{
				data[i][j] = 0;
				z++;
				
				import std.math : sin, sqrt;
				
				if(z>15){z=0; data[i][j] = 1; }
				if(j > 16) data[i][j] = uniform!"[]"(1,3);
				if(sqrt((j-30)^^2 + sin(i/2/3.14159)*10^^2) < 10)data[i][j] = 2;
				}
		}
			
	bool set(ipair pos, ubyte val)
		{
		if(pos.i >= 0 && pos.i < 256 && 
		   pos.j >= 0 && pos.j < 256)
			{
			data[pos.i][pos.j] = val; 
			return true;
			}
		return false;
		}
	
	void onDraw(viewport v)
		{
		float x = 0, y = 0;
		int iMin = capLow (cast(int)v.ox/TILE_W, 0);
		int jMin = capLow (cast(int)v.oy/TILE_W, 0);		
		int iMax = capHigh(SCREEN_W/TILE_W + cast(int)v.ox/TILE_W + 1, MAP_W-1);
		int jMax = capHigh(SCREEN_H/TILE_W + cast(int)v.oy/TILE_W + 1, MAP_H-1);

		import main : tints, timeIndex;
		al_set_shader_float_vector("tint", 3, &tints[0], 1);
		al_set_shader_float("timeIndex", timeIndex);
//https://www.allegro.cc/manual/5/al_hold_bitmap_drawing
//		writeln(" - ", pair(iMax, jMax));
		al_hold_bitmap_drawing(true);
		for(int i = iMin; i <= iMax; i++) // FIX WARNING, this shouldn't need +1 !!! are we rounding down?
			for(int j = jMin; j <= jMax; j++) // actually +1 hits array bounds!
				{
				x = i*TILE_W;
				y = j*TILE_W;
				
				auto val = data[i][j];
				bitmap* b = null;
				if(val == 0)b = ah2["grass"];
				if(val == 1)b = ah2["sand"];
				if(val == 2)b = ah2["brick"];
				if(val == 3)b = ah2["wood"];
				if(val == 4)b = ah2["wall"];
				if(val == 5)b = ah2["reinforcedwall"];
				if(val == 6)b = ah2["lava"];
				if(val == 7)b = ah2["water"];
				assert(b != null);
				
				drawBitmap(b, pair(x-v.ox, y-v.oy), 0);

				(*stats["tiles"]).drawn++;
				}
		al_hold_bitmap_drawing(false);
		}
		
	void onTick()
		{
		}
	
	bool isValidMovement(pair pos) /// Checks for both physical obstructions, as well as map boundaries
		{
		import std.stdio : writeln;
//		writeln(pos);
		if(pos.x < 0 || pos.y < 0)return false;
		if(pos.x/TILE_W >= w || pos.y/TILE_W >= h)return false;

		// holy shit this is slow
	//	color c = al_get_pixel(layers[1].data, cast(int)pos.x, cast(int)pos.y);
//		if(c.g == 0)
	
// if we're using ARRAY DATA:	
		auto p = ipair(pos);
		with(p)
		if(data[i/TILE_W][j/TILE_W] == 0) // kinda ugly, but it is a clear "recast" to int if you know the api
			{
//			writeln("0");
			return true;
			}else{
	//		writeln("1");
			return false;
			}
		}
	}

/// Requirements: 
///  - flat. Does not have any map heights. Just tiles + objects
/// we have to sort the object list against our projection matrix. best way to do this?
/// also if we have 3d coordinates all a sudden, we've got TRIPLETS instead of PAIRS.
/// unless we throw Z on a separate variable which is ugly but allows all other code to work for now.
struct triplet{float x,y,z;} // or trip.  or pair3?

pair mapToScreenSpace(pair pos) /// note: float pair in case we want to go from 1.5 tile to screen space
	{
	return pair((pos.x - pos.y) * ISOTILE_W/2, (pos.x + pos.y) * ISOTILE_H/2);
	// https://clintbellanger.net/articles/isometric_math/
	}

pair screenToMapSpace(pair screen)
	{
	pair map = pair
		(
			(screen.x / (ISOTILE_W/2) + screen.y / (ISOTILE_H/2)) /2,
			(screen.y / (ISOTILE_H/2) -(screen.x / (ISOTILE_W/2))) /2
		);
	return map;
	}

const int ISOTILE_W = 64;
const int ISOTILE_H = 32;
class isometricFlatMap : mapBase
	{
	import std.random : uniform;
	int[256][256] data;
	
	override void load(string path)
		{
		import toml;
		import std.file : read;
		auto tomldata = parseTOML(cast(string)read(path));
		//writeln(data["objects"]);
//		pragma(msg, typeof(tomldata["map"]["layer1"]));
		foreach(idx,o; tomldata["map"]["layer1"].array)
			{
			writeln("----", o);
			for(int j = 0; j < 10; j++)
				{
				data[idx+16][j+16] = cast(int)o[j].integer;
				}
			}
		return;
		}

	this()
		{
		load("./data/maps/map3d.toml");
//		for(int i = 0; i < 256; i++)data[i][i] = 5;

/+
		for(int i = 0; i < 1000; i++)data[uniform!"[]"(0,255)][uniform!"[]"(0,255)] = 1;
		for(int i = 0; i < 1000; i++)data[uniform!"[]"(0,255)][uniform!"[]"(0,255)] = 2;
		for(int i = 0; i < 1000; i++)data[uniform!"[]"(0,255)][uniform!"[]"(0,255)] = 3;
		for(int i = 0; i < 1000; i++)data[uniform!"[]"(0,255)][uniform!"[]"(0,255)] = 4;
		for(int i = 0; i < 1000; i++)data[uniform!"[]"(0,255)][uniform!"[]"(0,255)] = 5; // wall+/
//		writeln(data);
//		assert(0);
		}
		
	void onDraw(viewport v)
		{
		// we need to cycle through possible slanted values on our screen, and lookup each one
		// and draw them. So that we're back-of-screen order first.
		// however, how do we decide a width and height?
		
		
		pair minValue = pair(999,999);
		pair maxValue = pair(-999,-999);

		// we could find screenspace min/max of all tile corners.
		import std.algorithm : min, max;
		int wide=32;
		int tall=32;
		for(int j = tall; j > 0; j--)
			for(int i = wide; i > 0; i--)
				{
				bitmap* bmp;
				pair  pt  = screenToMapSpace(pair(i*ISOTILE_W,j*ISOTILE_H));
				ipair ipt = ipair(pt); // round it off
//				writeln(pt);
				float rowOffsetX = 0;
				float rowOffsetY = 0;
//				writeln(i," ",j,pt, ipt);
				minValue.x = min(ipt.i, minValue.x);
				minValue.y = min(ipt.j, minValue.y);
				maxValue.x = max(ipt.i, maxValue.x);
				maxValue.y = max(ipt.j, maxValue.y);
				if(ipt.i > 255 || ipt.j > 255)continue;
				if(ipt.i < 0   || ipt.j < 0)continue;
	//			writeln(ipt, " ",data[ipt.i][ipt.j]);
				switch(data[ipt.i][ipt.j])
					{
					case 0:
						bmp = ah2["isotile01"]; break;
					case 1:
						bmp = ah2["isotile02"]; break;
					case 2:
						bmp = ah2["isotile03"]; break;
					case 3:
						bmp = ah2["isotile04"]; break;
					case 4:
						bmp = ah2["isotile05"]; break;
					case 5:
						bmp = ah2["isowall01"]; break;
					default:
						assert(0);
						break;
					}
				
				drawBitmap(bmp, 
					pair(
						ipt.i*ISOTILE_W/2 - v.ox + 300 + rowOffsetX, 
						ipt.j*ISOTILE_H/2 - v.oy + 300 + rowOffsetY), 0);
				}
		writeln("min/max map value coordinates:", minValue, "/", maxValue);
		}
	}

class mapBase
	{
	idimen dim = idimen(256, 256); // we could call this dim.w dim.h for (dim)ensions?

	void load(string path){};
	void save(string path){};
	bool isValidMovement(pair pos) = 0;

	bool isInsideMap(pair pos) //external so others can use it.
		{
		if(pos.x < 0             || pos.y < 0)return false;
		if(pos.x/TILE_W >= dim.w || pos.y/TILE_W >= dim.h)return false;
		return true;
		}

	bool isInsideMap(ipair pos) 
		{
		if(pos.i < 0      || pos.j < 0){return false;}
		if(pos.i >= dim.w || pos.j >= dim.h){return false;}
		return true;
		}
	}
