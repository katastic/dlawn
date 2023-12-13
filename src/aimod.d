import molto, helper;
import std.math, std.random;

class aiType
	{
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

class bug : unit
	{
//	gunType gun;
	this(pair _pos)
		{
	//	gun = gunType();		
		super(_pos, new flatWalkerStyle(cast(unit)this));
		ai = new bugAi(this);
		}
		
	override void onTick()
		{
		ai.onTick();
		}
	}

class bugAi : aiType
	{	
	unit myOwner;
	BUG_STATES state;
	
	immutable float agitationThresholdC = 100; // end with C for constant instead of FULLCAPSFORACONST?
	immutable float rotationSpeedC = degToRad(5);
	immutable float skitterSpeedC = 0.25;
	immutable float agitationDecayRateC = 1;

	float agitation = 0;
	float fleeAngle = 0; // opposite of what we're fleeing from
	float currentAngle = 0;
	float runSpeedC = 1;

	
	this(unit owner)
		{
		myOwner = owner;
		}
	
	void triggerAudioCue(pair triggerPos, float volume)
		{
		agitation += distanceTo(myOwner.pos, triggerPos)/1000;
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
			if(currentAngle < fleeAngle)currentAngle+=rotationSpeedC;
			if(currentAngle > fleeAngle)currentAngle-=rotationSpeedC;
			myOwner.pos.x += cos(currentAngle)*runSpeedC;
			myOwner.pos.y += sin(currentAngle)*runSpeedC;
			}
		
		run();
		if(agitation > 0)agitation -= agitationDecayRateC;
		else
			state = BUG_STATES.IDLE;
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

	// do we want to CHECK for event changes inside each state, or before checking the switch?
	override void onTick()
		{			
		with(BUG_STATES)
		switch(state)
			{
			case IDLE:
					onStateIdle();
				break;
			case SCARED:
					onStateScared();
				break;
			case SKITTER:
					onStateSkitter();
				break;
			default:
				break;
			}
		}
	}
