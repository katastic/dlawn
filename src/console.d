import objects;
import g;
import helper;
import molto;

import std.format;
import std.stdio;
import std.file;
/// DEBUGGER CHANNEL STUFF
/// - Can any object send to a variety of "channels"?
/// so we only get data from objects marked isDebugging=true,
/// and we can choose to only display certain channels like 
/// movement or finite state machine.

/// Do we need a MAPPING setup? "debug" includes "object,error,info,etc"
enum logChannel : string
	{
	INFO="info",
	ERROR="error",
	DEBUG="debug",
	FSM="FSM"
	}

class pygmentize// : prettyPrinter
	{
	bool hasStreamStarted=false;
	string style="arduino"; // see [pygmentize -L style] for list of installed styles
	string language="SQL"; // you don't necessarily want "D" for console coloring
	// , you could also create your own custom pygments lexer and specify it here
	//see https://github.com/sol/pygments/blob/master/pygments/lexers/c_cpp.py
	
	// this will be "slower" since we're constantly re-running it with all that overhead
	// we might want to do some sort of batch/buffered version to reduce the number
	// of invocations
	string convert(string input)
		{
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
	
		return input;
		}

	import std.process : spawnProcess, spawnShell, wait, ProcessPipes, pipeProcess, Redirect;
	ProcessPipes pipes;

	string convert2(string input) /// Complete console call every produced text. (see convert3())
		{
		stats.swLogging.start();	
		import std.process : spawnProcess, spawnShell, wait;

		auto pid = spawnShell(format(`echo "%s" | pygmentize -l %s -O style=%s`, input, language, style));
		if (wait(pid) != 0)
			writeln("Compilation failed.");
			
		stats.swLogging.stop();
		stats.nsLogging = stats.swLogic.peek.total!"nsecs"; // NOTE only need to update this when we actually access it in the stats class
	
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
		pipes.stdin.flush();
		
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
		writefln("total stats.nsLogging time", stats.nsLogging);
		writefln("total log entries", stats.numberLogEntries);
		if(hasStreamStarted)pipes.stdin.close();
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
	import std.file;
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
			printer.convert3(str3);
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

void testLogger()
	{
	writeln("start------------------");
	log3 = new logger;
		
	baseObject u = new baseObject(pair(1, 2), pair(3, 4), g.grass_bmp);
	u.isDebugging = true;
	log3.logB(u, "guy died [%d]", 23);
//	log3.log(u, "word(12, 15.0f)");
	writeln("end--------------------");
	}

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
