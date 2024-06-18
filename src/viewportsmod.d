import objects;
import g;
import helper;
import molto;
import datajack;

class viewport{
//	unit attachedUnit;

	bool isAttached=false;
	bool isDudeAttached=false; //FIXME
	bool isConfinedToMap=false;
	unit* attachedObject;
	BaseObject* attachedDude;//FIXME
	
	bool seekFormula(pair position, pair goal, pair velocity){
		if(goal.x > ox)ox--;
		if(goal.y > oy)oy++;
		if(goal.x < ox)ox++;
		if(goal.y < oy)oy--;
		return false; // return true if we're done
		}
		
	void attach(unit* o){
		isAttached = true;
		attachedObject = o;
		}

	void attach(BaseObject* o){ //FIXME
		isDudeAttached = true;
		attachedDude = o;
		}

	/// Screen coordinates
	int x;
	int y;
	int w; /// viewport width
	int h; /// viewport height
	
	/// Camera position
	float ox; /// offset_x, how much scrolling. subtracted from drawing calls.
	float oy; /// offset_y
	float zoom = 1.0;
	
	float vx; //for free floating camera (keeps moving after you die)
	float vy;
	
	int* screen_w; // mirror of g.screen_w 
	int* screen_h; // used anywhere?? are these even set or just left null right now?

	@disable this();

	this(int _x, int _y, int _w, int _h, float _ox, float _oy){
		x = _x;
		y = _y;
		w = _w;
		h = _h;
		ox = _ox;
		oy = _oy;
		}
		
//	void attach(unit u)
	//	{//
	//	attachedUnit = u;
		//isAttached = true;
		//}
		
	void onTick(){
//	import std.stdio : writeln;
		if(attachedObject is null)isAttached = false;
		if(isAttached){
			unit* ao = attachedObject;
//			writeln(pair(ao.pos, w/2, h/2), " vs (", ox, ",", oy, ")");
//			seekFormula(pair(x,y), attachedObject.pos, pair(0,0));
			ox = (attachedObject.pos.x - w/2);
			oy = (attachedObject.pos.y - h/2);
//			writeln("now (", ox, ",", oy, ")");
			if(isConfinedToMap)
				{
				clampLow(ox, 0);
				clampLow(oy, 0);
	//			if(ox + w > g.world.map2.size.w*TILE_W)clampHigh(ox, g.world.map2.size.w*TILE_W - w); // fixme?
	//			if(oy + h > g.world.map2.size.h*TILE_W)clampHigh(oy, g.world.map2.size.h*TILE_W - h);
				}
			}
		if(isDudeAttached){
			BaseObject* ao = attachedDude;
			ox = (attachedDude.pos.x - w/2);
			oy = (attachedDude.pos.y - h/2);
			if(isConfinedToMap){
				clampLow(ox, 0);
				clampLow(oy, 0);
				}
			}
		}
	}
