// GLOBAL CONSTANTS
// =============================================================================
immutable bool DEBUG_NO_BACKGROUND = false; /// No graphical background so we draw a solid clear color. Does this do anything anymore?
immutable bool AUDIO_ENABLED = false;
// =============================================================================

import std.stdio;
import std.conv;
import std.string;
import std.format;
import std.random;
import std.algorithm;
import std.traits; // EnumMembers
import std.datetime;
import std.datetime.stopwatch : benchmark, StopWatch, AutoStart;
//thread yielding?
//-------------------------------------------
//import core.thread; //for yield... maybe?
//extern (C) int pthread_yield(); //does this ... work? No errors yet I can't tell if it changes anything...
//------------------------------

version(LDC)		{pragma(msg, "using ldc version of dallegro"); pragma(lib, "dallegro5ldc"); }
version(DigitalMars){pragma(msg, "using dmd version of dallegro"); pragma(lib, "dallegro5dmd"); }
version(GNU)		{pragma(msg, "using gdc version of dallegro"); pragma(lib, "dallegro5gdc"); } //NYI

version(ALLEGRO_NO_PRAGMA_LIB){}else{
	pragma(lib, "allegro");
	pragma(lib, "allegro_primitives");
	pragma(lib, "allegro_image");
	pragma(lib, "allegro_font");
	pragma(lib, "allegro_ttf");
	pragma(lib, "allegro_color");
	pragma(lib, "allegro_audio");
	pragma(lib, "allegro_acodec");
}

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;
import allegro5.allegro_audio;
import allegro5.allegro_acodec;
import allegro5.shader;

import testsmod;
import audiomod;
import helper;
import objects;
import viewportsmod;
import molto;
import g;
displayType display;
//=============================================================================

//https://www.allegro.cc/manual/5/keyboard.html
//	(instead of individual KEYS touching ANY OBJECT METHOD. Because what if we 
// 		change objects? We have to FIND all keys associated with that object and 
// 		change them.)
alias ALLEGRO_KEY = ubyte;

/+struct keyset_t
		{
		baseObject obj;
		ALLEGRO_KEY [ __traits(allMembers, keys_label).length] key;
		// If we support MOUSE clicks, we could simply attach a MOUSE in here 
		// and have it forward to the object's click_on() method.
		// But again, that kills the idea of multiplayer.
		}
enum keys_label // not used?
	{
	ERROR = 0,
	UP_KEY,
	DOWN_KEY,
	LEFT_KEY,
	RIGHT_KEY,
	FIRE_UP_KEY,
	FIRE_DOWN_KEY,
	FIRE_LEFT_KEY,
	FIRE_RIGHT_KEY,
	ACTION_KEY
	}
	+/	
float [12]tints = [
      1.0, 0.0, 1.0,
      0.0, 4.0, 1.0,
      1.0, 0.0, 4.0,
      4.0, 4.0, 1.0
   ];
ALLEGRO_SHADER *shader;
float timeIndex=0;
bool initialize()
	{
	al_set_config_value(al_get_system_config(), "trace", "level", "info"); // enable logging. see https://github.com/liballeg/allegro5/issues/1339
	// "debug"
	if (!al_init())
		{
		auto ver 		= al_get_allegro_version();
		auto major 		= ver >> 24;
		auto minor 		= (ver >> 16) & 255;
		auto revision 	= (ver >> 8) & 255;
		auto release 	= ver & 255;

		writefln("The system Allegro version (%s.%s.%s.%s) does not match the version of this binding (%s.%s.%s.%s)",
			major, minor, revision, release,
			ALLEGRO_VERSION, ALLEGRO_SUB_VERSION, ALLEGRO_WIP_VERSION, ALLEGRO_RELEASE_NUMBER);

		assert(0, "The system Allegro version does not match the version of this binding!");
		}else{
				writefln("The Allegro version (%s.%s.%s.%s)",
			ALLEGRO_VERSION, ALLEGRO_SUB_VERSION, ALLEGRO_WIP_VERSION, ALLEGRO_RELEASE_NUMBER);
		}
	
static if (false) // MULTISAMPLING. Not sure if helpful.
	{
	with (ALLEGRO_DISPLAY_OPTIONS)
		{
		al_set_new_display_option(ALLEGRO_SAMPLE_BUFFERS, 1, ALLEGRO_REQUIRE);
		al_set_new_display_option(ALLEGRO_SAMPLES, 8, ALLEGRO_REQUIRE);
		}
	}

	//see https://www.allegro.cc/manual/5/al_set_new_display_flags
	int display_flags = 0;
	al_set_new_display_flags(ALLEGRO_PROGRAMMABLE_PIPELINE | display_flags);

	al_display 	= al_create_display(g.SCREEN_W, g.SCREEN_H);
	queue		= al_create_event_queue();

	if (!al_install_keyboard())      assert(0, "al_install_keyboard failed!");
	if (!al_install_mouse())         assert(0, "al_install_mouse failed!");
	if (!al_init_image_addon())      assert(0, "al_init_image_addon failed!");
	if (!al_init_font_addon())       assert(0, "al_init_font_addon failed!");
	if (!al_init_ttf_addon())        assert(0, "al_init_ttf_addon failed!");
	if (!al_init_primitives_addon()) assert(0, "al_init_primitives_addon failed!");

	al_register_event_source(queue, al_get_display_event_source(al_display));
	al_register_event_source(queue, al_get_keyboard_event_source());
	al_register_event_source(queue, al_get_mouse_event_source());
	
	with(ALLEGRO_BLEND_MODE)
		{
		al_set_blender(ALLEGRO_BLEND_OPERATIONS.ALLEGRO_ADD, ALLEGRO_ALPHA, ALLEGRO_INVERSE_ALPHA);
		}

	import console : logger;
	con = new logger();
				
	// load animations/etc
	// --------------------------------------------------------
	g.loadResources();

	// SETUP viewports
	// --------------------------------------------------------
	g.viewports[0] = new viewport(0, 0, g.SCREEN_W, g.SCREEN_H, 0, 0);
	setViewport2(g.viewports[0]);
	// SETUP world
	// --------------------------------------------------------
	g.world = new g.world_t;
	
	// FPS Handling
	// --------------------------------------------------------
	fps_timer 		= al_create_timer(1.0f);
	screencap_timer = al_create_timer(7.5f);
	al_register_event_source(queue, al_get_timer_event_source(fps_timer));
	al_register_event_source(queue, al_get_timer_event_source(screencap_timer));
	al_start_timer(fps_timer);
	al_start_timer(screencap_timer);
	
	shader = al_create_shader(ALLEGRO_SHADER_PLATFORM.ALLEGRO_SHADER_AUTO);
	const char* psource = r"./data/shaders/ex_shader_pixel.glsl";
	const char* vsource = r"./data/shaders/ex_shader_vertex.glsl";
	assert(shader);
	
	if(!al_attach_shader_source_file(shader, ALLEGRO_SHADER_TYPE.ALLEGRO_VERTEX_SHADER, vsource)){writefln("%s", to!string(al_get_shader_log(shader))); assert(false);}
	if(!al_attach_shader_source_file(shader, ALLEGRO_SHADER_TYPE.ALLEGRO_PIXEL_SHADER, psource)){writefln("%s", to!string(al_get_shader_log(shader))); assert(false);}
	if(!al_build_shader(shader))
		{
		writefln("%s", to!string(al_get_shader_log(shader)));
		assert(false);
		}
		
	return 0;
	}
	
void shutdown() 
	{
	stats.list();
//	con.compress();
	al_destroy_shader(shader);
	}

	
struct displayType
	{
	void start_frame()	
		{
		g.stats.reset();
		reset_clipping(); //why would we need this? One possible is below! To clear to color the whole screen!
//		al_clear_to_color(ALLEGRO_COLOR(.2,.2,.2,1)); //only needed if we aren't drawing a background
		}
		
	void end_frame()
		{
		al_use_shader(null);
		al_flip_display();
		}

	void draw_frame()
		{
		start_frame();
		//------------------
		draw2();
		//------------------
		end_frame();
		}

	void reset_clipping()
		{
		al_set_clipping_rectangle(0, 0, g.SCREEN_W-1, g.SCREEN_H-1);
		}
		
	void draw2()
		{
		
	static if(true) //draw left viewport
		{
		/+
		al_set_clipping_rectangle(
			g.viewports[0].x, 
			g.viewports[0].y, 
			g.viewports[0].x + g.viewports[0].w ,  //-1
			g.viewports[0].y + g.viewports[0].h); //-1
		+/
		static if(DEBUG_NO_BACKGROUND)
			al_clear_to_color(ALLEGRO_COLOR(0, 0, 0, 1));

		g.world.draw(g.viewports[0]);
		}

	static if(false) //draw right viewport
		{
		al_set_clipping_rectangle(
			g.viewports[1].x, 
			g.viewports[1].y, 
			g.viewports[1].x + g.viewports[1].w  - 1, 
			g.viewports[1].y + g.viewports[1].h - 1);

		static if(DEBUG_NO_BACKGROUND)
			al_clear_to_color(ALLEGRO_COLOR(.8,.7,.7, 1));

		g.world.draw(g.viewports[1]);
		}
		
		//Viewport separator
	static if(false)
		{
		al_draw_line(
			g.SCREEN_W/2 + 0.5, 
			0 + 0.5, 
			g.SCREEN_W/2 + 0.5, 
			g.SCREEN_H + 0.5,
			al_map_rgb(0,0,0), 
			10);
		}
		
		// Draw FPS and other text
		display.reset_clipping();
		
		float last_position_plus_one = textHelper(false); // we use the auto-intent of one initial frame to find the total text length for the box
		textHelper(true);  //reset

		al_draw_filled_rounded_rectangle(16, 32, 64+800, last_position_plus_one+32, 8, 8, ALLEGRO_COLOR(.7, .7, .7, .7));

		drawText2(20, "fps[%d] frame#[%d] objrate[%d] -- Obj1[%.2f,%.2f]", g.stats.fps, g.stats.totalFramesPassed,	 
					((*stats["particles"]).drawn +
					(*stats["units"]).drawn + 
					(*stats["bullets"]).drawn + 
					(*stats["dudes"]).drawn +  
					(*stats["tiles"]).drawn) * g.stats.fps, g.world.objects[0].pos.x, g.world.objects[0].pos.y ); 

		float ifNotZeroPercent(T)(T drawn, T clipped) /// percent CLIPPED
			{
			if(drawn + clipped == 0)
				return 100;
			else
				return cast(float)clipped / (cast(float)drawn + cast(float)clipped) * 100.0;
			}

		float ifNotZeroPercent2(statValue v) /// percent CLIPPED
			{
			if(v.drawn + v.clipped == 0)
				return 100;
			else
				return cast(float)v.clipped / (cast(float)v.drawn + cast(float)v.clipped) * 100.0;
			}

		string makeString(string name)
			{
			string str = name ~ " " ~ format("%d", (*stats[name]).drawn);
			return str;
			}

		string makeOf(statValue s)
			{
			return format("%d:%d/%d %.0f%%", s.drawn, s.clipped, s.drawn + s.clipped, ifNotZeroPercent2(s));
			}

		drawText2(20, "meteors[%s] particles[%s] bullets[%s]", 
			makeOf(*stats["meteors"]), 
			makeOf(*stats["particles"]),
			makeOf(*stats["bullets"])
			);
			
		drawText2(20, "dudes[%s] units[%s] structures[%s]",
				makeOf(*stats["dudes"]),
				makeOf(*stats["units"]),
				makeOf(*stats["structures"])
				);

		drawTargetDot(g.mouse_x, g.mouse_y);		// DRAW MOUSE PIXEL HELPER/FINDER

/*
		int val = -1;
		int mouse_xi = (g.mouse_x + cast(int)g.viewports[0].ox + cast(int)g.viewports[0].x)/TILE_W;
		int mouse_yi = (g.mouse_y + cast(int)g.viewports[0].oy + cast(int)g.viewports[0].x)/TILE_H;
		if(mouse_xi >= 0 && mouse_yi >= 0
			&& mouse_xi < 50 && mouse_yi < 50)
			{
			}
*/			
		
		al_draw_textf(
			font1, 
			ALLEGRO_COLOR(0, 0, 0, 1), 
			mouse_x, 
			mouse_y - 30, 
			ALLEGRO_ALIGN_CENTER, "mouse [%d, %d][%.2f, %.2f]", 
				mouse_x, 
				mouse_y, 
				mouse_x + viewports[0].ox, 
				mouse_y + viewports[0].oy);
		}
	}

void logic()
	{
	g.world.logic();
	}

void handleMouseAt(int x, int y, viewport v)
	{
	float cx = x + v.x - v.ox;
	float cy = y + v.y + v.oy;
	
	if(g.world.map2.isInsideMap(pair(cx,cy)))
		{
//		g.world.map.data.set(ipair(pair(cx, cy)), 0);
//		al_set_target_bitmap(g.world.map.layers[1].data);
//		al_draw_pixel(cx, cy, color(1,0,0,1));
		}
	
	}

void execute()
	{
	ALLEGRO_EVENT event;
		
	bool isKey(ALLEGRO_KEY key)
		{
		// captures: event.keyboard.keycode
		return (event.keyboard.keycode == key);
		}

	void isKeySet(ALLEGRO_KEY key, ref bool setKey)
		{
		// captures: event.keyboard.keycode
		if(event.keyboard.keycode == key)
			{
			setKey = true;
			}
		}
	void isKeyRel(ALLEGRO_KEY key, ref bool setKey)
		{
		// captures: event.keyboard.keycode
		if(event.keyboard.keycode == key)
			{
			setKey = false;
			}
		}
		
	bool exit = false;
	while(!exit)
		{
		while(al_get_next_event(queue, &event))
			{
			switch(event.type)
				{
				case ALLEGRO_EVENT_DISPLAY_CLOSE:
					{
					exit = true;
					break;
					}
				case ALLEGRO_EVENT_KEY_DOWN:
					{
					isKeySet(ALLEGRO_KEY_ESCAPE, exit);

					isKeySet(ALLEGRO_KEY_SPACE, g.key_space_down);
					isKeySet(ALLEGRO_KEY_W, g.key_w_down);
					isKeySet(ALLEGRO_KEY_S, g.key_s_down);
					isKeySet(ALLEGRO_KEY_A, g.key_a_down);
					isKeySet(ALLEGRO_KEY_D, g.key_d_down);		
					isKeySet(ALLEGRO_KEY_E, g.key_e_down);		

					isKeySet(ALLEGRO_KEY_M, g.key_m_down);
					isKeySet(ALLEGRO_KEY_I, g.key_i_down);
					isKeySet(ALLEGRO_KEY_J, g.key_j_down);
					isKeySet(ALLEGRO_KEY_K, g.key_k_down);
					isKeySet(ALLEGRO_KEY_L, g.key_l_down);
					isKeySet(ALLEGRO_KEY_Q, g.key_q_down);
					
					if(g.key_e_down)
						{
						g.world.objects[0].actionFire();
						key_e_down = false;
						}
					
					if(g.key_q_down)//handleMouseAt(g.mouse_x, g.mouse_y, g.viewports[0]);
						{
						writeln("q is down");
						viewport v = viewports[0];
						auto p = g.world.objects[0].pos;
						int w = 20;
						int h = 20;
						g.world.map2.drawCircle(p, 4, 0);
						g.key_q_down = false;
						}
					break;
					}
					
				case ALLEGRO_EVENT_KEY_UP:				
					{
					isKeyRel(ALLEGRO_KEY_SPACE, g.key_space_down);
					isKeyRel(ALLEGRO_KEY_W, g.key_w_down);
					isKeyRel(ALLEGRO_KEY_S, g.key_s_down);
					isKeyRel(ALLEGRO_KEY_A, g.key_a_down);
					isKeyRel(ALLEGRO_KEY_D, g.key_d_down);

					isKeyRel(ALLEGRO_KEY_M, g.key_m_down);
					isKeyRel(ALLEGRO_KEY_I, g.key_i_down);
					isKeyRel(ALLEGRO_KEY_J, g.key_j_down);
					isKeyRel(ALLEGRO_KEY_K, g.key_k_down);
					isKeyRel(ALLEGRO_KEY_L, g.key_l_down);
					isKeyRel(ALLEGRO_KEY_Q, g.key_q_down);
					break;
					}

				case ALLEGRO_EVENT_MOUSE_AXES:
					{
					g.mouse_x = event.mouse.x;
					g.mouse_y = event.mouse.y;
					g.mouse_in_window = true;
					break;
					}

				case ALLEGRO_EVENT_MOUSE_ENTER_DISPLAY:
					{
					writeln("mouse enters window");
					g.mouse_in_window = true;
					break;
					}
				
				case ALLEGRO_EVENT_MOUSE_LEAVE_DISPLAY:
					{
					writeln("mouse left window");
					g.mouse_in_window = false;
					break;
					}

				case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
					{
					if(!g.mouse_in_window)break;
					
					if(event.mouse.button == 1)
						{
						}
					if(event.mouse.button == 2)
						{
						}
					break;
					}
				
				case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
					{
					g.mouse_lmb = false;
					break;
					}
				
				case ALLEGRO_EVENT_TIMER:
					{
					if(event.timer.source == screencap_timer)
						{
						al_stop_timer(screencap_timer); // Do this FIRST so inner code cannot take so long as to re-trigger timers.
						writeln("saving screenshot [screen.png]");
						al_save_screen("screen.png");	
//	auto sw = StopWatch(AutoStart.yes);
//						al_save_bitmap("screen.png", al_get_backbuffer(al_display));
//				sw.stop();
//	int secs, msecs;
//	sw.peek.split!("seconds", "msecs")(secs, msecs);
//	writefln("Saving screenshot took %d.%ds", secs, msecs);
			}						
					if(event.timer.source == fps_timer) //ONCE per second
						{
						g.stats.fps = g.stats.framesPassed;
						g.stats.framesPassed = 0;
						}
					break;
					}
				default:
				}
			}

		logic();
		display.draw_frame();
		g.stats.framesPassed++;
		g.stats.totalFramesPassed++;
//		Fiber.yield();  // THIS SEGFAULTS. I don't think this does what I thought.
//		pthread_yield(); //doesn't seem to change anything useful here. Are we already VSYNC limited to 60 FPS?
		}
	}

	
void setupFloatingPoint()
	{
/+ WARN FIXME not compiling with recent install of dmd  kat2023  
  If this errors, update to newest version of D +/

	import std.math.hardware : FloatingPointControl; 
	FloatingPointControl fpctrl;
    fpctrl.enableExceptions(FloatingPointControl.severeExceptions);
	/// enables hardware trap exceptions on uninitialized floats (NaN), (I would imagine) division by zero, etc.
	// see 
	// 		https://dlang.org/library/std/math/hardware/floating_point_control.html
	// we could disable this on [release] mode if necessary for performance
	}

//=============================================================================
int main(string [] args)
	{
	bool modeRunAllegroTests=false;
	bool modeRunConsoleTests=false;
	setupFloatingPoint();	
	writeln("args length = ", args.length);
	foreach(size_t i, string arg; args)
		{
		writeln("[",i, "] ", arg);
		}
		
	if(args.length >= 2)
		{
		import std.string : isNumeric;
		if(args[1].isNumeric)
			{
			g.SCREEN_W = to!int(args[1]);
			g.SCREEN_H = to!int(args[2]);
			writeln("New resolution is ", g.SCREEN_W, "x", g.SCREEN_H);
			}else{
			switch(args[1].toLower)
				{
				case "test":
					modeRunConsoleTests=true;
				break;
				case "allegrotest":
					modeRunAllegroTests=true;
				break;
				case "testfail1": // works with gdb break _d_assert
				// (shows a working stack but variable "frame base" is broken) when using GDB
				// compiling with LDC might be better?
				/+
	LDC
		(gdb) bt
		#0  0x00007ffff7967f20 in _d_assert_msg () from /lib/x86_64-linux-gnu/libdruntime-ldc-shared.so.100
		#1  0x000055555558f645 in _Dmain (args=...) at ./src/main.d:546
		(gdb) bt full
		#0  0x00007ffff7967f20 in _d_assert_msg () from /lib/x86_64-linux-gnu/libdruntime-ldc-shared.so.100
		No symbol table info available.
		#1  0x000055555558f645 in _Dmain (args=...) at ./src/main.d:546
				modeRunAllegroTests = false
				modeRunConsoleTests = false

	DigitalMars: [with -gdwarf=5 !!!!]

		(gdb) bt
		#0  0x00005555556da8f0 in _d_assert_msg ()
		#1  0x00005555556c2753 in _Dmain (args=<error reading variable: Could not find the frame base for "_Dmain".>)
			at /usr/include/dmd/druntime/import/core/internal/entrypoint.d:560
		(gdb) bt full
		#0  0x00005555556da8f0 in _d_assert_msg ()
		No symbol table info available.
		#1  0x00005555556c2753 in _Dmain (args=<error reading variable: Could not find the frame base for "_Dmain".>)
			at /usr/include/dmd/druntime/import/core/internal/entrypoint.d:560
				modeRunAllegroTests = <error reading variable modeRunAllegroTests (Could not find the frame base for "_Dmain".)>
				modeRunConsoleTests = <error reading variable modeRunConsoleTests (Could not find the frame base for "_Dmain".)>
				__r2701 = <error reading variable __r2701 (Could not find the frame base for "_Dmain".)>
				__key2700 = <error reading variable __key2700 (Could not find the frame base for "_Dmain".)>
				arg = <error reading variable arg (Could not find the frame base for "_Dmain".)>
				i = <error reading variable i (Could not find the frame base for "_Dmain".)>

	DigitalMars: [WITHOUT gdwarf=5]

		(gdb) bt
		#0  0x00005555556da8f0 in _d_assert_msg ()
		#1  0x00005555556c2753 in _Dmain (args=...) at ./src/main.d:578
		(gdb) bt full
		#0  0x00005555556da8f0 in _d_assert_msg ()
		No symbol table info available.
		#1  0x00005555556c2753 in _Dmain (args=...) at ./src/main.d:578
				modeRunAllegroTests = false
				modeRunConsoleTests = false
				__r2701 = {"/home/novous/Desktop/git/dlawn/main", "testfail1"}
				__key2700 = 2
				arg = "testfail1"
				i = 1

	GDB documentation says "Produce debugging information in DWARF format (if that 
	is supported). The value of version may be either 2, 3, 4 or 5; the default 
	version for most targets is 4. DWARF Version 5 is only experimental. "

				+/
					assert(false, "fail1");
				break;
				case "testfail2": // not caught
					throw new Exception("fail2");
				break;
				case "testfail3": // not caught
					import std.exception : enforce;
					enforce(false, "fail3"); 
				break;
				default:
					writeln("ERROR - Unhandled mode argument! [", args[1].toLower, "]");
					return 1;
				break;
				}
			}
		}

	if(modeRunConsoleTests)
		{
		runConsoleTests();
		}else{
	
		return al_run_allegro(
			{
			initialize();
			if(modeRunAllegroTests)
				runAllegroTests();
			else 
				execute();
			shutdown();
			return 0;
			});
		}
	return 0;
	}
