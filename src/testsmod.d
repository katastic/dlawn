import std.stdio;
import g;

void runConsoleTests() /// Test D stuff without loading the entire game.
	{
	writeln("Running console tests");
	
	
	statistics_t s;
	s.inc("tacos");
	s.inc("tacos");
	s.inc("tacos");
	s.inc("tacos");
	s.inc("tacos");
	
	(*s["tacos"]).drawn++;
	writeln(s["tacos"]);
	}

void runAllegroTests() /// Test stuff after Allegro sets up display, etc.
	{
	writeln("Running Allegro tests");
//	bitmapHandler bh = new bitmapHandler();
//	bh.loadJSON();
	}

