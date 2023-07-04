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

import g, molto;

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

struct gunStats // what about gunmods
	{
	ammoType[] ammoTypes;
		
	bool hasLaserSight;
	bool hasExtraMags;
	bool hasExtendedMags;
	
	// base stats before mods
	bitmap* bulletSprite;
	bool doesBulletFaceDirection; // or does it stay solid (like a sphere shot)
	float penetrationRating;
	
	bool hasDuckBill;	// spread shots are horziontal only, not in a cone. Or just separate X and Y spread values.
	
	float damagePerShot;
	float shotsPerSecond; // fire rate
 	float bulletsPerShot; // shotgun fires many pellets/bullets per shot 
	float shotsPerMag;
	float startingMags;
	
	float accuracy; // spread?precision?
	float recoil;
	}
