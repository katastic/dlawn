import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import std.conv;
import std.random;
import std.stdio;
import std.math;
import std.string;
import std.algorithm : remove;

import console;
import molto;
import g;
import helper;
import viewportsmod;
import particles;
import guns;
import bulletsmod;
import atlasmod;

import datajack; // gamemodule

// we should organize this at some point. game mechanic constants.
float STAT_WALK_SPEED = 1245;
float STAT_RUN_SPEED  = 1245;
float STAT_JUMP_VEL = 123;
float STAT_GRAVITY_ACCEL = 235;
float STAT_ACCEL = .1;
float STAT_ROTSPEED = degToRad(10);

float stat_meteor_fallspeed = 12_241;
float stat_meteor_explosion_diameter = 234;
float stat_meteor_damage = 23;
// also combined meteors

import toml;
class objectHandler /// load a MAP format full of objects. could be in objects.d
	{
	unit data; //baseobject, or unit? or (T)
	this(string path)
		{
		load(path);
		}
	
	void load(string path)
		{
		// https://github.com/dlang-community/toml
		// https://toml.dpldocs.info/v2.0.1/toml.toml.TOMLValue.html
		import std.file : read;
		auto data = parseTOML(cast(string)read(path));
		//writeln(data["objects"]);
//		pragma(msg, typeof(data["objects"]));
		foreach(o;data["objects"].array)
			{
			writeln(o); // how do we parse object types? This is a pretty specialized handler then?
			}
//		import core.stdc.stdlib : exit; exit(0);
		}
	void save(){}
	}
	
	/+
	stuff
	
	- sun casts scorching rays
	- water, rain, snow, ice
	- trees that burn, boulders (harvest them?), grass (can we animate it?)
	- land animals/monsters, flying birds. all kinds of animals that start exploding into gibs when the asteroids start hitting.
	- undergruond monstters
	
	- does it start normalish and the armeggedon only starts after a few minutes?
		[asteroid is coming to earth. first it starts with day tehn heavy monsoon, then fire and asteroids?]
		
	- do we support [ropes] somehow for going down, and add fall damage?
+/
/*
	Teams
		0 - Neutral		(asteroids. unclaimed planets?)
		1 - Player 1? (if we support real teams, then its whatever team it is)

name clashes
	- we cannot use "object" since that's a D keyword. 
	- we also can't use "with" for onCollision(baseObject with)
*/

class item : baseObject
	{
	bool isInside = false; //or isHidden? Not always the same though...
	bool isOnDropCooldown = false;
	timeout cooldown;	
	gravityStyle!item moveStyle; // this needs corrected API

	this(uint _team, pair _pos, pair _vel, ALLEGRO_BITMAP* b)
		{
		team = _team;
		super(_pos, _vel, b);
		writeln("ITEM EXISTS BTW at ", pos.x, " ", pos.y);
		moveStyle = new gravityStyle!item(this); // this needs corrected API. obviously sleep deprived code.
		}
		
	void onMapCollision(DIR d)
		{
		vel = 0;
		}
		
	void onObjectCollision(baseObject by)
		{
		}
		
	void goInside(dude d)
		{
		isInside = true;
		d.items ~= this;
		}
		
	void goOutside() // but who handles velocity, etc when thrown?
		{
		if(isInside)
			{
			isInside = false;
			th.addEdgeTimeout(cast(int)(60*1.5), &callback);
			isOnDropCooldown = true;
			con.log("item - setup pickup cooldown");
			}
		}
		
	void callback()
		{
		con.log("item - we got callback function from timeout");
		isOnDropCooldown = false;
		}
		
	override bool draw(viewport v)
		{
		if(!isInside)
			{
			super.draw(v);
			return true;
			}
		return false;
		}
		
	override void onTick()
		{
		if(!isInside)
			{
			//pos += vel;
			//vel.x *= .99; 
			//vel.y += .025; 
			moveStyle.onTick();
			}
		}
	}
	
/+
class unit : baseObject // WARNING: This applies PHYSICS. If you inherit from it, make sure to override if you don't want those physics.
	{
	float maxHP=100.0; /// Maximum health points
	float hp=100.0; /// Current health points
	float ap=0; /// armor points (reduced on hits then armor breaks)
	float armor=0; /// flat reduction (or percentage) on damages, haven't decided.
	int myTeamIndex=0;
	bool isPlayerControlled=false;
	float weapon_damage = 5;

	void applyV(float applyAngle, float _vel)
		{
		vel.x += cos(applyAngle)*_vel;
		vel.y += sin(applyAngle)*_vel;
		}

	override void onTick()
		{
		pos += vel;
		}
		
	void onCollision(baseObject who)
		{
		}
		
	void onHit(bullet b) //projectile based damage
		{
		// b.myOwner
		}

	void onCrash(unit byWho) //for crashing into each other/objects
		{
		}

	void doAttackStructure(structure s)
		{
		s.onHit(this, weapon_damage);
		}

	void doAttack(unit u)
		{
		u.onAttack(this, weapon_damage);
		}
		
	void onAttack(unit from, float amount) /// I've been attacked!
		{
		hp -= amount;
		}
	
	this(uint _teamIndex, float _x, float _y, float _vx, float _vy, ALLEGRO_BITMAP* b)
		{
		myTeamIndex = _teamIndex; 
		super(pair(_x, _y), pair(_vx, _vy), b);
		}

	override bool draw(viewport v)
		{
		super.draw(v);
		
		drawHealthBar(pos.x, pos.y - bmp.w/2, v, hp, 100);		
		return true;
		}
	}
+/		
class movementStyle // NOT USED?
	{
	pair* pos;
	pair* vel;
	
	this(ref pair _pos, ref pair _vel)
		{
		pos = &_pos;
		vel = &_vel;
		}
	
	void onTick(){}
	}
	
class fallingStyle(T)  /// Constant velocity "arcade-style" falling object
	{
	bool isColliding=true; // does it collide with objects  NYI
	T myObject;
	this(T d)
		{
		myObject = d;
		}

	void onTick()
		{
		with(myObject)
			{
			//writeln(*pos, " ", *vel);
			pos += vel;
//			writeln("Meteor: ", pos, " ", vel);
			
			foreach(o; g.world.units)
				{
				if(isInsideRadius(pos, o.pos, 20))
					{
					onObjectCollision(o);
					break;
					}
				}
				
			if(!g.world.map2.isValidMovement(pos))onMapCollision(DIR.DOWN);
			}
		}
	}
	
class gravityStyle(T)  /// Falling object gravity
	{
	bool isColliding=true; // does it collide with objects  NYI
	T myObject;
	this(T d)
		{
		myObject = d;
		}

	void onTick()
		{
		with(myObject)
			{
			//writeln(*pos, " ", *vel);
			pos += vel;
			vel.y += .1;
//			writeln("Meteor: ", pos, " ", vel);
			
			foreach(o; g.world.units)
				{
				if(isInsideRadius(pos, o.pos, 20))
					{
					onObjectCollision(o);
					break;
					}
				}
				
			if(!g.world.map2.isValidMovement(pos))onMapCollision(DIR.DOWN);
			}
		}
	}

class bigMeteor : meteor	
	{
	this(pair _pos)
		{
		super(_pos);
		bmp = bh["bigasteroid"];
		}
	
	override void onMapCollision(DIR hitDirection)
		{
		ipair p;
		p.i = cast(int)pos.x/TILE_W;
		p.j = cast(int)pos.y/TILE_W;
		with(p)
		with(g.world.map2)
		if(isInsideMap(p))
			{
			g.world.map2.drawCircle(pos, 2, 0);
//			if(data[p.i][p.j] > 0)data[p.i][p.j]--;
			}
		
		with(this)
		{
			{
			auto m = new splinterMeteor(pos, pair(2, -3));
			m.isSpawn = true;
			g.world.objects ~= m;
			}
			{
			auto m = new splinterMeteor(pos, pair(0, -3));
			m.isSpawn = true;
			g.world.objects ~= m;
			}
			{
			auto m = new splinterMeteor(pos, pair(-2, -3));
			m.isSpawn = true;
			g.world.objects ~= m;
			}
		}
		spawnExplosion();
//			spawnSmoke();
		//isDead = true;
		if(!isSpawn)respawn();
		}
	}
	
class meteor : baseObject
	{
	fallingStyle!meteor moveStyle; // this cannot be a pointer for some reason? it's a reference type already though?

	this(pair _pos)
		{
		import std.random : uniform;
		vel = pair(-3 + uniform!"[]"(-1,1), 3);
		super(_pos, vel, bh["asteroid"]);
		moveStyle = new fallingStyle!meteor(this);
		flipHorizontal = cast(bool)uniform!"[]"(0, 1);
		flipVertical = cast(bool)uniform!"[]"(0, 1);
		}

	this(pair _pos, pair _vel, bool _isSpawn=true)
		{
		import std.random : uniform;
		this(_pos);
		vel = pair(_vel.x + uniform!"[]"(-1,1), _vel.y);
		isSpawn = _isSpawn;
		}

	void spawnSmoke()
		{
		float cvx = cos(ang)*0;
		float cvy = sin(ang)*0;
		g.world.particles ~= particle(pos.x, pos.y, vel.x + cvx, vel.y + cvy, 0, 100);
		}

	void spawnExplosion()
		{
		float cvx = cos(ang)*0;
		float cvy = sin(ang)*0;
		auto p = particle(pos.x, pos.y, 0, 0, 0, 100, bh["explosion"]);
//		p.isGrowing = true;
		g.world.particles ~= p;
		}
		
	final void respawn()
		{
		import std.random : uniform;
		pos.x = uniform(0, g.world.map2.w*TILE_W-20);
		pos.y = 0;
		vel.x = uniform(-3, 3);
		}

	void onObjectCollision(baseObject by)
		{
//		isDead = true;
//		con.log("onObjectCollision at %s".format(pos));
		spawnSmoke();
		respawn();
		by.onHit(this, 1);
		}

	void onMapCollision(DIR hitDirection)
		{
		ipair p;
		p.i = cast(int)pos.x/TILE_W;
		p.j = cast(int)pos.y/TILE_W;
		with(p)
		with(g.world.map2)
		if(isInsideMap(p))
			{
			if(data[p.i][p.j] > 0)data[p.i][p.j]--;
			}
		spawnExplosion();
//			spawnSmoke();
		//isDead = true;
		if(!isSpawn)
			respawn();
		else
			isDead = true;
		}
	
	override void onTick()
		{
		if(moveStyle)moveStyle.onTick();
		}
	}
	
class splinterMeteor : baseObject
	{
	gravityStyle!splinterMeteor moveStyle; // this cannot be a pointer for some reason? it's a reference type already though?

	this(pair _pos)
		{
		import std.random : uniform;
		vel = pair(-3 + uniform!"[]"(-1,1), 3);
		super(_pos, vel, bh["asteroid"]);
		moveStyle = new gravityStyle!splinterMeteor(this);
		flipHorizontal = cast(bool)uniform!"[]"(0, 1);
		flipVertical = cast(bool)uniform!"[]"(0, 1);
		}

	this(pair _pos, pair _vel, bool _isSpawn=true)
		{
		import std.random : uniform;
		this(_pos);
		vel = pair(_vel.x + uniform!"[]"(-1,1), _vel.y);
		isSpawn = _isSpawn;
		}

	void spawnSmoke()
		{
		float cvx = cos(ang)*0;
		float cvy = sin(ang)*0;
		g.world.particles ~= particle(pos.x, pos.y, vel.x + cvx, vel.y + cvy, 0, 100);
		}

	void spawnExplosion()
		{
		float cvx = cos(ang)*0;
		float cvy = sin(ang)*0;
		auto p = particle(pos.x, pos.y, 0, 0, 0, 100, bh["explosion"]);
//		p.isGrowing = true;
		g.world.particles ~= p;
		}
		
	final void respawn()
		{
		import std.random : uniform;
		pos.x = uniform(0, g.world.map2.w*TILE_W-20);
		pos.y = 0;
		vel.x = uniform(-3, 3);
		}

	void onObjectCollision(baseObject by)
		{
//		isDead = true;
		//con.log("onObjectCollision at %s".format(pos));
		spawnSmoke();
		respawn();
		by.onHit(this, 1);
		}

	void onMapCollision(DIR hitDirection)
		{
		ipair p;
		p.i = cast(int)pos.x/TILE_W;
		p.j = cast(int)pos.y/TILE_W;
		with(p)
		with(g.world.map2)
		if(isInsideMap(p))
			{
			if(data[p.i][p.j] > 0)data[p.i][p.j]--;
			}
		spawnExplosion();
//			spawnSmoke();
		//isDead = true;
		if(!isSpawn)
			respawn();
		else
			isDead = true;
		}
	
	override void onTick()
		{
		if(moveStyle)moveStyle.onTick();
		}
	}

/+
	we could do a component system for this movement to make it more "engine acceptable"?
		We could ALSO have sub-versions of these components [see variations in notes below]

	In this case, we're doing a Wall2D (as opposed to topdown2D) pixel walker with 
	specific jump velocity characteristics. 

	- Fall if empty space below
	- while(onGround) 
		- Hold left, right to walk a [constant] direction 		(we can have acceleration too)
		- if blocked pixels in that direction, stop.
			- BUT if empty pixel ABOVE (-1 in Y direction), we simply move up a pixel to follow the terrain.

		Jumping modes:
			[fixed arc] Clonk. If on ground, we can launch at a fixed velocity [that we now HOLD regardless of user input].
			[air control] Mario? etc. Has arc, but some air control. Also variable jump height. 

	I'm having trouble enumerating it all into specifics. For example, we can have 
		- constant acceleration vs linear acceleration
		- various jumping algorithms
		- various collision with objects/ground physics. [bouncing vs not, slowing down friction rate when you let go of controls]
		
	One thing we could do is attempt to model specific known things and analyze them:
		- Mario
		- Sonic
		- Crappy DOS platformer games.
		
	If we can come up with either pixels, or some sort of nondimensional value
	 based on pixels/screen_size to measure velocities across different systems 
	 it might be easier to mathematically quantify them. 
	 
	 Hilariously, I was working on testing component system DIRECTLY above this
	 comment for Meteor and forgot/didn't notice it.
+/	
/+
	addition note: Instead of giving a whole [this] object, we may want a more 
	specific subset of data to interact with. But that will complicate the code
	further so it's easiest just to "not be an idiot" and only touch stuff you
	should.
+/
class wall2dStyle  // how do we integrate any flags with object code?
	{
	dude myObject;
	bool keepMoving=false;
	
	// if we do an alias this=myObject can we get rid of the with() statements internally?
	alias myObject this;
	//holy shit it works, however it may may shred the EXTERNAL API
	// since anyone accessing us can then... access themself... again...

	// https://forum.dlang.org/thread/emixkjutxnnrplaziwkj@forum.dlang.org
	// "classes are already ref so don't add a ref"
	this(dude _myObject)//ref pair _pos, ref pair _vel)
		{
		myObject = _myObject;
		}

	void onTick()
		{
		DIR isAnyCollision = DIR.NONE;
		with(myObject)
		with(g.world.map2) // isValidMovement
			{		
			// Horizontal tests
			// --------------------------------------------------------------
			if(vel.x < 0 && !isValidMovement(pair(pos, -1, 0)))  //if we can't move left
				{
				if(isValidMovement(pair(pos, -1, -1))) // what about if we move up one pixel?
					{
					if(isDebugging)debugString ~= "1 ";
//					pos.y--;  WHY does this make us freeze?!?!
					}else{
					if(isDebugging)debugString ~= "2 ";
					vel.x = 0;
					isAnyCollision = DIR.LEFT; // we might want to call "the right one" after we're completely done.
					}
				}

			if(vel.x > 0 && !isValidMovement(pair(pos, 1, 0))) //if we can't move right
				{
				if(isValidMovement(pair(pos, 1, -1))) // what about if we move up one pixel?
					{
					if(isDebugging)debugString ~= "3 ";
//					pos.y--;  WHY does this make us freeze?!?!
					}else{
					if(isDebugging)debugString ~= "4 ";
					vel.x = 0;
					isAnyCollision = DIR.RIGHT; 
					}
				}

			// other tests
			// --------------------------------------------------------------
			if(!isValidMovement(pair(pos, 0, -1))) // If blocked above
				{
				if(vel.y < 0)vel.y = 0;
				pos.y++;
				isAnyCollision = DIR.UP;
				}
	
			if(isValidMovement(pair(pos, 0, 1))) // If clear below, apply gravity
				{
				isFalling = true;
				vel.y += .1; // Apply gravity
				}else{
				isFalling = false;
				isAnyCollision = DIR.DOWN;
				}

			if(isValidMovement(pair(pos, vel.x, vel.y))) // If we can move, move.
				{
				pos += vel;
				isGrounded = false;
				}else{ // if we cannot move at all
				isGrounded = true;
				vel.y = 0;
				// this is where we should check to see if we can move up a pixel. not just blindly move up though.
				if( (vel.x < 0 && isValidMovement(pair(pos, -1, -1))) || 
					(vel.x > 0 && isValidMovement(pair(pos, -1,  1))))pos.y--; 
				}

			if(!isValidMovement(pair(pos, vel.x, 0))) /// If we can move horizontally, update facing direction
				{
//				con.log("ahhhh");
				if(vel.x < 0)isAnyCollision = DIR.LEFT;
				if(vel.x > 0)isAnyCollision = DIR.RIGHT;
				}
			
			if(isAnyCollision != DIR.NONE)
				{
				mapCollision(isAnyCollision);
				}
			}
			
		if(keepMoving)
			{
			if(facingRight)vel.x = 2f; else vel.x = -2f;
			}
		
		isMoving = (!vel.x.isZero) ? true : false;
		}

	void actionUp()
		{
		with(myObject)
		if(!isFalling)
			{
			vel.y = -3;
			if(facingRight)vel.x = 4f; else vel.x = -4f;
			}
		}
			
	void actionDown(){with(myObject)if(!isFalling)vel.x = -0;}
	void actionLeft(){with(myObject)if(!isFalling)vel.x = -4f;}
	void actionRight(){with(myObject)if(!isFalling)vel.x = 4f;}
	}

class cow : dude
	{
	this(pair _pos)
		{
		super(_pos);
		bmp = bh["cow"];
		facesVelocity = true;
		vel.x = 2f;
		moveStyle.keepMoving = true;
		}
		
	override void mapCollision(DIR hitDirection)
		{
		if(hitDirection == DIR.LEFT)
			{
//			con.log("AI switching right");
			vel.x = 2f;
			facingRight = true;
			}

		if(hitDirection == DIR.RIGHT)
			{
//			con.log("AI switching left");
			vel.x = -2f;
			facingRight = false;
			}
		}
	}

class monster : dude // wait, didn't we already start this with cow?
	{
	this(pair _pos)
		{
		super(_pos);
		}
	}

class aicontroller
	{
	dude myObject;
	
	this(dude _myObject)
		{
		myObject = _myObject;
		}
	
	void onTick()
		{
		with(myObject)
			{
			if(g.world.units[0].pos.x < pos.x && percent(50))actionLeft();
			if(g.world.units[0].pos.x > pos.x && percent(50))actionRight();
			if(g.world.units[0].pos.y < pos.y && percent(10))actionUp();
			}
		}
	// ???
	}

class dude : baseObject /// this is the new Unit class until we rename them, old unit is mostly just for old unported ode comparison
	{
	wall2dStyle moveStyle; // this cannot be a pointer for some reason? it's a reference type already though?
	aicontroller ai; //nyi
	
	bool usingAI = false;
	bool isMoving = false;
	bool isFalling = true;
	bool isGrounded = false;
	bool isJumping = false;
	bool facingRight = false;
	bool facesVelocity = false; /// do we automatically flip the bitmap to face the velocity direction?
	
	float facingVel() /// Helper function returns horizontal velocity sign (-1 left, +1 right) for multiplying velocities
		{
		if(facingRight)return 1.0;
		return -1.0;
		}
	
	this(pair _pos)
		{			
		moveStyle = new wall2dStyle(this);
		super(_pos, pair(0, 0), bh["dude"]);
		ai = new aicontroller(this);
		}
		
	import worldmod : world_t;
	void testCreateItems(world_t w) /// called by world_t
		{
		item i = new item(0, pos, vel, bh["carrot"]); // we could use pos(0,0) or negative, for inside items so they get pruned quickly from tests. or just test "isinside" i guess.
		i.isInside = true;
		items ~= i;
		w.items ~= i; //world needs to finish setting up before we can reference it! Or send a ref/pointer in args.
		}

	void scanForItemsToPickup() // do we do this all the time? Do we speed this up with spatial indexing? Do we fire this off periodically?
		{
		foreach(i; g.world.items)
			{
			if(isInsideRadius(this.pos, i.pos, 10) && !i.isInside && !i.isOnDropCooldown)
				{
				import std.format;
				string temp = format("%s found item %s!", this, i);
				con.log(temp);
				i.isInside = true;
				items ~= i;
				break;
				}
			}
		}

	void mapCollision(DIR hitDirection)
		{
		}

	// originally a copy of structure.draw
	override bool draw(viewport v)
		{
		// we draw RELATIVE to planet.xy, so no using baseObject.draw
		// TODO how do we rotate angle from center of planet properly? Or do we even need that?
		float cx=pos.x + v.x - v.ox;
		float cy=pos.y + v.y - v.oy;
//		if(cx < 0 || cx > SCREEN_W || cy < 0 || cy > SCREEN_H)return false;

		al_draw_filled_circle(cx, cy, 20, COLOR(0,1,0,.5));
		al_draw_center_rotated_bitmap(bmp, cx, cy, 0, !facingRight);
		
		debugString ~= format("%.1f ", hp);
		
		if(debugString != "")
			drawTextCenter(cx, cy - bmp.w, white, debugString);
		
		debugString = ""; // reset at end
		return true;
		}
	
	override void actionUp(){moveStyle.actionUp();}
	override void actionDown(){moveStyle.actionDown();}
	override void actionLeft(){moveStyle.actionLeft(); facingRight = false;}
	override void actionRight(){moveStyle.actionRight(); facingRight = true;}

	item[] items;

	bool hasItem()
		{
		return items.length > 0;
		}
	
	override void actionFire()
		{
		con.log("item.actionFire");
//		if(moveStyle.isActionAvailable)
		if(hasItem())throwItem();
		}
		
	void throwItem()
		{
		assert(hasItem());
		// "items[0].goOutside()"
//		items[0].isInside = false;
		items[0].goOutside(); // handle data structure stuff
		items[0].pos = pos;
		items[0].vel = pair(vel, 1*facingVel(), -1);
		items = items.remove(0); //I release you, my child!
		con.log("I release you!");
		}
	
	void spawnSmoke(float offsetx, float offsety)
		{
		float cvx = cos(ang)*0;
		float cvy = sin(ang)*0;
		g.world.particles ~= particle(pos.x + offsetx, pos.y + offsety, vel.x + cvx, vel.y + cvy, 0, 100);
		}
	
	override void onTick()
		{
		if(usingAI)ai.onTick();
		moveStyle.onTick();
		if(facesVelocity)
			{
			facingRight = (vel.x > 0) ? true : false;
			}
		if(isGrounded && isMoving)spawnSmoke(0, bmp.w/4);
		scanForItemsToPickup();
		}
	}
	
class structure : baseObject
	{
	immutable float maxHP=500.0;
	float hp=maxHP;
	int level=1; //ala upgrade level
	int team=0;
	int direction=0;
	immutable int countdown_rate = 200; // 60 fps, 60 ticks = 1 second
	int countdown = countdown_rate; // I don't like putting variables in the middle of classes but I ALSO don't like throwing 1-function-only variables at the top like the entire class uses them.

	this(float x, float y, ALLEGRO_BITMAP* b)
		{
		super(pair(x, y), pair(0, 0), b);
		writeln("we MADE a FAKKAN structure. @ ", x, " ", y);
	// this CRASHES. I'm not sure why, players should exist by now but doesn't. Almost like it's not allocated yet.
	//	assert(g.world.players[0] !is null);
	//	g.world.players[0].money -= 250;
//		assert(p !is null); // this works fine. wtf.
//		p.money -= 250;
		}

	void onHit(unit u, float damage)
		{
		hp -= damage;
		}
	}

/// NO ACTIVE PHYSICS code, base object. 
class baseObject
	{
	ALLEGRO_BITMAP* bmp;
	@disable this(); 
	bool isDebugging=false; /// display messages for this guy in particular (this allows us to have dump code for say, onDraw, but only the specific ones we care about by marking them ingame).
	bool isDead = false;	
	bool isSpawn = false; /// is a spawned child object, feel free to kill it. Used ATM for spawned meteors to not respawn on hit.
	pair pos; 	/// baseObjects are centered at X/Y (not top-left) so we can easily follow other baseObjects.
	pair vel;
	float w=0, h=0;   /// width, height 
	float ang=0;	/// pointing angle 
	float hp=100;
	string debugString="";
	bool flipHorizontal=false;
	bool flipVertical=false;
	int team;

	void onHit(baseObject by, int damage)
		{
		hp -= damage;
		}

	this(pair _pos, pair _vel, ALLEGRO_BITMAP* _bmp)
		{
		team = 0; //fixme
		pos = _pos;
		vel = _vel;
		bmp = _bmp;
		}
		
	bool draw(viewport v)
		{
		if(isInsideScreen(pos.x, pos.y, v))
			{
			al_draw_center_rotated_bitmap(bmp, 
				pos.x + v.x - v.ox, 
				pos.y + v.y - v.oy, 
				ang, ALLEGRO_FLIP_HORIZONTAL & ALLEGRO_FLIP_VERTICAL);

			if(debugString != "")
				{
				pair p = pair(pos.x + v.x - v.ox, pos.y + v.y - v.oy);
				pushFont(g.font12);
					drawText(p, white, debugString);
				popFont();
				}

			return true;
			}
		
		if(isDebugging) // do we ALWAYS draw debugstring regardless of this?
			{
				// and this is more like like vectors etc
			}

		// DEBUG. show partially clipped:
		/+
			al_draw_center_rotated_tinted_bitmap(bmp, red, 
				pos.x + v.x - v.ox, 
				pos.y + v.y - v.oy, 
				angle, ALLEGRO_FLIP_HORIZONTAL & ALLEGRO_FLIP_VERTICAL);
		+/
		return false;
		}
	
	// INPUTS (do we support mouse input?)
	// ------------------------------------------
	void actionUp(){ pos.y-= 10;}
	void actionDown(){pos.y+= 10;}
	void actionLeft(){pos.x-= 10;}
	void actionRight(){pos.x+= 10;}
	void actionFire()
		{
		}
	
	void onTick()
		{
		// THOU. SHALT. NOT. PUT. PHYSICS. IN BASE. baseObject.
		// but HOUSE KEEPING STUFF, WE DO. Because this will be called by child units first
		debugString = "";
		}
	}	

// old
// -----------------------------------------------------------------------
/+class ship : unit
	{
	string name="";
	bool isControlledByAI=false;
	bool isOwned=false;
	player currentOwner;
	bool isLanded=false; /// on planet
	bool isDocked=false; /// attached to object
	gun myGun;
	int numDudesInside; // NYI, we don't need (at least at this point) to keep actual unique dude classes inside. Just delete them and keep track of how many we had. (ala all level-1 blue pikmin are the same)
	int numDudesInsideMax = 20;
	
	/// "constants" 
	/// They are UPPER_CASE but they're not immutable so inherited classes can override them.
	/// unless there's some other way to do that.
	float MAX_LATCHING_SPEED = 3;
	float MAX_SAFE_LANDING_ANGLE = 45;
	float ROTATION_SPEED = 5;
	uint  SHIELD_COOLDOWN = 60; /// frames till it can start recharging
	float SHIELD_RECHARGE_RATE = 0.5; /// once recharging starts rate of fill
	int   SHIELD_MAX = 100; /// total shield health
	float SPEED = 0.1f;
	
//	int gunCooldown = 0;
	float shieldHP = 0;
	int shieldCooldown = 60;
	//we could also have a shield break animation of the bubble popping
		
	bool requestBoarding(dude d)
		{
		// we send dude type just in case there's multiple classes or something.
		if(numDudesInside < numDudesInsideMax)
			{
			numDudesInside++;
			return true;
			}else{
			return false; // we full
			}
		}
	
	this(float _x, float _y, float _xv, float _yv)
		{
		myGun = new minigun(this);
		super(1, _x, _y, _xv, _yv, ship_bmp);
		}

	override bool draw(viewport v)
		{ //todo include bitmap width/height in this scenario (a helper function may already exist)
		float cx = pos.x + v.x - v.ox;
		float cy = pos.y + v.y - v.oy;
		if(cx < 0 || cx > SCREEN_W || cy < 0 || cy > SCREEN_H)return false; //built-in clipping
		//drawShield(pair(x, y), v, bmp.w, 5, COLOR(0,0,1,1), shieldHP/SHIELD_MAX);
		super.draw(v);		
		
		if(name != "")
			{
			if(numDudesInside == 0)
				drawTextCenter(cx, cy - bmp.w, white, "%s", name);
			else
				drawTextCenter(cx, cy - bmp.w, white, "%s [+%d]", name, numDudesInside);
					
			// using bmp.w because it's larger in non-rotated sprites
			}
		
		return true;
		}
		
	void crash()
		{
		pos += vel;
		//pos.x += -vel.x; // NOTE we apply reverse full velocity once 
		//pos.y += -vel.y; // to 'undo' the last tick and unstick us, then set the new heading
		vel.x *= -.80;
		vel.y *= -.80;
		}
		
	bool checkUnitCollision(unit u)
		{
//		writefln("[%f,%f] vs u.[%f,%f]", x, y, u.x, u.y);
		if(pos.x - 10 < u.pos.x)
		if(pos.x + 10 > u.pos.x)
		if(pos.y - 10 < u.pos.y)
		if(pos.y + 10 > u.pos.y)
			{
//		writeln("[bullet] Death by unit contact.");
			return true;
			}		
		return false;
		}
		
	void doShield()
		{
		if(shieldCooldown > 0)
			{
			shieldCooldown--; 
			return;
			}else{
			if(shieldHP < SHIELD_MAX)shieldHP += SHIELD_RECHARGE_RATE;
			if(shieldHP > SHIELD_MAX)shieldHP = SHIELD_MAX;
			}
		}
		
	void runAI()
		{
		// Mode: attack
		// we can add randomness (on spawn) to certain parameters to make it more 'human' / imperfect
		// Overshooting (detect turn left, but then we keep turning left until we get a stop turning
		// or turn right command, then we reduce the tickrate of the AI)
		// - could implement some sort of PID controller
		//		desired_pos(player)		-- set point (SP)
		//		this:
		//			current_pos			-- 
		//			current_vel
		//			current_angle
		// 
		// at the very least, a PID of "distance to target" plus our velocity equation
		//	https://en.wikipedia.org/wiki/PID_controller
		//
		//	P proportional error vs desired
		//	D derivative, for dampening overshoot
		//  I integral (not needed?) for removing residuals
		// 
		// ALSO, ships currently have LINEAR velocity. Do we want SQUARED so they can't speed up as fast?
		//	K.E. = 1/2mv^^2
		/+
			ALSO (not necessarily needed) but look up PID velocity and position control
				because if we're taking an integral or derivative of position (or velocity)...
				we're already using those terms and may plug them in. (del pos/time = velocity right?)
			
			we might use a more advanced version for getting AI ships to land on planets carefully (desired end velocity=0)
		+/
	
		immutable float MAX_AI_SPEED = 2;		// jet till we hit max speed
		immutable float BOOST_DISTANCE = 100; 	// jet until we close distance (what about manuevering for close combat vs closing the distance?)
		immutable float ENGAGE_DISTANCE = 400;
		immutable float SHOT_PERCENT = 25;		// 1/60th frame rate, 25% = ~15 shots / second max (not including cooldown) 
		immutable float SHOT_ANGLE_RANGE = 30;  // NYI, don't shoot unless we're SOMEWHAT close to being able to hit (don't shoot backwards). Unless we want to look stupid sometimes. Add a percentage chance for that based on AI_STUPIDITY.
		
		unit target = g.world.units[0];
		float a = angleTo(target, this);
		// FIXME: WARNING. This will cap max speed... even if we're going max speed opposite direction!
		if(distanceTo(target, this) > BOOST_DISTANCE /*&& distance(vx, vy) < MAX_AI_SPEED*/){actionUp();}
		if(distanceTo(target, this) < ENGAGE_DISTANCE && percent(SHOT_PERCENT)){actionFire();}		
		if(isLanded)actionUp();
		if(angle > a)actionLeft();
		if(angle < a)actionRight();
		}

	override void onTick()
		{
		/// Subunit logic
		myGun.onTick();
		doShield();
		if(isControlledByAI)runAI();
			
		pos += vel;
		}

	void spawnSmoke()
		{
		float cvx = cos(angle)*0;
		float cvy = sin(angle)*0;
		g.world.particles ~= particle(pos.x, pos.y, vel.x + cvx, vel.y + cvy, 0, 100, this);
		}

	override void actionUp()
		{		
		}
		
	override void actionDown() 
		{ 	
		if(!isLanded)applyV(angle, -.1); 
		}
		
	override void actionLeft() { if(!isLanded){angle -= degToRad(ROTATION_SPEED); angle = wrapRad(angle);}}
	override void actionRight() { if(!isLanded){angle += degToRad(ROTATION_SPEED); angle = wrapRad(angle);}}

	override void actionFire()
		{
		if(!isLanded)myGun.actionFire();
		}
	}
+/

// method 1
// ------------------------------------------------------------------------
class _event
	{
	eventFSM owner;
	this(eventFSM _owner)
		{
		owner = _owner;
		}
	void enter(){}
	void trigger(){}
	void exit(){}
	}

class _event_switchON : _event
	{
	this(eventFSM _owner)
		{
		super(_owner);
		}
	
	override void enter(){}
	override void trigger(){owner.lightBulbOn = true;}
	override void exit(){}
	}

class _event_switchOFF : _event
	{
	this(eventFSM _owner)
		{
		super(_owner);
		}
	
	override void enter(){}
	override void trigger(){owner.lightBulbOn = false;}
	override void exit(){}
	}
		
// method 2
// ------------------------------------------------------------------------
void switchon(eventFSM owner) // okay but this needs internal logic or its always going to flip.
	{ // and we've also got a problem, we don't have enter/exit conditions.
	owner.dg = &switchoff;
	owner.lightBulbOn = true;
	}

void switchoff(eventFSM owner) 
	{
	owner.lightBulbOn = true;
	owner.dg = &switchon;
	}
	
class eventFSM
	{
	_event ev;
	void function(eventFSM) dg;
	bool lightBulbOn=false;
	
	this()
		{
		auto switchON = new _event_switchON(this);
		auto switchOFF = new _event_switchOFF(this);
		dg = &switchon;
		}
	
	void switchTo(_event _next)
		{
		ev.exit();
		ev = _next;
		ev.enter();
		}
		
	void onTick()
		{
		ev.trigger();
		dg(this);
		}
	}
