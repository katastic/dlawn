import toml;
import std.stdio;

// https://github.com/dlang-community/toml
// https://toml.dpldocs.info/v2.0.1/toml.toml.TOMLValue.html

class configType
	{
	TOMLDocument doc;
		
	void save(string path)
		{
		}
		
	void load(string path)
		{
		import std.file : read;
		doc = parseTOML(cast(string)read(path));
		// writeln(data["objects"]);
		// pragma(msg, typeof(data["objects"]));
		foreach(o; doc["main"].array)
			{
			writeln(o); // how do we parse object types? This is a pretty specialized handler then?
			}
		}
	}
