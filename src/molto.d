/+
	Molto Allegro
	
	extensions for DAllegro + Allegro5

	by Chris Katko
+/

/+
	Notes on unit system (pair, apair, vpair, ipair, ...)
		- we could use the [attribute] system here and combine them into a single
		construct. The issue, as always, is that the user doesn't see the
		 attributes. So making them implicit is a reciepe for ambiguity 
		 and debugging nightmares.
		 
		- we could try it, just for learning purposes however. We immediately
		run into x,y vs i,j naming problem and lose that protection.
		
		---> UDAs can be KEY PAIRS?! They can have values! wowza.
			@("color") int taco;
			@("color", "red") int taco; 
			
			I mean, I guess it's just a tuple and you're inferring key-value 
			pairs.

		WAIT, no. you can turn them into entire STRUCTS? This is disturbingly 
		powerful and error prone.
		
		http://dpldocs.info/experimental-docs/std.traits.getUDAs.html
			
			struct Attr { string name; int value;}
			@Attr("Answer", 42) int a;
			
		so we just attached an answer:42 to our integer. But how do UDAs travel 
		around? Can they? This is COMPILE TIME only information!
		
		You can also search ALL SYMBOLS by UDA mark. So theoretically, simply adding
		@renderable (or something) to any object in objects.d, I could have my
		 game spit out onDraw, onTick, onPrune, and statistics code.
		
		Granted, it's so new age, that 99.999% of people would need more time to 
		have it explained to them, than it would to just do it the manual way.
		
		@coreObject
			onDraw, onTick, onPrune, stat

			objects, structures, particles
			
		Now this still doesn't let us fine tune our statistics. All object
		children are tossed in objects. If we do parent and child, it explodes.
		
		But its still a really cool idea to play with. The key is (other than 
		learning) is: The part we're automating, is it actually something that
		takes so much time dealing with that it's worth the time to automate it?
		
		The only real scenario that I see here is, when we use this as a starter 
		template / basic engine. We don't have to worry about deleting/reseting
		lots of code. We simply make new objects (with no constraints except the 
		basicInterface of onDraw, etc) and tag them.
		
		PROBLEM. DRAW ORDER. Unless we now specify them somewhere, we now have
		broken the draw order.
	
		We could store draw order in the @coreObject UDA itself.
			@coreObject("zLevel", 300)
		
		but now we have to require all z-levels be explicit (then the
		 templates do a sort based on z-levels before dumping rendering 
		 functions) but the human element being required to be aware of
		 all other z-levels to not overstep them or know where to fit them
		 is rather annoying.
		 
		 The alternative (and this still may be better) is to have two 
		 modifications. tag the object, as well as have a draw list and
		 if there's a missing or duplicate one, the template will throw 
		 an error.
		 
		 We **COULD** also use this tagging system to automatically "bunch" 
		 up related child objects for statistics. Anything marked @ship
		 is counted as a ship, and such.
		 
		 
	- YOU CAN USE A FUNCTION AS AN ATTRIBUTE? COME ON, PEOPLE.
+/
/+
class spair
	{
	import std.meta, std.traits;
	float x, y;
	
	 this()
		{
		import std.traits;
		alias TA = __traits(getAttributes, typeof(this)); //must be a TYPE
		pragma(msg, TA); 
		// result:  ()  empty aliasseq		
		// does not appear that an object can understand itself.
		}
	}

void spairTest()
	{
	@("taco", "asg") spair t = new spair;
//	alias TP = __traits(getAttributes, t);
	//pragma(msg, TP);
	}+/

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;
import allegro5.allegro_audio;
import allegro5.allegro_acodec;

import viewportsmod : viewport;
import g;
import helper;
import std.math;
import std.conv;
import std.stdio;
import std.format : format;
import std.string : toStringz;

// ALLEGRO symbols
// -----------------------------------------------------------------

// upper case aliases
alias BITMAP = ALLEGRO_BITMAP; //see also 'bitmap' or should we stick to capitals?
alias COLOR = ALLEGRO_COLOR;
alias FONT = ALLEGRO_FONT;

// lower case aliases (optional)
alias color = ALLEGRO_COLOR;
alias sample = ALLEGRO_SAMPLE;
alias bitmap = ALLEGRO_BITMAP;
	
COLOR white  = COLOR(1,1,1,1);
COLOR black  = COLOR(0,0,0,1);
COLOR red    = COLOR(1,0,0,1);
COLOR green  = COLOR(0,1,0,1);
COLOR blue   = COLOR(0,0,1,1);
COLOR yellow = COLOR(1,1,0,1);
COLOR orange = COLOR(1,0.65,0,1);

alias KEY_UP = ALLEGRO_KEY_UP; // should we do these? By time we write them out we've already done more work than just writing them.
alias KEY_DOWN = ALLEGRO_KEY_DOWN; // i'll leave them coded as an open question for later
alias KEY_LEFT = ALLEGRO_KEY_LEFT; 
alias KEY_RIGHT = ALLEGRO_KEY_RIGHT; 

// pairs, trios, etc code
// ----------------------------------------------------------------

/+
	notes: 
	- VECTOR CODE may be super useful here like when we implement 
	vector additions. There's likely already vector code, so either 
	integrate it or duplicate it. Gotta add and multiply simple vectors. 

	- I wonder if there's any kind of marking for "absolute" vs "relative" we 
	can do with them, and whether explicitly using rpairs (relative) vs pairs (absolute),
	or somehow implicitly marking them absolute or relative and letting them
	resolve themselves? In general, that could introduce all kinds of terribleness
	so simple.
	
	The only auto conversions we're doing right now are with vpairs (viewport pairs) 
	because they're only used in obvious cases, in obvious relationships, and its hardcoded.
+/

void testipair()
	{
	import std.math.rounding : floor, ceil;
	ipair t = ipair(1,2);
	pair u = pair(3,4);
	t = ipair(u, &floor);
	writeln(t);
	t = ipair(u, &ceil);
	writeln(t);
	}
	
struct dimen /// dimension. good name? dimen dim... ehh...?
	{ 
	float w, h; 
	}

struct idimen /// dimension. good name? dimen dim... ehh...?
	{ 
	int w, h; 
	}

struct ipair
	{
	int i=0, j=0;

//	this(T)(T[] dim) //multidim arrays still want T[]? interesting
	//	{
	//	}

	this(pair val, float function(float) roundingFunction) /// Convert a pair with a desired rounding function.
		{
		// WARN: Technically, roundingFunction could be a function that 
		// DOESN'T give only integers in float format, like quantize().
		// But if you're dumb enough to do that, we'll just chop it to 
		// integer anyway. 
		i = cast(int)roundingFunction(val.x);
		j = cast(int)roundingFunction(val.y);
		}

	this(int _i, int _j)
		{
		i = _i;
		j = _j;
		}

	this(ipair p)
		{
		i = p.i;
		j = p.j;
		}

	this(ipair p, int offsetx, int offsety)
		{
		i = p.i + offsetx;
		j = p.j + offsety;
		}		

	// WARNING: take note that we're using implied viewport conversions
	// .... ARE WE?!?!? 
	this(pair p)
		{
		// this is ROUNDING THE INTEGER DOWN. (or the other one)
//		alias v=IMPLIED_VIEWPORT; // wait this isn't used???
//		this = ipair(cast(int)p.x/TILE_W, cast(int)p.y/TILE_H);
//		this = ipair(cast(int)lround(p.x/cast(float)TILE_W), cast(int)lround(p.y/cast(float)TILE_H));
		float x, y;
//		writeln("going from ", p);
		if(p.x < 0 )x = ceil(p.x) - (TILE_W-1);// FIXME. TODO. THIS WORKS But do we UNDERSTAND IT ENOUGH?
		if(p.y < 0 )y = ceil(p.y) - (TILE_H-1);
		if(p.x >= 0)x = floor(p.x);
		if(p.y >= 0)y = floor(p.y);

		this = ipair(cast(int)(x/cast(float)TILE_W), cast(int)(y/cast(float)TILE_H));
//		writeln("going to ", this);
		}

	this(pair p, float xOffset, float yOffset) /// take a pair, and apply scalar offsets to both
		{
//		alias v=IMPLIED_VIEWPORT; // wait this isn't used???
//		writeln("  going from ", p, " ", xOffset, " ", yOffset);
		float x, y;
		if(p.x + xOffset < 0 )x = ceil(p.x + xOffset) - (TILE_W-1); // FIXME. TODO. THIS WORKS But do we UNDERSTAND IT ENOUGH?
		if(p.y + yOffset < 0 )y = ceil(p.y + yOffset) - (TILE_H-1);
		if(p.x + xOffset >= 0)x = floor(p.x + xOffset);
		if(p.y + yOffset >= 0)y = floor(p.y + yOffset);

		this = ipair(cast(int)(x/cast(float)TILE_W), cast(int)(y/cast(float)TILE_H));
//		writeln("  going to ", this);
		}

	this(T)(T obj, float xOffset, float yOffset) /// Take ANYTHING. Are we using this?!?!
		{
		pragma(msg, "Are you using this code???");
	//	alias v=IMPLIED_VIEWPORT; // wait this isn't used???
		this = ipair(cast(int)(obj.pos.x+xOffset)/TILE_W, cast(int)(obj.pos.y+yOffset)/TILE_H);
		}
		
	bool opEquals(const int val) const @safe nothrow pure // what about float/double scenarios?
		{
		assert(val == 0, "Did you really mean to check a pair to something other than 0 == 0,0? This should only be for velocity pairs = 0");
		if(i == val && j == val)
			{
			return true;
			}
		return false;
		}
	
	// no idea what it should be
	// https://forum.dlang.org/post/dgawdxjtsffcqjskwwwx@forum.dlang.org
	size_t toHash() const nothrow @safe 
		{
		return typeid(this).getHash(&this); 
		// https://forum.dlang.org/post/iavcspvqttccocezmqeb@forum.dlang.org
		} 
	
	void opAssign(int val)
		{
		assert(val == 0, "Did you really mean to set a pair to something other than 0,0? This is an unlikely case.");
		i = val;
		j = val;
		}
	}

struct pair
	{
	float x=0, y=0;
	
	bool opEquals(const int val) const @safe nothrow pure // what about float/double scenarios?
		{
		assert(val == 0, "Did you really mean to check a pair to something other than 0 == 0,0? This should only be for velocity pairs = 0");
		if(x == val && y == val)
			{
			return true;
			}
		return false;
		}

	// no idea what it should be
	// https://forum.dlang.org/post/dgawdxjtsffcqjskwwwx@forum.dlang.org
	size_t toHash() const nothrow @safe 
		{
		assert(false, "VERIFY BEFORE USING");
		return typeid(this).getHash(&this); 
		// https://forum.dlang.org/post/iavcspvqttccocezmqeb@forum.dlang.org
		} 
	
	void opAssign(int val)
		{
		assert(val == 0, "Did you really mean to set a pair to something other than 0,0? This is an unlikely case.");
		x = cast(float)val;
		y = cast(float)val;
		}

	void opAssign(apair val) /// ipair from velocity vectors (apair, "angle/vel pair");
		{
		x = cos(val.a)*val.m;
		y = sin(val.a)*val.m;
		}
	 
	auto opOpAssign(string op)(pair p)
		{
		static if(op == "+=")
		{
			pragma(msg, "+= THIS HASNT BEEN VERIFIED");
			//x += p.x;
			//y += p.y; // also can't we just do:
			this = this + p; // VERIFIY
			return this;
		}else static if(op == "-=") 
		{
			assert(false, "TODO");
		}else static if(op == "+" || op == "-")
		{
//			pragma(msg, op);
			mixin("x = x "~op~" p.x;");
			mixin("y = y "~op~" p.y;");
			return this;
		}
		else static assert(0, "Operator "~op~" not implemented");
			
		}
	
	/+
	//https://dlang.org/spec/operatoroverloading.html
    // this ~ rhs
	T opBinary(string op)(T rhs)		// add two pairs
		{
		static if (op == "+") 
			{
			pragma(msg, "hello");
			return pair(this, rhs.x, rhs.y);
			}
//		else static if (op == "-") return data - rhs.data;
		else static assert(0, "Operator "~op~" not implemented");
		}	
	
	// http://ddili.org/ders/d.en/operator_overloading.html
    auto opOpAssign(string op)(pair p) 
		if(op =="+=" || op == "-=")
		{
			pragma(msg, "hello2");
        //mixin("ptr"~op~"i;");
//        ptr += p;
		return this; 
		}
	+/
	this(T)(T t) //give it any object that has fields x and y
		{
		x = t.x;
		y = t.y;
		}

	this(T)(T t, float offsetX, float offsetY)
		{
		x = t.x + offsetX;
		y = t.y + offsetY;
		}
	
	this(int _x, int _y)
		{
		x = to!float(_x);
		y = to!float(_y);
		}

	this(float _x, float _y)
		{
		x = _x;
		y = _y;
		}

	this(apair val)
		{
		x = cos(val.a)*val.m;
		y = sin(val.a)*val.m;
		}
	}

import std.traits;
import std.meta;

bool isAny(T, U...)(T t, U u)
	{
	pragma(msg, typeof(t));
	pragma(msg, "--------------");
	pragma(msg, typeof(u));
	pragma(msg, "--------------");
	foreach(element; u) //__traits(parameters)
		{
	//	if(is(element : u))return true;
		pragma(msg, typeof(element));
		if(is(typeof(element) : ALLEGRO_BITMAP *))return true;
		}
	return false;

	}

bool isAny2(T, U...)(U u)
	{
	pragma(msg, typeof(u));
	pragma(msg, "--------------");
	foreach(element; u) //__traits(parameters)
		{
	//	if(is(element : u))return true;
		pragma(msg, typeof(element));
		if(is(typeof(element) : ALLEGRO_BITMAP *))return true;
		}
	return false;

	}
	
// whats an enum template here?
// https://stackoverflow.com/questions/10957744/struct-and-tuple-template-parameters-in-d	

// and what IS the deal with all the enum = [code] here
// "manifest constants" maybe?
// https://stackoverflow.com/questions/32998781/opdispatch-and-compile-time-parameters
/+

T update(T)(T t)
    if(isIncrementableStruct!T)
	{
    auto copy = t;

    foreach(ref var; copy.tupleof)
        ++var;

    return copy;
	}

template isIncrementableStruct(T)
	{
    enum isIncrementableStruct = is(T == struct) &&
                                 is(typeof
									(
										{T t; foreach(var; t.tupleof) ++var;}
									)
									);	// this looks like an isCompilable for a struct with fields
	}
+/

void draw(T...)(T t)
	{
	if(is(typeof(t[0]) : ALLEGRO_BITMAP*))
	//	if(isAny2!(ALLEGRO_BITMAP*)(t))
	//	if(isAny(ALLEGRO_BITMAP*, t))  how do we pass a TYPE?!
	//	if(is(typeof(t) : ALLEGRO_BITMAP*))
	//	if(isContainedIn(typeof(center).stringof, t))   // https://dlang.org/articles/constraints.html
		{	
	//	pragma(msg, typeof(t));
		al_draw_center_rotated_bitmap(t[0], t[1].x, t[1].x, 0, 0);
		}
	if(is(typeof(t[0]) : string))
		{
		// al_draw_text(const ALLEGRO_FONT *font, ALLEGRO_COLOR color, float x, float y, int flags, char const *text);
//		al_draw_text(font, color, t[1].x, t[1].y,  0, text);
		}
	}

//enum center;
struct center{bool yes;}
center centered;

void test()
	{
//	draw(grass_bmp);
	draw(grass_bmp, pair(320, 320), center(true));
	}

// later:
// pairs
// https://forum.dlang.org/post/lyplbnbujwmapooclrce@forum.dlang.org
// using / with
// https://forum.dlang.org/post/lyplbnbujwmapooclrce@forum.dlang.org

vpair toViewport(T)(T point, viewport v)
	{
	return vpair(point.x + v.x - v.ox, point.y + v.y - v.oy);
	}
	
viewport IMPLIED_VIEWPORT;

void setViewport2(viewport v)
	{
	IMPLIED_VIEWPORT = v;
	}

vpair toViewport2(T)(T point)
	{
	assert(IMPLIED_VIEWPORT !is null);
	alias v = IMPLIED_VIEWPORT;
	return vpair(point.x + v.x - v.ox, point.y + v.y - v.oy);
	}

/// WARNING: This can be a 'CONFUSING' construct if you don't enforce it 
///		through understanding:
///
///  - converts world coordinates to viewport coordinates automatically
///	 - IMPLIED_VIEWPORT (an appropriately loud name) must be set beforehand 
///		with setViewport2(viewport); or you'll segfault.
struct vpair
	{
	float r, s;
	
	this(T)(T obj) // warning: this only works if we [ENFORCE] that x and y MEAN world coordinates regardless of object.
		{ // also, why don't we just use a pair for position on objects instead of indivudal x/y's? 
		r = obj.x + IMPLIED_VIEWPORT.x - IMPLIED_VIEWPORT.ox;
		s = obj.y + IMPLIED_VIEWPORT.y - IMPLIED_VIEWPORT.oy;		
		}

	this(float _x, float _y)
		{
		r = _x + IMPLIED_VIEWPORT.x - IMPLIED_VIEWPORT.ox;
		s = _y + IMPLIED_VIEWPORT.y - IMPLIED_VIEWPORT.oy;
		}

	this(pair pos)
		{
		r = pos.x + IMPLIED_VIEWPORT.x - IMPLIED_VIEWPORT.ox;
		s = pos.y + IMPLIED_VIEWPORT.y - IMPLIED_VIEWPORT.oy;		
		}

	this(vpair vpos)
		{
		r = vpos.r;
		s = vpos.s;		
		}

	/// OFFSET constructors:
	///
	/// Usage example:
	///		 drawBitmap(bmp, vpair(this, -30, 0), flags);
	///
	///	have a this.vpair, but then add an offset
	/// build vpair with an offset
	this(vpair vpos, float xOffset, float yOffset)
		{
		r = vpos.r + xOffset;
		s = vpos.s + yOffset;	
		}
		
	/// build vpair with an offset
	this(T)(T obj, float xOffset, float yOffset)
		{
		r = obj.x + xOffset + IMPLIED_VIEWPORT.x - IMPLIED_VIEWPORT.ox;
		s = obj.y + yOffset + IMPLIED_VIEWPORT.y - IMPLIED_VIEWPORT.oy;		
		}
	}

//void testthing()
//	{
//	bool[100][100] isMapPassable;
//	ipair ipTest = ipair(50,50);
//	ipair(isMapPassable);
//	ip(isMapPassable);
//	}

struct apair
	{
	float a; /// angle
	float m; /// magnitude
	} // idea: some sort of automatic convertion between angle/magnitude, and xy velocities?

struct rpair // relative pair. not sure best way to implement automatic conversions
	{
	float rx; //'rx' to not conflict with x/y duct typing.
	float ry;
	}

/+
    enum position = staticIndexOf!(pos, A);
    static assert(position > -1, "Must pass a position");
    enum hasCenteredPosition = anySatisfy!(isa!center, A);

    static if (hasCenteredPosition) {
        float temp_x = a[position].x - bit.w/2;
        float temp_y = a[position].y - bit.h/2;
    } else {
        float temp_x = a[position].x;
        float temp_y = a[position].y;
    }
+/

/// Returns the first element of Args that is of type T,
/// or an empty AliasSeq if no such element exists.
template find(T, Args...) {
    enum idx = staticIndexOf!(T, typeof(Args));
    static if (idx > -1) alias find = Args[idx];
    else                 alias find = AliasSeq!();
}

// Checks if find!() found anything.
enum found(T...) = T.length == 1;

// Using those, you would write this code:

void funct2(A...)(ALLEGRO_BITMAP* bit, A a)
if (anySatisfy!(isa!pos, A))
{
    enum isCentered  = anySatisfy!(isa!center, A);

    alias position = find!(pos, a);
    alias rotation = find!(rotate, a);
    alias scaling  = find!(scale, a);
    // alias stretch  (non-aspect correct / affine? scaling)
    // alias tint
    // alias flipH 
    // alias flipV 
    // alias flip(w), flip(h) (somehow abuse bitmap.w bitmap.h ?) 

    static if (isCentered) {
        // No need to use array lookup - find!() did that for us.
        // That also means we can more easily modify position directly,
        // instead of using temporaries.
        position.x -= bit.w/2;
        position.y -= bit.h/2;
    }

    static if (!found!rotation && !found!scaling) {
        // Since rotation and scaling are empty AliasSeqs here,
        // attempting to use them will cause immediate compile errors.
        al_draw_bitmap(bit, position.x, position.y, 0);
    } else static if (found!rotation && !found!scaling) {
        al_draw_rotated_bitmap(bit,
            bit.w/2,    bit.h/2,
            position.x, position.y,
            rotation.a,
            0);
    } else static if (found!rotation && found!scaling) {
        // Handle this case.
    } else static if (!found!rotation && found!scaling) {
        // Handle this case.
    }
}

/// Draws a rectangle but it's missing the inside of lines. Currently just top left and bottom right corners.
void drawSplitRectangle(pair ul, pair lr, float legSize, float thickness, COLOR c)
	{
	// upper left
	al_draw_line(ul.x, ul.y, ul.x + legSize, ul.y, c, thickness); // horizontal
	al_draw_line(ul.x, ul.y, ul.x, ul.y + legSize, c, thickness); // vertical
	
	// lower right
	al_draw_line(lr.x, lr.y, lr.x - legSize, lr.y, c, thickness); // horizontal
	al_draw_line(lr.x, lr.y, lr.x, lr.y - legSize, c, thickness); // vertical
	}

/// Draw text using most common settings
void drawText(A...)(float x, float y, COLOR c, string formatStr, A a)
	{
	al_draw_text(g.font1, c, x, y, ALLEGRO_ALIGN_LEFT, format(formatStr, a).toStringz); 
	}

/// Draw text using most common settings
void drawTextCenter(A...)(float x, float y, COLOR c, string formatStr, A a)
	{
	al_draw_text(g.font1, c, x, y, ALLEGRO_ALIGN_CENTER, format(formatStr, a).toStringz); 
	}
	
/// Draw text with help of textHelper auto-indenting
void drawText2(A...)(float x, string formatStr, A a)
	{
	al_draw_text(g.font1, ALLEGRO_COLOR(0, 0, 0, 1), x, textHelper(), ALLEGRO_ALIGN_LEFT, format(formatStr, a).toStringz); 
	}	

/// Font Height = Ascent + Descent
int h(const ALLEGRO_FONT *f)
	{
	return al_get_font_line_height(f);
	}

/// Font Ascent
int a(const ALLEGRO_FONT *f)
	{
	return al_get_font_ascent(f);
	}

/// Font Descent
int d(const ALLEGRO_FONT *f)
	{
	return al_get_font_descent(f);
	}

//helper functions using universal function call syntax.
/// Return BITMAP width
int w(ALLEGRO_BITMAP *b)
	{
	return al_get_bitmap_width(b);
	}
	
/// Return BITMAP height
int h(ALLEGRO_BITMAP *b)
	{
	return al_get_bitmap_height(b);
	}
	
//2023
void drawBitmap(bitmap *b, pair pos, uint flags=0)
	{
	al_draw_bitmap(b, pos.x, pos.y, flags);
	}

void drawTintedBitmap(bitmap *b, COLOR tint, pair pos, uint flags=0)
	{
	al_draw_tinted_bitmap(b, tint, pos.x, pos.y, flags);
	}

/// How do we handle PARALLAX scrolling? We need a SCALE value. (vpair could include that if we want)
void drawBitmap(bitmap *b, vpair pos, uint flags=0) /// draw bitmap with implied viewport
	{
	al_draw_bitmap(b, 
		pos.r + IMPLIED_VIEWPORT.x - IMPLIED_VIEWPORT.ox, 
		pos.s + IMPLIED_VIEWPORT.y - IMPLIED_VIEWPORT.oy,
		flags);
	}

/// Same as al_draw_bitmap but center the sprite
/// we can also chop off the last item.
/// we could also throw an assert!null in here but maybe not for performance reasons.
void al_draw_centered_bitmap(ALLEGRO_BITMAP* b, float x, float y, int flags=0)
	{
	al_draw_bitmap(b, x - b.w/2, y - b.h/2, flags);
	}
	
/// Set texture target back to normal (the screen)
void al_reset_target() 
	{
	al_set_target_backbuffer(al_get_current_display());
	}

/// draw scaled bitmap but with a scale factor (simpler than the allegro API version)
void al_draw_scaled_bitmap2(ALLEGRO_BITMAP *bitmap, float x, float y, float scaleX, float scaleY, int flags=0)
	{
	al_draw_scaled_bitmap(bitmap, 0, 0, bitmap.w, bitmap.h, x, y, bitmap.w * scaleX, bitmap.h * scaleY, flags);
	}

void al_draw_center_rotated_bitmap(BITMAP* bmp, float x, float y, float angle, int flags)
	{
	al_draw_rotated_bitmap(bmp, bmp.w/2, bmp.h/2, x, y, angle, flags);
	}

void al_draw_center_rotated_tinted_bitmap(BITMAP* bmp, COLOR tint, float x, float y, float angle, int flags)
	{
	al_draw_tinted_rotated_bitmap(bmp, tint, bmp.w/2, bmp.h/2, x, y, angle, flags);
	}

// you know, we could do some sort of scoped lambda like thing that auto resets the target
/*
	DAllegro might already have that somewhere...
	
	foo();
	al_target(my_bitmap)
		{
		al_clear_to_color(...);
		al_draw_filled_rectangle(...);
		} // calls al_reset_target at end
	bar();

	al_target would be a class
		this

*/
//ALLEGRO_BITMAP* target, 

void al_target2(ALLEGRO_BITMAP* target, scope void delegate() func)
	{
	al_set_target_bitmap(target);
	func();
	al_reset_target();
	}
	
import std.stdio;
void test2()
	{
	ALLEGRO_BITMAP* bmp;
	al_target2(bmp, { al_draw_pixel(5, 5, ALLEGRO_COLOR(1,1,1,1)); });
	}

struct al_target()
	{
	this(ALLEGRO_BITMAP* target)
		{
		al_set_target(target);
		}
		
		//wheres the middle???
		
	~this()
		{
		al_reset_target();
		}
	}

/// Print variablename = value
/// usage because of D oddness:    
/// writeval(var.stringof, var);
void writeval(T)(string x, T y) 
	{
	writeln(x, " = ", y);
	}

/// Load a font and verify we succeeded or cause an out-of-band error to occur.
FONT* getFont(string path, int size)
	{
	import std.string : toStringz;
	ALLEGRO_FONT* f = al_load_font(toStringz(path), size, 0);
	assert(f != null, format("ERROR: Failed to load font [%s]!", path));
	return f;
	}

/// Load a bitmap and verify we succeeded or cause an out-of-band error to occur.
ALLEGRO_BITMAP* getBitmap(string path)
	{
	import std.string : toStringz;
	ALLEGRO_BITMAP* bmp = al_load_bitmap(toStringz(path));
	assert(bmp != null, format("ERROR: Failed to load bitmap [%s]!", path));
	return bmp;
	}

/// ported Gourand shading Allegro 5 functions from my old forum post
/// 	https://www.allegro.cc/forums/thread/615262
/// Four point shading:
void al_draw_gouraud_bitmap(ALLEGRO_BITMAP* bmp, float x, float y, COLOR tl, COLOR tr, COLOR bl, COLOR br)
	{
	ALLEGRO_VERTEX[4] vtx;
	float w = bmp.w;
	float h = bmp.h;

	vtx[0].x = x;
	vtx[0].y = y;
	vtx[0].z = 0;
	vtx[0].color = tl;
	vtx[0].u = 0;
	vtx[0].v = 0;

	vtx[1].x = x + w;
	vtx[1].y = y;
	vtx[1].z = 0;
	vtx[1].color = tr;
	vtx[1].u = w;
	vtx[1].v = 0;

	vtx[2].x = x + w;
	vtx[2].y = y + h;
	vtx[2].z = 0;
	vtx[2].color = br;
	vtx[2].u = w;
	vtx[2].v = h;

	vtx[3].x = x;
	vtx[3].y = y + h;
	vtx[3].z = 0;
	vtx[3].color = bl;
	vtx[3].u = 0;
	vtx[3].v = h;

	al_draw_prim(cast(void*)vtx, null, bmp, 0, vtx.length, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_FAN);
	}

/// Five points (includes center)
void al_draw_gouraud_bitmap_5pt(ALLEGRO_BITMAP* bmp, float x, float y, COLOR tl, COLOR tr, COLOR bl, COLOR br, COLOR mid)
	{
	ALLEGRO_VERTEX[6] vtx;
	float w = bmp.w;
	float h = bmp.h;

	//center
	vtx[0].x = x + w/2;
	vtx[0].y = y + h/2;
	vtx[0].z = 0;
	vtx[0].color = mid;
	vtx[0].u = w/2;
	vtx[0].v = h/2;

	vtx[1].x = x;
	vtx[1].y = y;
	vtx[1].z = 0;
	vtx[1].color = tl;
	vtx[1].u = 0;
	vtx[1].v = 0;

	vtx[2].x = x + w;
	vtx[2].y = y;
	vtx[2].z = 0;
	vtx[2].color = tr;
	vtx[2].u = w;
	vtx[2].v = 0;

	vtx[3].x = x + w;
	vtx[3].y = y + h;
	vtx[3].z = 0;
	vtx[3].color = br;
	vtx[3].u = w;
	vtx[3].v = h;

	vtx[4].x = x;
	vtx[4].y = y + h;
	vtx[4].z = 0;
	vtx[4].color = bl;
	vtx[4].u = 0;
	vtx[4].v = h;

	vtx[5].x = vtx[1].x; //end where we started.
	vtx[5].y = vtx[1].y;
	vtx[5].z = vtx[1].z;
	vtx[5].color = vtx[1].color;
	vtx[5].u = vtx[1].u;
	vtx[5].v = vtx[1].v;

	al_draw_prim(cast(void*)vtx, null, bmp, 0, vtx.length, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_FAN);
	}
	
	
/// al_draw_line_segment for pairs
void al_draw_line_segment(pair[] pairs, COLOR color, float thickness)
	{
	assert(pairs.length > 1);
	pair lp = pairs[0]; // initial p, also previous p ("last p")
	foreach(ref p; pairs)
		{
		al_draw_line(p.x, p.y, lp.x, lp.y, color, thickness);
		lp = p;
		}
	}
	
/// al_draw_line_segment for raw integers floats POD arrays
void al_draw_line_segment(T)(T[] x, T[] y, COLOR color, float thickness)
	{
	assert(x.length > 1);
	assert(y.length > 1);
	assert(x.length == y.length);

	for(int i = 1; i < x.length; i++) // note i = 1
		{
		al_draw_line(x[i], y[i], x[i-1], y[i-1], color, thickness);
		}
	}

/// al_draw_line_segment 1D
void al_draw_line_segment(T)(T[] y, COLOR color, float thickness)
	{
	assert(y.length > 1);

	for(int i = 1; i < y.length; i++) // note i = 1
		{
		al_draw_line(i, y[i], i-1, y[i-1], color, thickness);
		}
	}

/// al_draw_line_segment 1D
void al_draw_scaled_line_segment(T)(pair xycoord, T[] y, float yScale, COLOR color, float thickness)
	{
	assert(y.length > 1);

	for(int i = 1; i < y.length; i++) // note i = 1
		{
		al_draw_line(
			xycoord.x + i, 
			xycoord.y + y[i]*yScale, 
			xycoord.x + i-1, 
			xycoord.y + y[i-1]*yScale, 
			color, thickness);
		}
	}

/// al_draw_line_segment 1D
void al_draw_scaled_indexed_line_segment(T)(pair xycoord, T[] y, float yScale, COLOR color, float thickness, int index, COLOR indexColor)
	{
	assert(y.length > 1);

	for(int i = 1; i < y.length; i++) // note i = 1
		{
		if(i == index)
			{
			al_draw_line(
				xycoord.x + i, 
				xycoord.y + y[i]*yScale, 
				xycoord.x + i-1, 
				xycoord.y + y[i-1]*yScale, 
				indexColor, thickness*2);
			}else{
			al_draw_line(
				xycoord.x + i, 
				xycoord.y + y[i]*yScale, 
				xycoord.x + i-1, 
				xycoord.y + y[i-1]*yScale, 
				color, thickness);
			}
		}
	}

