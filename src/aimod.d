import molto, helper;
import std.math, std.random;

class aiType
	{
	message[] messages;
	void onTick(){}
	}

class finiteStateMachine
	{
	int state;
	void onTick()
		{
		switch(state)
			{
			case 0:
				break;
			case 1:
				break;
			case 2:
				break;
			default:
				break;
			}
		}
	}

enum BUG_STATES
	{
	IDLE, SCARED, SKITTER
	}

import datajack;
import guns; // FIX ME LATER
import g;
class bug : unit
	{
//	gunType gun;
	this(pair _pos)
		{
	//	gun = gunType();		
		super(_pos, new flatWalkerStyle(cast(unit)this));
		ai = new bugAi(this);
		bmp = bh["beetle"];
		}
		
	override void onTick()
		{
		ai.onTick();
		}
	}

struct message
	{
	bool isSoundEvent;
	bool isVisualEvent;
	pair pos;
	}

// TODO: Confirm this works. looks like it favors one direction
void test__angleToward()
	{
	import std.stdio;
	writeln(angleToward(340.degToRad,   0.degToRad, 20.degToRad).radToDeg);
	writeln(angleToward(340.degToRad, 310.degToRad, 20.degToRad).radToDeg);
	writeln(angleToward(340.degToRad,  40.degToRad, 20.degToRad).radToDeg);
	}

// TODO: FIX ME
float angleToward(float currentAngle, float destAngle, float angleChange)
	{
	import std.stdio : writefln;
	writefln("ca:%3.2f da:%3.2f change:%3.2f", currentAngle.radToDeg, destAngle.radToDeg, angleChange.radToDeg); 
	float result=0;
	
	if(destAngle > currentAngle) // we need to move forward
		{
		result = destAngle + currentAngle;
		}
	if(destAngle < currentAngle) // we need to move backwards across zero
		{
		result = destAngle - currentAngle;
		}

	return result.wrapRad;
	}

class bugAi : aiType
	{	
	unit myOwner;
	BUG_STATES state;

	immutable float agitationThresholdC = 100; // end with C for constant instead of FULLCAPSFORACONST?
	immutable float rotationSpeedC = degToRad(10);
	immutable float skitterSpeedC = 0.25;
	immutable float agitationDecayRateC = 2;
	immutable float runSpeedC = 2;

	float agitation = 0;
	float fleeAngle = 0; // opposite of what we're fleeing from
	float currentAngle = 0;

	this(unit owner)
		{
		myOwner = owner;
		assert(myOwner !is null);
		}
	
	void triggerAudioCue(pair triggerPos, float volume)
		{
		import std.stdio;
		auto d = distanceTo(myOwner.pos, triggerPos);
		float t=0;
		if(d < 1000)t += 1000 - d; // if within circle, ramp danger
		agitation += t/10;
		writeln("distanceTo:", distanceTo(myOwner.pos, triggerPos));
		if(agitation > agitationThresholdC)
			{
			fleeAngle = angleTo(myOwner.pos, triggerPos).flip;
			triggerScared();
			}
		}
	
	void triggerScared()
		{
		state = BUG_STATES.SCARED;
		}
	
	void onStateIdle()
		{
		if(percent(3))state = BUG_STATES.SKITTER;
		}

	void onStateScared()
		{
		void run()
			{
//			if(currentAngle < fleeAngle)currentAngle+=rotationSpeedC;
//			if(currentAngle > fleeAngle)currentAngle-=rotationSpeedC;
			currentAngle = angleToward(currentAngle,fleeAngle,rotationSpeedC);
			myOwner.pos.x += cos(currentAngle)*runSpeedC;
			myOwner.pos.y += sin(currentAngle)*runSpeedC;
			}
		
		run();
		if(agitation > 0)agitation -= agitationDecayRateC;
		else
			{ agitation = 0; state = BUG_STATES.IDLE; }
		}

	void onStateSkitter()
		{
		void skitter()
			{
			if(percent(3))currentAngle += uniform(-.1, 1);
			myOwner.pos.x += cos(currentAngle)*skitterSpeedC;
			myOwner.pos.y += sin(currentAngle)*skitterSpeedC;
			}
		
		skitter();
		if(percent(3))state = BUG_STATES.IDLE;
		}

	void processEvents()
		{
		while(messages.length > 1)
			{
			auto msg = messages[$-1];
			if(msg.isSoundEvent)
				{
				triggerAudioCue(msg.pos, 100);
				}
			messages = messages[0..$-1];
			}
		}

	// do we want to CHECK for event changes inside each state, or before checking the switch?
	override void onTick()
		{
		super.onTick();
		import std.format;
		processEvents();
		
		myOwner.debugString = ""; // this should have been working BEFORE.
		// instead of a SUPERCHAIN, we can start an overhead() handler at the
		// start of an onTick.
		// in order to make it OPT-OUT, we could force someone to get the OWNER CONTEXT
		// by requesting it, which automatically calls super.onTick()
			
		with(BUG_STATES)
		switch(state)
			{
			case IDLE: // if we append, we can add messages however we're also slamming tons of string allocaitons. it might be better to have a debug[STRINGS_MAX] array
					myOwner.debugString = format("IDLE %3.2f", agitation);
					onStateIdle();
				break;
			case SCARED:
					myOwner.debugString = format("SCARED %3.2f", agitation);
					onStateScared();
				break;
			case SKITTER:
					myOwner.debugString = format("SKITTER %3.2f", agitation);
					onStateSkitter();
				break;
			default:
				break;
			}
		}
	}
