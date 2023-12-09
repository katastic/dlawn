import molto, helper;
import std.math, std.random;

class aiType
	{
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

class bugAi : aiType
	{	
	pair pos;
	BUG_STATES state;
	
	immutable float agitationThresholdC = 100; // end with C for constant instead of FULLCAPSFORACONST?
	immutable float rotationSpeedC = degToRad(5);
	immutable float skitterSpeedC = 0.25;
	immutable float agitationDecayRateC = 1;

	float agitation = 0;
	float fleeAngle = 0; // opposite of what we're fleeing from
	float currentAngle = 0;
	float runSpeedC = 1;
	
	void triggerAudioCue(pair triggerPos, float volume)
		{
		agitation += distanceTo(pos, triggerPos)/1000;
		if(agitation > agitationThresholdC)
			{
			fleeAngle = angleTo(pos, triggerPos).flip;
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
			pos.x += cos(currentAngle)*runSpeedC;
			pos.y += sin(currentAngle)*runSpeedC;
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
			pos.x += cos(currentAngle)*skitterSpeedC;
			pos.y += sin(currentAngle)*skitterSpeedC;
			}
		
		skitter();
		if(percent(3))state = BUG_STATES.IDLE;
		}

	// do we want to CHECK for event changes inside each state, or before checking the switch?
	
	void onTick()
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
