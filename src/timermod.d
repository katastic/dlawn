/+
	routines for tracking units of time and trigging events based on time or frames
	
	---> don't we need a coded event system for this?

+/
struct event
	{
	void* toSomeShit; // or delegate,etc
	}


class timerType
	{
	void start() = 0;
	void stop() = 0;
	void restart() = 0;
	// how do we do a set that takes different times? it can't be in this interface then YET needs to be implemented by everyone else!
	// i mean worst case, screw it, it's TWO different implementations but if there's a proper way I'd like to know
	event triggerEvent;
	}

class frameTimer : timerType
	{
	int framesLeft;
	int getFramesLeft(){return framesLeft;}
	}
	// also do we want a relativeFrameTimer? Does that do anything conceptually?
	// the normal one syncs to game frames. Is there another kind of sync we'd 
	// want for animations? I thought so for a brief moment but I can't think of an example now.
	
	
class clockTimer : timerType		// alternate names? timeTimer? metricTimer? clockTimer?
	{
	float secondsLeft;
	int getSecondsLeft(){return secondsLeft;}
	}
	
