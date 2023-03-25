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

import molto;
import g;
import helper;
import viewportsmod;
import particles;
import guns;
import planetsmod;
import turretmod;
import bulletsmod;

enum STROKE{ two, four};
enum FUEL { gas, diesel, electric, nuclear, coal, hydrogen}
class engineT
	{
	float rpm = 0;
	float rpmMax = 7000;
	
	float[4] gears = [1, 2, 3, 4]; /// forward gears
	float reverseGear = 2;
	int cylinders = 4;
	STROKE stroke = STROKE.two;
	FUEL fuel = FUEL.gas;
	}

// <-----------------------------------	
// omfg, we could make it a Rogue/roguelite game. Randomized perk upgrades... for your fucking __lawn mower__.

/+
	- DIFFERENT LAWN MOWER TYPES / classes? 
	- bumping into obsticles damages your vheicle
  
	perks: 
	 - traditional ones like flat +10% buff to damage (to weeds), speed, health.
	 - "fun" / creative ones, especially "specializing" ones that give you a larger boost, but also a caveat.
		- "hot doggin'" (or whatever) 
			+ "additional mowing efficiency 50%, but the engine takes damage any time it's idling [the mower is motionless"]
		- "blind luck" ?
			- On the downside, you're completely blind. [see 10 ft]. 
			  On the brightside, there is no brightside, because you
			  can't see light. On the up side, with your retinas singed, 
			  you have replaced them with wanton abandon. You drive like you stole it. 50% mow speed." 
		- "drive it like you stole it"
			- "a police lawn mower chases you. You go faster, but if you get caught, it's game over." 
	
	DRINKS like Hammerwatch. you're getting DRUNK before mowing.
	specific MUSIC could apply bonsues but may be annoying for players to hear.
+/

// in our case, every player will control only one lawn mower and nothing else?
// or, he can control a dwarf/pedestration? If not, we can combine "player" class into the lawnmower class.

// functional drive systems
// 		front wheel drive, rear wheel drive, all wheel drive, tracked drive

// functional steering systems
//		front/rear steering. 4 wheel steering. zero turn drive.

// ground types:
//		grass, sand, mud, snow. shallow water. deep water. lava.
//			^^^^^^^^^^THEN WHY ARE WE MOVING IT?
//			unless we're moving "magic" trees or something that fight back.

struct baseStats
	{
	int engine; //level
	int transmission;
	int tires;
	int blade;
	int steering;
	}

float STAT_ACCEL = .1;
float STAT_ROTSPEED = degToRad(10);

/+
class lawnmower : unit // what other vehicles would there be? none?
	{
	this(){super(0, 0, 0, 0, 0, goblin_bmp);}
	
	override void onTick()
		{
//		g.world.map.attemptMow(ipair(x,y));  should we have ipair auto downconvert? BUT what about rounding decisions?
		g.world.map.attemptMow(ipair(cast(int)x, cast(int)y));
//		pos.x += vel.x;
//		pos.y += vel.y;
		x += vx;
		y += vy;
		}
	}
+/

class lawnMower : baseObject  // this should be a VEHICLE since its gonna have VEHICLE physics.
	{
	bool isMowing = true;
	pair pos, vel;
	float speed=0;
	float wheelBase=30;
	float facingAngle=0; 	// Car body facing angle.
	float rearWheelAngle = 0, frontWheelAngle = 0;
	
	this(pair position)
		{
		pos = position;
		vel.x = 0;
  		vel.y = 0;
		super(0, pos.x, pos.y, 0, tree_bmp);
		}
	override void actionUp()
		{
		speed += STAT_ACCEL;
		}
	override void actionDown()
		{
		speed -= STAT_ACCEL;
		}
	override void actionLeft(){facingAngle = wrapRad(facingAngle - STAT_ROTSPEED);}
	override void actionRight(){facingAngle = wrapRad(facingAngle + STAT_ROTSPEED);}

	bool attemptMove(float relX, float relY)
		{
		pair possiblePos = pos;
		possiblePos.x += relX;
		possiblePos.y += relY;
		if(g.world.map.isInsideMap(possiblePos))
			{
			if(g.world.map.isValidMovement(possiblePos))
				{
				pos = possiblePos;
				return true;
				}
			}
		return false;
		}

	pair rearWheelVec;
	pair frontWheelVec;

//http://engineeringdotnet.blogspot.com/2010/04/simple-2d-car-physics-in-games.html
	void doPhysics()
		{
		float carSpeed = 1;
		float steeringAngle = 5.degToRad;
		
		frontWheelVec = pair(	carSpeed * cos(facingAngle + steeringAngle) * wheelBase/2, 
								carSpeed * sin(facingAngle + steeringAngle) * wheelBase/2);
		rearWheelVec  = pair(	carSpeed * cos(facingAngle) * (-wheelBase/2), 
								carSpeed * sin(facingAngle) * (-wheelBase/2));

		pair averagePos; 
		averagePos.x = (frontWheelVec.x + rearWheelVec.x) / 2;
		averagePos.y = (frontWheelVec.y + rearWheelVec.y) / 2;
		
		import std.math : atan2;
		facingAngle = atan2(frontWheelVec.y - rearWheelVec.y, frontWheelVec.x - rearWheelVec.x);

		writeln(facingAngle);
		attemptMove(averagePos.x, averagePos.y);
//		attemptMove(speed*sin(facingAngle), -speed*cos(facingAngle));
//		if(isMowing)g.world.map.attemptMow(ipair(cast(int)pos.x/TILE_W, cast(int)pos.y/TILE_H));
		}

	override void onTick()
		{
//		doPhysics();
		attemptMove(speed*sin(facingAngle), -speed*cos(facingAngle));
//		clampBoth(pos.x, 0, 10_000);
//		clampBoth(pos.y, 0, 10_000);
	//	g.world.map.attemptMow(ipair(cast(int)pos.x/TILE_W, cast(int)pos.y/TILE_H));
		}
		
	override bool draw(viewport v)
		{
		// we're missing the IMPLICIT VIEWPORT code version!
		// we really have to move this stuff to its own library file
		// what about vpos?!?! gotta get access to dglad repo!!!!
//		drawTargetDot();
		al_draw_center_rotated_bitmap(bmp, pos.x - v.ox + v.x, pos.y + v.oy + v.y, facingAngle + degToRad(0), 0);
		return true;
		}
	}

class resource : baseObject
	{
	this(){super(0, 0, 0, 0, grass_bmp);}
	}

class fuel : baseObject
	{
	int amount=25;
	this(){super(0, 0, 0, 0, grass_bmp);}
	}

// do PARTS wear out? Tires? Blades? So we need/want either money, or, item drops like new blades. 
// or, we can do upgrades. Tire upgrade. Blade upgrade. Engine upgrade. etc

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
	int team;
	
	this(uint _team, float _x, float _y, float _vx, float _vy, ALLEGRO_BITMAP* b)
		{	
//		writeln("ITEM EXISTS BTW at ", x, " ", y);
		super(_x, _y, _vx, _vy, b);
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
			pos.x += vx;
			pos.y += vy;
			vx *= .99; 
			vy *= .99; 
			}
		}
	}
	
class goblin : unit
	{
	this(){super(0, 0, 0, 0, 0, goblin_bmp);}
	}
	
class dwarf : unit
	{
	this(){super(0, 0, 0, 0, 0, goblin_bmp);}
	}

class unit : baseObject // WARNING: This applies PHYSICS. If you inherit from it, make sure to override if you don't want those physics.
	{
	float maxHP=100.0; /// Maximum health points
	float hp=100.0; /// Current health points
	float ap=0; /// armor points (reduced on hits then armor breaks)
	float armor=0; /// flat reduction (or percentage) on damages, haven't decided.
	int myTeamIndex=0;
	bool isPlayerControlled=false;
	float weapon_damage = 5;

	void applyV(float applyAngle, float vel)
		{
		vx += cos(applyAngle)*vel;
		vy += sin(applyAngle)*vel;
		}

	override void onTick()
		{
/+		foreach(p; g.world.planets)
			{
			if(checkPlanetCollision(p))
				{
				x += -vx; // NOTE we apply reverse full velocity once 
				y += -vy; // to 'undo' the last tick and unstick us, then set the new heading
				vx *= -.80;
				vy *= -.80;
				}
			}
+/
		pos.x += vx;
		pos.y += vy;
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
		super(_x, _y, _vx, _vy, b);
		}

	override bool draw(viewport v)
		{
		super.draw(v);
		
		// Velocity Helper
		float mag = distance(vx, vy)*10.0;
		float angle2 = atan2(vy, vx);
		drawAngleHelper(this, v, angle2, mag, COLOR(1,0,0,1)); 
		
//		drawAngleHelper(this, v, angle, 25, COLOR(0,1,0,1)); // my pointing direction

		// Planet Helper(s)
		if(isPlayerControlled) 
			{
			pair p1 = pair(pos.x + v.x - v.ox - bmp.w, pos.y + v.y - v.oy - bmp.h);
			pair p2 = pair(pos.x + v.x - v.ox + bmp.w, pos.y + v.y - v.oy + bmp.h);
			drawSplitRectangle(p1, p2, 20, 1, white);

			// draw angle text
			al_draw_text(g.font1, white, 
				pos.x + v.x - v.ox + bmp.w + 30, 
				pos.y + v.y - v.oy - bmp.w, 0, format("%3.2f", radToDeg(angle)).toStringz); 
			}
		
		// Point to other player (could for nearby enemy units) once seen (but not before)
		//float angle3 = angleTo(g.world.units[0], this);
		//drawAngleHelper(this, v, angle3, 25, COLOR(1,1,0,1)); 
	
		draw_hp_bar(pos.x, pos.y - bmp.w/2, v, hp, 100);		
		return true;
		}
	}
	
class hardpoint : unit
	{
	ship owner;
	
	this(ship _owner)
		{
		hp = 50;
		owner = _owner;
		super(0, owner.pos.x, owner.pos.y, 0, 0, g.trailer_bmp);
		}
	
	override bool draw(viewport v)
		{
		COLOR c = COLOR(1,1,1,hp/maxHP);
		al_draw_tinted_rotated_bitmap(bmp, c,
			bmp.w/2, bmp.h/2, 
			owner.pos.x + v.x - v.ox + cos(angle + PI/2f)*10f, 
			owner.pos.y + v.y - v.oy + sin(angle + PI/2f)*10f, angle, 0);
		al_draw_tinted_rotated_bitmap(bmp, c,
			bmp.w/2, bmp.h/2, 
			owner.pos.x + v.x - v.ox + cos(angle + PI/2f)*-10f, 
			owner.pos.y + v.y - v.oy + sin(angle + PI/2f)*-10f, angle, 0);
		return true;
		}
		
	override void onTick()
		{
		// need some vector rotations;
		angle = owner.angle;
		pos.x = owner.pos.x;
		pos.y = owner.pos.y;
		}
	}

class ship : unit
	{
	string name="";
	bool isControlledByAI=false;
	bool isDebugging=false;
	bool isOwned=false;
	player currentOwner;
	bool isLanded=false; /// on planet
	bool isDocked=false; /// attached to object
	gun myGun;
	turret[] turrets;
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
		
		foreach(t; turrets){t.draw(v); g.stats.numberUnits.drawn++; }
		
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
		pos.x += -vx; // NOTE we apply reverse full velocity once 
		pos.y += -vy; // to 'undo' the last tick and unstick us, then set the new heading
		vx *= -.80;
		vy *= -.80;
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
		foreach(t; turrets)t.onTick();
		if(isControlledByAI)runAI();
			
		pos.x += vx;
		pos.y += vy;
		}

	void spawnSmoke()
		{
		float cvx = cos(angle)*0;
		float cvy = sin(angle)*0;
		g.world.particles ~= particle(pos.x, pos.y, vx + cvx, vy + cvy, 0, 100, this);
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
		
class movementStyle
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
	
class fallingStyle : movementStyle
	{
	this(ref pair _pos, ref pair _vel)
		{
		super(_pos, _vel);
		}

	override void onTick()
		{
		writeln(*pos, " ", *vel);
		*pos += *vel;
		}
	} /+ a component cannot access owner class unless we pass it. This can be good thing but how do we then... do stuff? 
	it can only operate on its own variables unless we pass them.
	
	+/
	
class meteor : baseObject
	{
	movementStyle moveStyle; // this cannot be a pointer for some reason? it's a reference type already though?
		
	this(pair _pos)
		{
		vel = pair(-.25, .25);
		super(_pos.x, _pos.y, 0, 0, g.large_asteroid_bmp);
		moveStyle = new fallingStyle(pos, vel);
		}
	
	override void onTick()
		{
		if(moveStyle)moveStyle.onTick();
		}
	}
	
class dude : baseObject
	{
	bool isGrounded = false;
	bool isJumping = false;
	
	this(pair _pos)
		{			
		super(_pos.x, _pos.y, 0, 0, g.dude_bmp);
		}

	// originally a copy of structure.draw
	override bool draw(viewport v)
		{		
		// we draw RELATIVE to planet.xy, so no using baseObject.draw
		// TODO how do we rotate angle from center of planet properly? Or do we even need that?
		float cx=pos.x + v.x - v.ox;
		float cy=pos.y + v.y - v.oy;
		if(cx < 0 || cx > SCREEN_W || cy < 0 || cy > SCREEN_H)return false;

		al_draw_center_rotated_bitmap(bmp, cx, cy, 0, 0);
//		if(isRunningForShip)
			al_draw_filled_circle(cx, cy, 20, COLOR(0,1,0,.5));
	//		else
		//	al_draw_filled_circle(cx, cy, 20, COLOR(0,0,1,.5));
		return true;
		}
	
	override void actionUp()
		{
		if(isJumping == false)
			{
			isJumping = true;
			vel.y = -5;
			}
		}

	override void actionLeft()
		{
		vel.x -= .10;
		}

	override void actionRight()
		{
		vel.x += .10;
		}
	
	override void onTick()
		{
		if(isJumping)vel.y += .1;
		pos.y += vel.y;
		if(g.world.map.isValidMovement(pair(pos, vel.x, vel.y)))
			{
			pos = pair(pos, vel.x, vel.y);
			isJumping = true;
			isGrounded = false;
			}else{
			pos = pair(pos, vel.x*.99, -1); //if we're stuck, move us up one out of the ground.
			vel = 0;
			isJumping = false;
			isGrounded = true;
			}
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
		super(x, y, 0, 0,b);
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

class baseObject
	{
	ALLEGRO_BITMAP* bmp;
	@disable this(); 
	bool isDead = false;	
	pair pos; 	/// baseObjects are centered at X/Y (not top-left) so we can easily follow other baseObjects.
	pair vel;
	float vx=0, vy=0; /// Velocities.
	float w=0, h=0;   /// width, height 
	float angle=0;	/// pointing angle 

	this(float _x, float _y, float _vx, float _vy, ALLEGRO_BITMAP* _bmp)
		{
		pos.x = _x;
		pos.y = _y;
		vx = _vx;
		vy = _vy;
		bmp = _bmp;
		}
		
	bool draw(viewport v)
		{
		al_draw_center_rotated_bitmap(bmp, 
			pos.x + v.x - v.ox, 
			pos.y + v.y - v.oy, 
			angle, 0);

		return true;
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
		}
	}	
