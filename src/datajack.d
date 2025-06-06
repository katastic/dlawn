import molto : angle;
import viewportsmod;
import atlasmod;
import g, helper, objects, molto : pair, bitmap;
import toml;

// GANGS OF SHERWOOD
// ==========================================================================
/+
gladiator. warcraft 1, 2. heroes of might magic

baseObject-> 
	unit->
		(neutral NPCs)
			rabbit
			deer
			cow
			chicken
			birds
		(enemy NPCs)
			dragon
			ogre
			goblins
			kobold
			orcs
			demon
	
		elf/dwarves
		thief
		peasants
		thugs/mercs/brigand
		pikeman
		fighter
		knight
		mage/archmage/sorcerer
		cleric
		conjurer
		faerie
		fireElemental
		waterElemental
		airElemental
		giantScorpion
		slime, bigSlime, hugeSlime
		spider
		golem
		orc
		ogre
		archer
		druid
		skeleton
		necromancer
		engineer (builds towers
		seigeWeapons
			catapult
			ballista
		demon
	buildings
		enemy spawners?
	ridableVehicle
		horse	[can any NPC mount a knight]
		chariot
		wagon
		dragon/griffon
		gnomish flying machine
+/

/+
class pikeman : dude{
	this(){
		super(pair(0,0));
		}
	override bool onDraw(viewport v){return 0;
		}
	override void onTick(){
		}
	}


class dude : baseObject{
	bool usingAI = false;
	this(){
		super(pair(0,0), pair(0,0), bh["asteroid"]);
		}
	this(pair pos){
		super(pos, pair(0,0), bh["asteroid"]);
		}
	
	override bool onDraw(viewport v){return 0;
		}
	override void onTick(){
		}
	}

// HOTEL HELL / WARS
// ==========================================================================

// SPACE PIRATE
// ==========================================================================

/// space ship is a unit but also a tilemap
class spaceShip : baseObject{
	int [][] map; //filler since map2 has tons of code
	
	this(){
		super(pair(0,0), pair(0,0), bh["asteroid"]);
		}
	
	override bool onDraw(viewport v){return 0;
		}
	override void onTick(){
		}
	}

class asteroid : baseObject{
	this(){
		super(pair(0,0), pair(0,0), bh["blimp"]);
		}
	override bool onDraw(viewport v){return 0;
		}
	override void onTick(){
		}
	}

class spacePirate : baseObject{
	this(){
		super(pair(0,0), pair(0,0), bh["blimp"]);
		}
	override bool onDraw(viewport v){return 0;
		}
	override void onTick(){
		}
	}

// THIS IS ww2 OR OTHERWISE now because why make a datajack game.
// though that won't really have any kind of physics stuff that I usually do and enjoy
// maybe that'll be unique enough.
// maybe we can make WW2JRPG have a top down view instead of JRPG where you can pick targets and use terrain

// otherwise, Biplane Bonanza, or SkiiFreed or Death Hard

// WW2RPG
// ==========================================================================
// we should do more components. so if they have a health component, anyone can.
enum TANK_LOCATION
	{
	TL_UpperGlacius,
	TL_LowerGlacius,
	TL_Back,
	TL_UpperSide,
	TL_LowerSide,
	TL_TurretMantlet,
	TL_TurretFront,
	TL_TurretBack,
	TL_TurretSide,
	TL_LeftTrack,
	TL_RightTrack,
	}

enum SHELL_TYPE
	{
	HE, HESH, AP, APCR, APCBR, HVAP, HEVT
	}

struct shellType
	{
	float pen;
	float decayFactor; // or pen at each range table
	float explosiveMass;
	float fuseDistance; /// minimum
	SHELL_TYPE type;
	bool isIncendiary;
	bool isExplosive;
	bool isTracer;
	bool isArmorPiercing;
	bool isBallisticCapped;
	bool isHESH;
	bool isHEAT;
	}

class tankType : unit
	{ // when we hit armor, does it damage the armor? Or just pen and do HP damage
	ipair gridPos;
	float hitpoints;
	float hitpointsMax;
	
	float[TANK_LOCATION] armor;
	
	this()
		{	
		super(pair(0,0), new flatWalkerStyle(this));
		}
	
	void moveToGrid(ipair gridLocation)
		{
		// if map says its clear, lets move
		// or request the map move us. a toss up
		gridPos = gridLocation;
		}
	
	void actionMakeAttackOn(tankType enemy)
		{
		}
		
	void eventTakeHit(tankType from, shellType shell, float range, TANK_LOCATION loc)
		{
		
		}
		
	void onTurn()
		{
		// do shit
		}
	}

// Biplane Bonanza
// ==========================================================================
class biplane : unit
	{
	pair velocity;
//	angle ang;
	
	this()
		{	
		super(pair(0,0), new flatWalkerStyle(this));
		}
	
	bool isLandingGearDown;
	void actionLandingGear(){}
	void actionFireGun(){}
	void actionButtGunner(){}
	void actionDropBomb(){}
	}

// datajack 2020 alpha footage has various sneaking chatting
// https://www.youtube.com/watch?v=N9kcwtBtgoI
// "I'm still figuring it out but I think there will be strategic elements. You might be able to use information you find to talk around, items like fake IDs, maybe real IDs you pull off a dead guard, and the overall skill check / choices will be subject to some other constraints."
/+ "Maybe worth thinking about fire alarms and fire doors too. Two mechanics come to mind: 
1. fire doors with magnetic catches - in some secure storage buildings (i.e., archive stores) fire doors are held open by magnetic locks so staff can move through the corridors unimpeded during work hours. At night, or in the event of a fire alarm, the catches are released and the doors close under their own weight - for two purposes: security (once closed the doors might require card access) and to slow the spread of fire. 
2. alarm-triggered releases: when a fire alarm is triggered, some doors that are normally locked will become unlocked (from one side, if they have electronic locks) to allow staff to leave quickly. 
There's the potential for an interesting risk/reward mechanic here: trigger an alarm and deal with the noise and alert, but potentially benefit from new access routes, or newly closed doors impeding the guards..."
+/
// CYBER NINJA: https://www.youtube.com/watch?v=j1FohqSH3SE&list=FLACu5qsR5IpXRQvHo8vRyDQ
// random YT link to read later hah

// different vision modes like predator. see laser trips. other things? track heat sources for power stuff?

// highscore uses replay system so people can't cheat online scores.

// GAGDET: scout eye drone like Perfect Dark
// flashbangs (stun)
// smoke grenades
// gas grenades (sleep? poison?)? Expensive and rare like Thief 1/2?
/+
	healthkit
	hacking kit
	breach kit
	grenades
+/

import g, molto, objects, helper : capReset;
import toml;
import std.stdio;
/+
	need additional layer:
	
	for every direction
		for every stance		[prone, walking, running]
			listOfFrames[]
			
	do we want an animation format that lets you combine animation directives 
	with the file loading instead of naming every singl eframe and THEN binding
	them?
	
	do we have any support alternative player skins?
		- simple: tinting? Do we need a mask

+/


/+
	is there ANYWAY to integrate optional triplets into pair code?
+/

// class flatWalkerStyle(T) : movementStyle2(T)
// template functions are NON-VIRTUAL and cannot be inhereted from!
// or is that an old post from 2012?
	

import aimod;
class unit : baseObject /// Physics operating generic object
	{
	movementStyle2 	moveStyle; 
	anim 			myAnim;
	aiType 			ai;
	int direction; // facing direction
	float maxHp;
	float hp;
		
	void onHit(baseObject by) // could be bullet, or unit. might want two different functions for this.
		{
		}
		
	this(pair _pos, movementStyle2 _moveStyle)
		{
		moveStyle = _moveStyle;
		super(_pos, pair(0,0), bh["grass"]);
		}

	this(pair _pos, movementStyle2 _moveStyle, aiType _aiStyle)
		{
		moveStyle = _moveStyle;
		ai = _aiStyle;
		super(_pos, pair(0,0), bh["grass"]);
		}
		
	override void onTick()
		{
		if(moveStyle !is null)moveStyle.onTick();
		if(ai !is null)ai.onTick();
		super.onTick();
		}
	}
	
class cleanerDroid : unit
	{
	this(pair _pos)
		{
		super(_pos, new flatWalkerStyle(cast(unit)this));
		}
	}

class runner : unit // how are we going to integrate 3D?!
	{
	this(pair _pos)
		{
		gun = gunType();
		
		super(_pos, new flatWalkerStyle(cast(unit)this));
		}
		
	gunType gun;
	}
	
struct damageType
	{
	float bruteDamage;
	float pierceDamage;
	float poisonDamage;
	float shockDamage;
	float EMPDamage;
	float burnDamage;
	float pressureDamage;
	} // can have predefined ones.	
damageType fireDT = damageType(1,1,1,1,1,1,1); // e.g.

struct floorType
	{
	float speedReduction;
	float volumeReduction; // metal = 0, rug = 99%
	bool isDamaging;
	damageType damage;
	}
floorType grass;
floorType rug;
floorType metal; //etc

struct structureType
	{
	bool transparent; /// see through
	bool passesLaser; /// passes laser shots
	bool passesLow; // prone, crouch, standing
	bool passesMid; // crouch, standing
	bool passesHigh; // standing  (also flying, or flying can vary)
	float health;
	float passPen; // anything above this will reduce percentage of damage, and keep going. (10 pen, 5 penToPass = 50% damage leftover)
	float stopPen; // anything below this will not damage at all.
	}

struct itemHydraulicJack /// inventory item for breaking open doors/etc.
	{
	}

struct itemPowerJack /// inventory item for "stunning" power grids
	{
	}

struct itemHackRig /// inventory item for hacking grids
	{
	float hackRateLocal; /// how many hackpoints a second
	float hackRateRemote; /// how many hackpoints a second
	uint  hackLevelLocal; /// level 0-10
	uint  hackLevelRemote; 
	}

class hackingGrid /// Hacking overlay
	{
	string gridName;
	color gridColor; // maybe
	hackableDevice[] devices;
	}

class hackableDevice /// Device in overlay
	{
	bool isRemoteHackable=false;
	float hostName; // network host name, if useful
	uint  minimumLevel;
	float hackPoints; // hitpoints for hacking
	
	// does this go in the device, or the grid class
	bool onTriggerExplodesTile;
	bool onTriggerDisablesAlarm;
	bool onTriggerSpawnGuards;
	ipair triggerEffectLocation; // where do we blow up, spawn guys, etc.
	}
	
// spike traps (animated?), laser tripline, laser explosive
// trap doors fall through? trap doors that open and reveal guns/etc?
class trapDevice
	{
	string name;
	bool isHackable;
	hackableDevice myHackGrid;
	
	irect triggerArea;
	
	bool triggersOnGroundUnits;
	bool triggersOnFlyingUnits;
	
	bool isRepeatingTrap;
	bool isWaitForLeaveToRetrigger;
	
	bool onTriggerSpawnProjectile;
	bool onTriggerTriggerAlarm;
	bool onTriggerSummonGuards;
	bool onTriggerExplodeTile;
	ipair triggerEffectLocation; /// where do we blow up, spawn guys, etc.
	damageType damageToScenary;
	damageType damageToPlayer;
	damageType damageToGuards; /// ai unit damage
	}

struct gunMod
	{
	string name = "Laser Sight";
	string description = "Increases accuracy";
	// stat change code. either all stats, or a delegate that changes stats.
	}
	
struct ammoType
	{
	float PenModifier;
	float DamageModifier;
	float loudnessModifier;

	bool doesExplosiveDamage;
	bool doesFireDamage;
	bool doesIceDamage;
	bool doesShockDamage;
	bool doesStunDamage; // non-lethal/knockout
	
	// accuracy modifiers
	}

struct gunType // what about gunmods
	{
	string name;
	string description;
	ammoType[] ammoTypes;
		
	bool hasLaserSight;
	bool hasExtraMags;
	bool hasExtendedMags;
	
	// base stats before mods
	bitmap* bulletSprite;
	bool doesBulletFaceDirection; // or does it stay solid (like a sphere shot)
	float penetrationRating;
	
//	bool hasDuckBill;	// spread shots are horziontal only, not in a cone. Or just separate X and Y spread values.
	float spreadX;
	float spreadY;
	
	float damagePerShot;
	float shotsPerSecond; // fire rate
 	float bulletsPerShot; // shotgun fires many pellets/bullets per shot 
	float shotsPerMag;
	float startingMags;
	
	float accuracy; // spread?precision?
	float recoil;
	}
+/

class flatWalkerStyle : movementStyle2{
	bool isGrounded=0;
	bool isJumping=0;
		
	// "I want to move up/down/left/right"
	override bool tryToMove(pair posDifference)
		{
		// "Yes"
		//return true
		
		alias p = posDifference; // set animation direction.
		if		(p.x < 0 && p.y < 0){ myObject.direction = DIR.UP; } // fix me
		else if	(p.x > 0 && p.y < 0){ myObject.direction = DIR.DOWN; }
		else if	(p.x < 0 && p.y > 0){ myObject.direction = DIR.LEFT; }
		else if	(p.x > 0 && p.y > 0){ myObject.direction = DIR.RIGHT; }
		myObject.pos += posDifference;
		
		return true;
		// "No"
		//notifyCollisions(); // we hit some stuff
	//	return false; 
		}
	
	this(BaseObject _myObject)
		{
		super(_myObject);
		}
		
	override void onTick()
		{
		with(myObject)
			{
			if(world.map2.isValidMovement(pair(pos, vel))){
				vel.y += 0.05;
				pos += vel;
				}else{
				pos -= vel;
				vel.y = 0;
				}
			}
		}
	}


class movementStyle2{
	BaseObject myObject;
	@disable this();
	
	this(BaseObject _myObject){
		assert(_myObject !is null);
		myObject = _myObject;
		}
	
	bool tryToMove(pair posDifference){return true;}
	void onTick(){}; // why can't this be = 0; instead of requiring override???
	}

class planeStyle : movementStyle2{
	// "I want to move up/down/left/right"
	override bool tryToMove(pair posDifference){ // not used?
		// "Yes"
		//return true
		
		alias p = posDifference; // set animation direction.
		if		(p.x < 0 && p.y < 0){ myObject.direction = DIR.UP; }
		else if	(p.x > 0 && p.y < 0){ myObject.direction = DIR.DOWN; }
		else if	(p.x < 0 && p.y > 0){ myObject.direction = DIR.LEFT; }
		else if	(p.x > 0 && p.y > 0){ myObject.direction = DIR.RIGHT; }
		myObject.pos += posDifference;
		
		return true;
		// "No"
		//notifyCollisions(); // we hit some stuff
	//	return false; 
		}
	
	this(BaseObject _myObject){
		super(_myObject);
		}
		
	override void onTick(){
		with(myObject)
			pos += vel;
		}
	}

import helper : isInsideRadius;
class fallingObjectStyle : movementStyle2{
	bool doesCollide=true; // does it collide with objects  NYI
	
	override void onTick(){
		with(myObject){
			if(world.map2.isValidMovement(pair(pos, vel))){
				vel.y += 0.05;
				pos += vel;
				}else{
				vel.y = 0;
				//onMapCollision(DIR.DOWN);
				}
			
			foreach(o; g.world.objects){
			//	if(o.OBJTYPE == 1 && isInsideRadius(pos, o.pos, 20)){
			//		onObjectCollision(o);
			//		break;
			//		}
				}			
			}
		}

	override bool tryToMove(pair posDifference) { // should this be in movementStyle for user actions
		assert(false, "NYI");
		return true;
		}
	
	this(BaseObject _myObject){
		super(_myObject);
		}
		
	}
	
class floatingObjectStyle : movementStyle2 /// like a blimp (do we want velocity?)
	{
	bool doesCollide=true; // does it collide with objects  NYI
	
	override void onTick(){
		with(myObject){
			if(world.map2.isValidMovement(pair(pos, vel))){
				pos += vel;
				if(pos.x < 0)pos.x = 0;
				if(pos.x > 1005)pos.x = 1005; //fixme
				}else{
				//onMapCollision(DIR.DOWN);
				}
			
			if(doesCollide) foreach(o; g.world.objects){
				//if(o.OBJTYPE == 1 && isInsideRadius(pos, o.pos, 20))
					{
				//	onObjectCollision(o);
				//	break;
					}
				}			
			}
		}

	override bool tryToMove(pair posDifference){
		alias p = posDifference; // set animation direction.
		if		(p.x < 0 && p.y < 0){ myObject.direction = DIR.UP; }
		else if	(p.x > 0 && p.y < 0){ myObject.direction = DIR.DOWN; }
		else if	(p.x < 0 && p.y > 0){ myObject.direction = DIR.LEFT; }
		else if	(p.x > 0 && p.y > 0){ myObject.direction = DIR.RIGHT; }
		myObject.pos += posDifference;
		
		return true;
		}

	this(BaseObject _myObject){
		super(_myObject);
		}
	}

struct anim{
	int currentFrame;
	int numDirections;
	int numFramesPerDirection;
	
	int numFramesTotal(){ // function because this should be single-responsibility principle (SRP)
		return numFramesPerDirection * numDirections;
		}
		
	bitmap*[] frames;
	}

class animationHandler{
	void loadAnimationMeta(string path){
		import std.file : read;
		auto data = parseTOML(cast(string)read(path));
		//writeln(data["objects"]);
//		pragma(msg, typeof(data["objects"]));
import std.stdio;
		foreach(o;data["objects"].array){
			writeln(o);
			}
		}
	
	anim[const char*] anims;

	bitmap* get(const char *name, int frame, int direction){
		assert(name in anims);
		with(anims[name]){
			assert(direction < numDirections);
			assert(frame < numFramesTotal());
			return frames[currentFrame];
			}
		}

	bitmap* getNext(const char *name, int direction){
		assert(name in anims);
		with(anims[name]){
			assert(direction < numDirections);
			currentFrame = capReset(currentFrame, numFramesTotal()-1, 0); 
			return frames[currentFrame];
			}
		}
	}
