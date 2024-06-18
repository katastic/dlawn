import objects;
import g;
import helper;
import molto;

import std.format;
import std.stdio;
import std.file;
/+
	support maximumLogLength.		[how do we implement rolling buffer then?]
	or maximumFileSize
			- easy case, just use a D array of lines [strings]
			- should apply only to file output, right? That's meaningless for console output right?
			
	- support zipping the output. we could use TERMINAL commands instead of doing it ourselves!
		- p7zip
		
		7zr a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on game.log.7z game.log 
	
	- support a virtual console that can be viewed/scrolling (and colored?) ingame.
		- we could even detect POSIX ANSII color codes in the text stream, and make our own rich-text parser 
		so you can still modify pygmentize/alternative highlighters, and use the same ones.

	there are tons of text compression algorithms as well, but we don't need to go overboard. just a fun reference:
	http://www.mattmahoney.net/dc/text.html
		10.85% 
	
	http://compressionratings.com/sort.cgi?txt2.full+6ne_old hutter prize (linked from previous link)
		18.9% wikipedia ratio
+/

class dialogConsole{
	rect dims;
	size_t scrollIndex; // in pixels? in lines?
	size_t bufferLength; // TODO: get this from log.
	alias dims this;
	logger log; /// reference to our current logger

	float scrollBarWidth=30; // should this be its own dialog element?
	// dialogScrollbar scrollbar;
	uint columnsHeight=32; // how many vertical columns can we see 
	
	void actionScrollUp(){clampLow(--scrollIndex, 0); }
	void actionScrollDown(){clampHigh(++scrollIndex, bufferLength); }
	void actionScrollPageUp(){scrollIndex -= columnsHeight; clampLow(scrollIndex, 0); } // we can move less than a full page. like 2/3rd.
	void actionScrollPageDown(){scrollIndex += columnsHeight; clampHigh(scrollIndex, bufferLength);}
	
	// do we need any other controls? left/right/action/etc
	}

/// DEBUGGER CHANNEL STUFF
/// - Can any object send to a variety of "channels"?
/// so we only get data from objects marked isDebugging=true,
/// and we can choose to only display certain channels like 
/// movement or finite state machine.

/// Do we need a MAPPING setup? "debug" includes "object,error,info,etc"
enum logChannel : string{
	INFO="info",
	ERROR="error",
	DEBUG="debug",
	FSM="FSM"
	}

class pygmentize{// : prettyPrinter
	bool hasStreamStarted=false;
	string style="arduino"; // see [pygmentize -L style] for list of installed styles
	string language="SQL"; // you don't necessarily want "D" for console coloring
	// , you could also create your own custom pygments lexer and specify it here
	//see https://github.com/sol/pygments/blob/master/pygments/lexers/c_cpp.py
	
	// this will be "slower" since we're constantly re-running it with all that overhead
	// we might want to do some sort of batch/buffered version to reduce the number
	// of invocations
	string convert(string input){
		stats.swLogging.start();	
		import std.process : spawnProcess, spawnShell, wait;
	/+	auto pid = spawnProcess(["pygmentize", "-l D"],
                        stdin,
                        stdout,
                        logFile);
      +/
		auto pid = spawnShell(`echo "hello(12,12)" | pygmentize -l D`);
		if (wait(pid) != 0)
			writeln("Compilation failed.");

		stats.swLogging.stop();
		stats.nsLogging = stats.swLogic.peek.total!"nsecs"; // NOTE only need to update this when we actually access it in the stats class
		g.stats.numberLogEntries++;
	
		return input;
		}

	import std.process : spawnProcess, spawnShell, wait, ProcessPipes, pipeProcess, Redirect;
	ProcessPipes pipes;

	string convert2(string input){ /// Complete console call every produced text. (see convert3())
		stats.swLogging.start();	
		import std.process : spawnProcess, spawnShell, wait;

		auto pid = spawnShell(format(`echo "%s" | pygmentize -l %s -O style=%s`, input, language, style));
		if (wait(pid) != 0)
			writeln("Compilation failed.");
			
		stats.swLogging.stop();
		stats.nsLogging = stats.swLogic.peek.total!"nsecs"; // NOTE only need to update this when we actually access it in the stats class
		g.stats.numberLogEntries++;
	
		return input;
		}
		
	string convert3(string input) /// Appears to be stream based version.
		{
   		stats.swLogging.start(); //fixme: does this reset every time? So we're only logging a SINGLE USE, not all of them!?

		if(!hasStreamStarted)
			{
			hasStreamStarted = true;
			string flags = "-s -l d";
			pipes = pipeProcess(
				["pygmentize", "-s", "-l", language, "-O", format("style=%s", style)],
				 Redirect.stdin);
			// https://dlang.org/library/std/process/pipe_process.html
			}

		pipes.stdin.writeln(input);
		pipes.stdin.flush(); // we're already flushing!
		// we could maybe use stdlibc setbuf to set buffer size zero? But it needs before data is sent.
		
		g.stats.numberLogEntries++;
			
		stats.swLogging.stop();
		stats.nsLogging = stats.swLogic.peek.total!"nsecs"; // NOTE only need to update this when we actually access it in the stats class
	
		return input;
		}

	this()
		{
		}
		
	~this()
		{
		writeln("[log] total stats.nsLogging time ", stats.nsLogging/1000/1000, "s");
		writeln("[log] total log entries ", stats.numberLogEntries);
		if(hasStreamStarted){		writeln("[log] Closing stream.");
 pipes.stdin.close();}
		}
	}
/+
interface prettyPrinter
	{
	string convert(string input);
	string convert2(A...)(A input);
	}
+/
class logger
	{
	size_t maxFileSize=1;	
	bool deleteLogAfterCompression=false;
	
	void compress()
		{
		// we could either dump to virtual memory, or,
		import std.process : spawnProcess, spawnShell, wait;
	
		writeln("Compressing logfile");
		string filename = "game.log";
		auto pid = spawnShell(format(`7zr a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on %s %s`, filename~".7z", filename));
		if (wait(pid) != 0)
			writeln("Compilation failed.");

		if(deleteLogAfterCompression)
			{
			auto pid2 = spawnShell(format(`rm %s`, filename));
			if (wait(pid2) != 0)
				writeln("Compilation failed.");
			}
		}
		
	// possible output format:
	//  [0.0000000ms][frame#][category] - "Text"

	// we could have a implied category, and a explicit one though this
	// complicates things because you have to know which you're in.
	
	// con.setChannel("objects")
	// ...
	// con.log("mytext"); - [objects] mytext
	// con.logOverride("overridenChannel", "mytext"); [overriddenChannel] mytext
	
	ulong *currentFrameptr;
		
	bool writeTimeStamp=false; // TODO.   
	bool writeChannel=false;

	bool echoToFile=true;
	bool echoToStandard=false; //stdout
	bool usePrettyPrinter=false; //dump to stdout
	bool usePrettyPrinterDirectly=true; // calls printf itself
	
	pygmentize printer;
	string[] data;
	string logFilePath;
	File logFile;

	this(){
		printer = new pygmentize();
		logFilePath = "game.log";
		logFile = File(logFilePath, "wb");
		
		currentFrameptr = &g.stats.totalFramesPassed;
		}

	~this()
		{
		logFile.close();
		}
	
	void enableChannel(logChannel channel)
		{
		}

	void disableChannel(logChannel channel)
		{
		}
	
	void forceLog(string name, string str) // log without an object attached using a custom name
		{
		// NYI
		}
	
	void log(string str2) /// log just text, no category.
		{
		// do we really need any of this category crap??? Or a simple INFO, DEBUG, ERROR, WARNING, might be fine. but even then.
		float time = stats.swGameStart.peek.total!"nsecs"/1_000_000_000.0;
		string cat = "[test]";
		string str3 = format("[%5.3fs][%d][%s][%s]", time, *currentFrameptr, cat, str2);	
		
		if(echoToStandard)
			writeln(str3);
		if(echoToFile)
			logFile.writeln(str3);
		if(usePrettyPrinter)
			writeln(printer.convert3(str3));
		if(usePrettyPrinterDirectly)
			{
			printer.convert3(str3);
			}
		}		
	
	void log(T)(T obj, string str2)
		{
		if(!obj.isDebugging)return; // If the object isn't set to debug, we ignore it. So we can just set debug flag at will to snoop its data.
		if(echoToStandard)
			writeln(str2);
		if(echoToFile)
			logFile.writeln(str2);
		if(usePrettyPrinter)
			writeln(printer.convert3(str2));
		if(usePrettyPrinterDirectly)
			printer.convert3(str2);
		}	

	void logB(T, V...)(T obj, V variadic) /// variadic version
		{
//		import std.traits;

//		pragma(msg, typeof(variadic)); // debug
		if(echoToStandard)
			{
			foreach(i, v; variadic) // debug
				writeln(variadic[i]); // debug
			}
	//	if(echoToFile)
//			logFile.writeln(str2);
			
		if(usePrettyPrinterDirectly)
			printer.convert3(format(variadic[0], variadic[1..$]));
		}
	}
	
logger log3;

/+
	ijk		array indicies
	rst  	viewport space coordinates?
	uvw		texture/bitmap space coordinates?
	xyz		world space coordinates? (also confusingly relative coordinates but those are rare?)

	we could do capital XYZ but that's confusing too probably.

	xyz		pixels
	rst		relative pixels (width, height, for example)
	ijk		array
	uvw		?
+/
