/// Module: Duake
/// D quake terminal
/// We should try to separate the data layer and the UI layer into two distinct classes per Tim Cain.
import viewportsmod;

// which one contains which? or a third class has both.
// but then OOP problem. How do you INSTANTIATE a valid one? Circular references!
// unless 

// I will say, duake is hurting my brain a bit saying and typing it. maybe just 
// dQuake or dQuakeConsole, or even foldingTerminal or foldingConsole 

class duake
	{
	duakeDataLayer dataLayer;
	duakeUILayer uiLayer;
	
	this()
		{
		}
	}

class duakeCommandLayer /// this is the current command string (and list of previous run commands)
	{
	immutable MAX_STRINGS = 100;
	string[] previousCommands;
	string currentCommandString; 
	
	duakeUILayer myOwner;
	this(duakeUILayer _myOwner)
		{
		myOwner = _myOwner;
		}
		
	void addKeyToLine(string key)
		{
		currentCommandString ~= key; // we could use a staticString to reduce allocations
		}
		
	void addCommmandToCommandBuffer(string command)
		{
		previousCommands ~= command;
		if(previousCommands.length > MAX_STRINGS)previousCommands = previousCommands[1..$-1]; // chop off oldest (first) element
		}
		
	bool parseCommand(string command)
		{
		// woof.
		return true;
		}
		
	bool runCommand(string command){return true;} /// run a specified command
	bool runCommandLine(){return true;} /// whatever is currently typed in the commandline
	}

class duakeDataLayer /// this is just the previous commands log?
	{
	duakeUILayer myOwner;
	this(duakeUILayer _myOwner)
		{
		myOwner = _myOwner;
		}
	}

// We could also support a three? height one. Large (most of screen), small (a mini view with a 3 lines), and hidden.
// And we also forgot fullscreen so that's four which is kinda hefty. I almost never use fullscreen except to read man
// pages
enum duakeSize
	{
	MINIMIZED=0,	/// Hidden
	NORMAL=1,		/// Normal size
	MAXIMIZED=2		/// Fullscreen
	}

class duakeUILayer
	{
	duakeSize currentMode;	/// do enum. 0=minimized, 1=open, 2=maximized
	float height;			/// the height of the display when open
	float maximizedHeight;	/// height of screen
	float width;			/// width of screen and console
	duakeDataLayer dataLayer;
	
	this()
		{
		dataLayer = new duakeDataLayer(this); 
		}
		
	void onTick(){}
	void onDraw(viewport v){}
	}
