import std.process, std.path;
import std.stdio;
import std.file;

int main(string[] args){
    string filesList = "";
    int i = 0;
    foreach(string name; dirEntries("./src/", "*.d", SpanMode.shallow)){
        //if(i == 0)
            filesList ~= r"C:\git\dLawn\" ~ buildNormalizedPath(name ~ " ");
        ////else
            //filesList ~= name;
       // writeln(name);
       // writeln(buildNormalizedPath(name ~ " "));
        i++;
    }    
    writeln("Files to compile:");
    writeln("");
    writefln("\"%s\"", filesList);
    writeln("");
    //auto dmd = execute(["dmd", " -debug", "-O", filesList]);
    string toml = r"C:\git\dlawn\toml\src\toml\datetime.d C:\git\dlawn\toml\src\toml\toml.d C:\git\dlawn\toml\src\toml\package.d C:\git\dlawn\toml\src\toml\serialize.d";
    string outputName = "main.exe";
    string lib  = r"-L/LIBPATH:C:\git\dlawn\winbuilddeps\lib\";
    string lib2  = r"-L/LIBPATH:C:\git\dlawn\winbuilddeps\dallegro5";
    string lib3  = r"-L/LIBPATH:C:\git\dlawn\toml";
    string flags = "-debug -O -d"; // debug symbols, optimze, -d is ignore depreciationn for DAllegro for now
    auto dmd = executeShell("dmd -of="~outputName~" " ~ flags ~ " " ~ filesList ~ " " ~ toml ~ " " ~ lib ~ " " ~ lib2 ~ " " ~ lib3);
    if (dmd.status != 0){
        writeln("Compilation failed:\n", dmd.output);        
        }else{
        writefln("Writing to [%s]", outputName);
        writeln("Compilation succeeded:\n\n", dmd.output);
        writeln();
        }
    return 0;
}