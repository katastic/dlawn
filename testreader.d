#!/usr/bin/env rdmd
// file print_words.d

// import the D standard library
import std;
import std.stdio;
import std.file;
import std.regex;
import std.utf;

// https://dlang.org/phobos/std_regex.html

// cat allegro.log.pyg | grep -oP "\[\d*;\d*;\d*;\d*m" | less
auto r = regex(r"(\d*);(\d*);(\d*)m");

void main(string[] args){
	auto bytes = read(args[1]);
	auto b2 = cast(ubyte[])bytes;

	for(int i = 0; i < b2.length; i++)
		{
		ubyte esc = 0x1B; // '' 0x1B, 27 DEC
		// '[' 0x5B, 91 DEC
		// ';' 0x3B, 59 DEC
		// 'm' 0x6D, 109 DEC
		
		// we SHOULD increment after each successful match so we don't double match inside one.
		if(b2[i] == esc && b2[i+1] == '[' && b2[i+3] == 'm')
			{
			writeln("A"~b2[i+2]);
			}
		if(b2[i] == esc && b2[i+1] == '[' && b2[i+4] == 'm')
			{
			writeln("B ", b2[i+2..i+5], " ", cast(char[])b2[i+2..i+5], " - Default Foreground color");	
			}
		if(b2[i] == esc && b2[i+1] == '[' && b2[i+5] == 'm')
			{
			writeln("C ", b2[i+2..i+6], " ", cast(char[])b2[i+2..i+6]);
			}
		if(b2[i] == esc && b2[i+1] == '[' && b2[i+6] == 'm')
			{
			writeln("D ", b2[i+2..i+7], " ", cast(char[])b2[i+2..i+7]);
			}
		if(b2[i] == esc && b2[i+1] == '[' && b2[i+7] == 'm')
			{
			writeln("E ", b2[i+2..i+8], " ", cast(char[])b2[i+2..i+8]);
			}
		if(b2[i] == esc && b2[i+1] == '[' && b2[i+8] == 'm')
			{
			writeln("F ", b2[i+2..i+9], " ", cast(char[])b2[i+2..i+9]);
			}
		if(b2[i] == esc && b2[i+1] == '[' && b2[i+9] == 'm')
			{
			writeln("G ", b2[i+2..i+10], " ", cast(char[])b2[i+2..i+10]);
			}
		if(b2[i] == esc && b2[i+1] == '[' && b2[i+10] == 'm')
			{
			writeln("H ", b2[i+2..i+11], " ", cast(char[])b2[i+2..i+11]);
			string str = cast(string)b2[i+2..i+11];
			foreach(m; str.matchAll(r))
				{
				writeln("HEYO ", m); //m[0] is full match
				auto val1 = m[1]; //38
				auto val2 = m[2]; //5
				auto val3 = m[3]; //241
				}
			}
		if(b2[i] == esc && b2[i+1] == '[' && b2[i+11] == 'm')
			{
			writeln("I ", b2[i+2..i+12], " ", cast(char[])b2[i+2..i+12]);
			}
		if(b2[i] == esc && b2[i+1] == '[' && b2[i+12] == 'm')
			{
			writeln("J ", b2[i+2..i+13], " ", cast(char[])b2[i+2..i+13]);
			}
		if(b2[i] == esc && b2[i+1] == '[' && b2[i+13] == 'm')
			{
			writeln("K ", b2[i+2..i+14], " ", cast(char[])b2[i+2..i+14]);
			}
		}
}
