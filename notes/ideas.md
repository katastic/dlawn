dlawn
================================================================================================

 - how do we want multiple fonts? Right now it's an implied font but the problem there is, we HAVE to remember to 
 current push/pop fonts! We could do a pushFont.drawText().popFont;

 - tankRotate (or better name). rotate the closest direction toward the goal. (counter-clockwise vs clockwise)
	as 350 degrees and goal = 0 deg, move 10 up toward 360, not down 350.

 - is there a way to do temporary bitmap targets that auto go back:
	 
		with(target(myNewTarget))
			{
			drawToNewBitmap();
			} // auto removes afterward

 - drawLine and drawText are slow. Since they're mostly used in dialogs do the following:
	- system for detecting text changes (dirtybit) and render to a texture. draw calls only draw the
		buffer bitmap directly.
	- the drawline background could just be a bitmap anyway in the final product.


	- if we do angle class, are we going to have a bunch of slow conversions to/from sin/cos functions?
		should we typedef instead?
			https://dlang.org/library/std/typecons/typedef.html

 - frame separation. actions affect the NEXT frame. Keep a collection of frames. However, what about Write after Write hazards? 
	
	A kills B so it's dead in B'
	C uses B (not B') but it should already be dead
	
	- frame replay system, as well as spectating/logging from a network device. (Vibe.d? other simpler network lib?)
	
	- typedef or whatever angle to be it's own type so you can flip and rollOver/WrapAround the coordinates inside 360.
		internally we could use some sort of fixed point thing so it autowraps around, but then we'll have to 
		constantly convert to and from it.
		
	- user interface drag-and-drop. need timers / events

 - send logs to a seperate frame debugger either on localhost or another PC with bigger screen. filter options. sql?
	- support hyperlinks to object index lookups/pointers
		O2013.AttackedBy[O1000]
			 [01000].Name "taco man steve"

	- 3d lighting on 2d surfaces / bump mapping
	
	- AI stuff. bug skittering AI.




ecophage
================================================================================================
	- we could do some sort of colony management stuff like Colonization, and Oxygen Not Included
		- multiple food stuffs together, increase gather rate / stamina / etc.
	- we could make it a fantasy game with orcs and stuff taking over the world and a wizard is like "bitch, we're going to fantasy mars. So you gotta get as much resources as possible before the orcs from WC2 take over."
	


robinhood GTA mafia
================================================================================================
	- formations of thugs
	- rob rich
	- give some to poor to gain favor. robinhood meets al capone

star control2? gravity well?
================================================================================================



datajack style game
================================================================================================
	- items: hacking. bombs. medkit.
	- upgrades: deus ex. arms, legs, torso, head. eyes. cybernetic AUGMENTS.
	- new: SWIMMING
	- hacking, talking?, brute force breakin through doors/windows/etc.
	- sneak in.
	
	- use a civilian as a HOSTAGE and lead them around.
		- different areas, and different levels, have Rules of Engagement levels
		from "completely ignore hostile acts" all the way to "shoot on sight"
			- Full ignore
			- Aggrevated by shots / hacking sighting
			- Aggrevated by trespassing
			- Shoot on sight
			
		or even a set of qualifiers of any combination.
	
for any particular level, get XP points for beating it multiple ways just like Styx: Master of Shadows 
	- assault run. complete the level normally. +avoid civilian casualities. (or is that pacifist)
	- pacifist run. 
	- ghost run. 
	
	or literally:
		skill objectives + optional objectives.
	
	- assault
		- don't kill anyone
		- don't lose X health
		- TIME.
	- breacher
		- uses explosives and other devices to break through windows, doors, WALLS, etc.
	- hacker
		- uses computers to subvert automated defenses
		- steal data
	- thief 
		- don't kill anyone
		- steal things
		- don't get seen
		- limited breaching

	if we intend to do CO-OP then we need to LIMIT the amount of resource usage somehow, like Monaco with limited use items. 
	Or force everyone to be the same class. The idea is, whether it's 1 or 4 players, there's the same amount of total "kit" 
	item money, so we can easily tweak level difficulty/design to be balanced.
		[levels can specify lootkit too, just be ware that modders aren't exactly great at balance.]
	
		- 1 guy can breach X of Y doors, so he has to make a CHOICE which ones you care about. Do you bypass this section, when a harder section may be ahead?
		- 4 guys can breach the same amount of X doors, by splitting the charges between them. They just can do different ordering.
		
			think using flashbangs/stun grenades to bypass sections. They're temporary, and limited.
		
		
	--> How do we ALARMS and other AI when there's multiple players?
		- it has to reset (cooldown?) somehow otherwise the game is blown immediately when someone messes up a single task.
		- we could do some sort of "only way to stop alarm, is go to an ALARM STATION and hit it" like crusader no remorse.
			- so there is a PENALTY for screwing up, but its only a set back. However, in a really hard section it could be annoying to constantly backtrack.
			- dont forget LOCKDOWN gates/doors/windows/etc when alarms hit which force you to either use more breaching kit, or undo the alarm

obviously full Steam workshop support for new levels and campaigns. No idea if you can add 3rd party enemies.
