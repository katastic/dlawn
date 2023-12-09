import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;
import allegro5.allegro_audio;
import allegro5.allegro_acodec;

import std.stdio;
import std.string;
import std.format;
import std.math;
import std.random;
import std.conv;
import std.traits;

import viewportsmod;
import g;
import objects;
import molto;

//mixin template grey(T)(T w)
	//{
	//COLOR(w, w, w, 1);
	//}

bool isWithin(T)(T val, T lowBound, T highBound) /// NOTE this range is inclusive [ ] range
	{
	if(val >= lowBound && val <= highBound)return true;
	return false;
	}

bool isWithin(pair val, pair lowBound, pair highBound) /// NOTE this range is inclusive [ ] range
	{
//	writeln(" - isWithin(T) -", val, " low:", lowBound, " high:", highBound);
	if(
		val.x >= lowBound.x && val.x <= highBound.x &&
		val.y >= lowBound.y && val.y <= highBound.y
		) return true;
	return false;
	}

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

// TODO: does this track viewport offset or not?!
void drawAngleHelper(baseObject o, viewport v, float angle, float distance, ALLEGRO_COLOR color)
	{
	float cx = cos(angle)*distance;
	float cy = sin(angle)*distance;
	al_draw_line(
		o.pos.x + v.x - v.ox, 
		o.pos.y + v.y - v.oy, 
		o.pos.x + cx + v.x - v.ox, 
		o.pos.y + cy + v.y - v.oy, 
		color, 1);
	}

float radToDeg(T)(T angle)
	{
	return angle/(2.0*PI)*360.0;
	}

float degToRad(T)(T angle)
	{
	return angle*(2.0*PI)/360.0;
	}
	
void testRad()
	{
	for(int i = 0; i < 10; i++)
		{
		double x = -2*PI -.5 + .1*i;
		writeln(x, " ", wrapRad(x));
		}
	}
	
// Angle helper routines
// ----------------------------------------------------------------------------
T wrapRad(T)(T angle)
	{
	if(angle >= 0)
		angle = fmod(angle, 2.0*PI);
	else
		angle += 2.0*PI;
		angle = fmod(angle, 2.0*PI);
			// everyone does this. What if angle is more than 360 negative though?
			// it'll be wrong. though a few more "hits" though this function and it'll be fixed.
			// otherwise, we could do a while loop but is that slower even when we don't need it?
			// either find the answer or stop caring.
	
	////	writeln(fmod(angle, 2.0*PI).radToDeg);
	//while(angle > 2*PI)angle -= 2*PI;
	//while(angle < 0)angle += 2*PI;
	return angle;
	}

void wrapRadRef(T)(ref T angle)
	{
	angle = fmod(angle, 2.0*PI);
	}



float flip(float a) // we could make angles their own typedef
	{
	return (a + degToRad(180)).wrapCircle;
	}


/// angleTo:		angleTo (This FROM That)
///
/// Get angle to anything that has an x and y coordinate fields
/// 	Cleaner:	float angle = angleTo(this, g.world.units[0]);
///  	Verses :	float angle = atan2(y - g.world.units[0].y, x - g.world.units[0].x);
///
///		2.0 version allows anything with a .pos as well in either argument
float angleTo(T, U)(T t, U u) /// from This (t) to That (u)
	{
	static if(__traits(compiles, u.x - t.x))		// xy only
		return atan2(u.y - t.y, u.x - t.x).wrapRad;
	else static if(__traits(compiles, u.pos.x - t.pos.x)) // pos only
		return atan2(u.pos.y - t.pos.y, u.pos.x - t.pos.x).wrapRad;
	else static if(__traits(compiles, u.x - t.pos.x)) // t pos
		return atan2(u.y - t.pos.y, u.x - t.pos.x).wrapRad;
	else static if(__traits(compiles, u.pos.x - t.x)) // u pos
		return atan2(u.pos.y - t.y, u.pos.x - t.x).wrapRad;
	assert(false, "fuck");

/// 	note this is just an expansion of this:
///	return atan2(_this.y - fromThat.y, _this.x - fromThat.x).wrapRad;

/// this allows this: 
/// 	float a = angleTo(target.pos, this.pos);
/// to become this:
/// 	float a = angleTo(target, this);
/// or any variation thereof. When not stated otherwise (e.g. .vel ) we assume 
/// .pos.  We can "alias this" the object but that could have other unintended 
/// consequences in other parts of the API.
	
	}

float angleDiff(T)(T _thisAngle, T toThatAngle)
	{
	return abs(_thisAngle - toThatAngle); //is this a valid formula compared to below?
	}

/// modified from https://stackoverflow.com/questions/28036652/finding-the-shortest-distance-between-two-angles
float angleDiff2( double angle1, double angle2 )
	{
	//δ=(T−C+540°)mod360°−180°
	return (angle2 - angle1 + 540.degToRad) % 2*PI - PI;
	}

///		2.0 version allows anything with a .pos as well in either argument
float distanceTo(T, U)(T t, U u)
	{
	static if(__traits(compiles, u.x - t.x))		// xy only
		return sqrt((u.x - t.x)^^2 + (u.y - t.y)^^2);
	else static if(__traits(compiles, u.pos.x - t.pos.x)) // pos only
		return sqrt((u.pos.x - t.pos.x)^^2 + (u.pos.y - t.pos.y)^^2);
	else static if(__traits(compiles, u.pos.x - t.x))	// u is pos only
		return sqrt((u.pos.x - t.x)^^2 + (u.pos.y - t.y)^^2);
	else static if(__traits(compiles, u.x - t.pos.x)) // t is pos only
		return sqrt((u.x - t.pos.x)^^2 + (u.y - t.pos.y)^^2);
	assert(false, "fuck");
	} // TODO: Confirm this works for all permutations as intended.
	
float distance(float x, float y)
	{
	return sqrt(x*x + y*y);
	}

//	writeln(array.length); // 10, h
//	writeln(array[0].length); // 5, w

// Graphical helper functions
//=============================================================================
/// For bitmap culling. Is this point inside the screen?
bool isInsideScreen(float x, float y, viewport v) 
	{
	if(	x > 0 && x < v.w + v.ox && 
		y > 0 && y < v.h + v.oy)
		{return true;} else{ return false;}
	}

/// Same as above but includes a bitmaps width/height instead of a single point
bool isWideInsideScreen(float x, float y, ALLEGRO_BITMAP* b, viewport v) 
	{
	if(	x >= -b.w/2 && x - b.w/2 < v.w + v.ox &&
		y - b.h/2 >= -b.w/2 && y < v.h + v.oy)
		{return true;} else{ return false;} //fixme
	}

bool isInsideRectangle(pair pos, rect b) 
	{
	with(pos)
		{
		if(		x >= -b.w/2 		&& 
				x - b.w/2 < b.w 	&&
				y - b.h/2 >= -b.w/2 &&
				y < b.h
				 )
			{return true;} else{ return false;} //fixme
		}
	}
	
bool isInsideRadius(pair p, pair q, float radius) 
	{
	import std.math : sqrt;
	
	if(sqrt((q.x - p.x)^^2 + (q.y - p.y)^^2) < radius)
		{
		return true;
		}else return false;
		
//	if(x >= -b.w/2 && x - b.w/2 < v.w && y - b.h/2 >= -b.w/2 && y < v.h)
	//	{return true;} else{ return false;} //fixme
	}

/*
//inline this? or template...
void draw_target_dot(pair xy)
	{
	draw_target_dot(xy.x, xy.y);
	}
*/
void drawTargetDot(float x, float y)
	{
	drawTargetDot(to!(int)(x), to!(int)(y));
	}

void drawTargetDot(int x, int y)
	{
	al_draw_pixel(x + 0.5, y + 0.5, al_map_rgb(0,1,0));

	immutable r = 2; //radius
	al_draw_rectangle(x - r + 0.5f, y - r + 0.5f, x + r + 0.5f, y + r + 0.5f, al_map_rgb(0,1,0), 1);
	}

/// For each call, this increments and returns a new Y coordinate for lower text.
int textHelper(bool doReset=false)
	{
	static int number_of_entries = -1;
	
	number_of_entries++;
	immutable int text_height = 20;
	immutable int starting_height = 20;
	
	if(doReset)number_of_entries = 0;
	
	return starting_height + text_height*number_of_entries;
	}

// Helper functions
//=============================================================================

bool percent(float chance)
	{
	return uniform!"[]"(0.0, 100.0) < chance;
	}

bool flipCoin() => cast(bool)uniform!"[]"(0,1); //return a 0 or 1 result

// TODO Fix naming conflict here. This series returns the value. The other works by 
// reference
/+
	capLow		(non-reference versions)
	
		capRefLow?	(reference versions)
		rCapLow	
		refCapLow
	
	also is cap ambiguous? I like that it's smaller than 'clamp'
		cap:
			verb
				2.provide a fitting climax or conclusion to.
+/

// do these need to be REF parameters?
T capReset(T)(T val, T max, T resetValue=0) /// If val > max, val = resetValue=0
	{
	return (val <= max) ? val : resetValue;
	}

T capHigh(T)(T val, T max)
	{
	if(val > max)
		{
		return max;
		}else{
		return val;
		}
	}	
// Ditto.
T capLow(T)(T val, T max)
	{
	if(val < max)
		{
		return max;
		}else{
		return val;
		}
	}	
// Ditto.
T capBoth(T)(T val, T min, T max)
	{
	assert(min < max);
	if(val < max)
		{
		val = max;
		}
	if(val > min)
		{
		val = min;
		}
	return val;
	}	

/// For angles. If val is above max, subtract max until it is below max
void wrapHigh(T)(ref T val, T max){
	while(val > max)val -= max;
	}
/// For angles. If val is below min, add min until it is above min
void wrapLow(T)(ref T val, T min){
	while(val < min)val += min;
	} // BUT WHAT IF MIN IS ZERO!?!?! and does MAX even make sense?!
	
/// For angles. Keep within range
void wrapBoth(T)(ref T val, T min, T max){
	while(val > max)val -= max;
	while(val < min)val += min;
	}

/// For angles. Keep within range. Method chaining(?) version.
T wrapBoth(T)(T val, T min, T max){
	while(val > max)val -= max;
	while(val < min)val += min;
	return val;
	}

/// For angles. Keep within range. Method chaining(?) version.
/// if we had an angle class we could just name it .wrap or have it automatically wrap every time its set 
T wrapCircle(T)(T val){
	T pi2 = degToRad(360);
	while(val < -pi2)val += pi2;
	while(val >  pi2)val -= pi2;
	return val;
	}

// can't remember the best name for this. How about clampToMax? <-----
void clampHigh(T)(ref T val, T max)
	{
	if(val > max)
		{
		val = max;
		}
	}	

void clampLow(T)(ref T val, T min)
	{
	if(val < min)
		{
		val = min;
		}
	}	

void clampBoth(T)(ref T val, T min, T max)
	{
	assert(min < max);
	if(val < min)
		{
		val = min;
		}
	if(val > max)
		{
		val = max;
		}
	}	

// <------------ Duplicates??
void cap(T)(ref T val, T low, T high)
	{
	if(val < low){val = low; return;}
	if(val > high){val = high; return;}
	}

// Cap and return value.
// better name for this? 
pure T cap_ret(T)(T val, T low, T high)
	{
	if(val < low){val = low; return val;}
	if(val > high){val = high; return val;}
	return val;
	}
