
/+
	routines for tracking units of time and trigging events based on time or frames
	
	---> don't we need a coded event system for this?

+/
import eventmod;

class timerHandler /// th
	{
	frameTimer[] frameTimers;
	secondTimer[] secondTimers;
	
	// are we just going to reimplenet the signatures for all types?
	// do we want two handlers then? otherwise we have
	// setFrameTimer, setSecondTimer, getSecondTimer, etc etc etc.
	}

class frameTimerHandler
	{
	frameTimer[] timers;
	void createTimer(int frames, void function() trigger){
		}
		
	void onTick(){
		for(uint i = 0; i<timers.length;i++){
			with(timers[i]){
				timers[i].framesLeft--;
				if(timers[i].framesLeft==0){ // on zero or less than zero?
					timers[i].triggerEvent.toSomeShit();
					}
				}
			}
		}
	}

class SecondTimerHandler
	{
	}
	
class timerType
	{
	void start() = 0;
	void stop() = 0;
	void restart() = 0;
	void trigger()
		{
		assert(triggerEvent.toSomeShit !is null);
		triggerEvent.toSomeShit();
		}
	// void set(){}
	event triggerEvent;
	}

class frameTimer : timerType
	{
	int framesLeft;
	int getFramesLeft(){return framesLeft;}
	this(int _frames)
		{
		framesLeft = _frames;
		}
	}
	// also do we want a relativeFrameTimer? Does that do anything conceptually?
	// the normal one syncs to game frames. Is there another kind of sync we'd 
	// want for animations? I thought so for a brief moment but I can't think of an example now.
	
class secondTimer : timerType		// alternate names? timeTimer? metricTimer? clockTimer?
	{
	float secondsLeft;
	float getSecondsLeft(){return secondsLeft;}
	}
	
