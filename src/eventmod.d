import timermod; // ldksnlksagdndgslakn

struct event
	{
	void function() toSomeShit; // or delegate,etc
	}

class eventManager
	{
	event[] events;
	void onTick()
		{
		handleEvents();
		}
		
	void handleEvents()
		{
		foreach(e; events)
			{
	//		e.toSomeShit();
			}
		}
	}
