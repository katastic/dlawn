import timermod; // ldksnlksagdndgslakn

struct event {
	void function() toSomeShit; // or delegate,etc
}

class eventManager {
	event[] eventsQueue; // could use a static array of MAX_EVENTS

	void add(event e) {
		eventsQueue ~= e; // is it simply FIFO?
	}

	void onTick() {
		handleEvents();
	}

	void handleEvents() {
		foreach (e; eventsQueue) {
			e.toSomeShit();
		}
		eventsQueue = [];
	}
}
