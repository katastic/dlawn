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

pragma(lib, "toml");

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

alias ALLEGRO_KEY = ubyte;
//=============================================================================

//https://www.allegro.cc/manual/5/keyboard.html
//	(instead of individual KEYS touching ANY OBJECT METHOD. Because what if we 
// 		change objects? We have to FIND all keys associated with that object and 
// 		change them.)

import std.conv : emplace;

struct myTestStruct
	{
	this(int x, int y)
		{
		}
	}

void constructTest()
	{
	myTestStruct temp;
	emplace!myTestStruct(&temp, 2, 3);
	}

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
      1.0, 0.5, 1.0,
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
	with (ALLEGRO_DISPLAY_OPTIONS) // https://www.allegro.cc/manual/5/al_set_new_display_option
		{
		al_set_new_display_option(ALLEGRO_SAMPLE_BUFFERS, 1, ALLEGRO_REQUIRE);
		al_set_new_display_option(ALLEGRO_SAMPLES, 8, ALLEGRO_REQUIRE);
		}
	}

	//see https://www.allegro.cc/manual/5/al_set_new_display_flags
	int display_flags = 0;
	al_set_new_display_flags(ALLEGRO_OPENGL_3_0 | ALLEGRO_PROGRAMMABLE_PIPELINE | display_flags);

	al_display 	= al_create_display(g.SCREEN_W, g.SCREEN_H);
	queue		= al_create_event_queue();
	with(ALLEGRO_DISPLAY_OPTIONS)
		writeln("OpenGL version reported: ", al_get_display_option(al_display, ALLEGRO_OPENGL_MAJOR_VERSION), ".", al_get_display_option(al_display, ALLEGRO_OPENGL_MINOR_VERSION));

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
				
	extraLogsAfterAllegro();
	
	al_set_new_bitmap_flags(ALLEGRO_VIDEO_BITMAP); // this should be the default...
		 // https://www.allegro.cc/manual/5/al_set_new_bitmap_flags
		 // mipmapping? premultiplied alpha?
				
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
	
	// should this throw an exception since this error can occur by user damage and not just [design error]
	bool buildShader(ref ALLEGRO_SHADER *sh, string pixelShaderPath, string vertexShaderPath)
		{		
		sh = al_create_shader(ALLEGRO_SHADER_PLATFORM.ALLEGRO_SHADER_AUTO);
		assert(sh);
		
		if(!al_attach_shader_source_file(shader, ALLEGRO_SHADER_TYPE.ALLEGRO_VERTEX_SHADER, vertexShaderPath.toStringz)){writefln("%s", to!string(al_get_shader_log(sh))); assert(false, "FAILED TO BUILD VSHADER");}
		if(!al_attach_shader_source_file(shader, ALLEGRO_SHADER_TYPE.ALLEGRO_PIXEL_SHADER, pixelShaderPath.toStringz)){writefln("%s", to!string(al_get_shader_log(sh))); assert(false, "FAILED TO BUILD PSHADER");}
		if(!al_build_shader(sh)){
			writefln("%s", to!string(al_get_shader_log(sh)));
			assert(false, "FAILED TO BUILD SHADER");
			}
		return true;
		}
	
	string psource = r"./data/shaders/ex_shader_pixel.glsl";
	string vsource = r"./data/shaders/ex_shader_vertex.glsl";
	buildShader(shader, psource, vsource);
	
	return 0;
	}
	
void shutdown() 
	{
	stats.list();
	writeln("total frames passed ", g.stats.totalFramesPassed);
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

		al_draw_filled_rounded_rectangle(16, 32, 64+1000, last_position_plus_one+32, 8, 8, ALLEGRO_COLOR(.7, .7, .7, .7));

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
			return format("%d:%d/%d %.0f%% (All/sec=%.0f)", s.drawn, s.clipped, s.drawn + s.clipped, ifNotZeroPercent2(s), s.allocationsPerSecond);
			}

		drawText2(20, "meteors[%s] particles[%s] bullets[%s]", 
			makeOf(*stats["meteors"]), 
			makeOf(*stats["particles"]),
			makeOf(*stats["bullets"])
			);
			
		drawText2(20, "objects[%s] units[%s] structures[%s]",
				makeOf(*stats["objects"]),
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
	
//	if(g.world.map2.isInsideMap(pair(cx,cy)))
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
						g.world.units[0].actionFire();
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
					
					// GUI dialog mouse movement notifications:
					world.grids.eventHandleMouse(pair(mouse_x, mouse_y));
					
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
						world.grids.onClick(pair(mouse_x, mouse_y));
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
						g.stats.onTickSecond();
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

void extraLogsAfterAllegro()
	{
// see https://www.allegro.cc/manual/5/al_set_new_display_option
	writefln("Max texture size reported: %d", al_get_display_option(al_display, ALLEGRO_DISPLAY_OPTIONS.ALLEGRO_MAX_BITMAP_SIZE));
	}

void testMemoryPool()
	{
	memoryPool!pair mp;
	
	writeln("\t\t\t\t\t", mp.getall(), " free:", mp.howManyFree);
	for(int i = 0; i < 3; i++)mp.add(pair(i,i));
	writeln("\t\t\t\t\t", mp.getall(), " free:", mp.howManyFree);
	mp.remove(1);
	writeln("\t\t\t\t\t", mp.getall(), " free:", mp.howManyFree);
	mp.add(pair(5,0));
	writeln("\t\t\t\t\t", mp.getall(), " free:", mp.howManyFree);
	mp.add(pair(6,0));
	writeln("\t\t\t\t\t", mp.getall(), " free:", mp.howManyFree);
	mp.add(pair(7,0));
	writeln("\t\t\t\t\t", mp.getall(), " free:", mp.howManyFree);
	mp.remove(3);
	writeln("\t\t\t\t\t", mp.getall(), " free:", mp.howManyFree);
	auto p = pair(8,0);
	mp.add(p);
	writeln("\t\t\t\t\t", mp.getall(), " free:", mp.howManyFree);
	mp.remove(p);
	writeln("\t\t\t\t\t", mp.getall(), " free:", mp.howManyFree);
	mp.clearAll;
	writeln("\t\t\t\t\t", mp.getall(), " free:", mp.howManyFree);
	
	auto p2 = pair(2,352);
	mp ~= p2;
	writeln(mp[0]);
	writeln("\t\t\t\t\t", mp.getall(), " free:", mp.howManyFree);
	}

immutable size_t memSize = 20000;

struct memoryPool(T)
	{
	size_t size=memSize;
	size_t usedSize=0;
	T[memSize] data;
	bool[memSize] isUsed;  // <-- bad for cache unless we batch or combine with the data[] entries
	size_t totalFree=memSize; // do we want/need this? Someone can request how much is left.
	
	@nogc auto opSlice()
		{
	//	writeln("opSlice:", (size-totalFree-1));
		return data[0..(size-totalFree)];
		} // we cannot use external foreach because the 'length' is less than the total length!
	
	/*
		don't forget @nogc
		https://stackoverflow.com/questions/32538563/implement-opapply-with-nogc-and-inferred-parameters
	*/

	// GOOD PROBLEM:
	/*
		if we want to iterate over all valid entries:
			- if we have ONE element in a 1 million entry static array, we're going to scan EVERY single element 
			and check isUsed or =null! (though we don't want null because then we're using pointers and extra indirection)
			- one optimization regardless is to treat in blocks of 512 because cacheline=64 bytes * 8 =512 bits
			- or somehow pack the cached bit WITH (T) datatype but will that still mess with the structs? We'd ideally
			want [X number of type T structs packed in 64 bytes - 1] or maybe even -2 or -3 if they're small but
			we can do it
			
			- however, we've got a new problem. Even if we keep it contigious and move LAST_ELEMENT into the slot
			of the most [recently deleted element], now we're invalidating all pointers/indexes into this array!
			
			- we might want a cascade of sub-static pools. So once all items in a sub-pool are deleted we no 
			longer iterate over it, but otherwise we iterate over the entire sub-pool. 
				So e.g.: 1 million entries into 1000 pools = 1000 elements each.
				and at worst, with a single element, we're iterating over 1000 elements. 
					We can optimize this sub-stacks for cacheline size, say 512 elements.
					ceil(1 million/512)=1954 subpools.
					
					realistically we're at 100000 objects or possibly far less as scripting and such will 
					far dwarf the content access.
					
					>>The only thing we really need to avoid from the default vector array is ALLOCATIONS.<<
					
			- okay but again, regardless of two-tier or 1-tier static pools. How do we seemlessly FOREACH
			this shit or is that impossible? How do we return a subset of [valid entires] compared to [total set]
			quickly? We're talking about a FUCK TON of if statements!
			
			[1 million static pool] = 1 million if statements MINIMUM
			
			and thats if we're not allocating some temporary SUBSET bullshit every return. 
			
			if we're just:
			
			for(int i =0; i < 1M; i++)
				{
				if(isUsed)doThingOn(data[i]);
				}
				
			now we might be able to vectorize that into at least checking isUsed on 512 elements at a time.
			
			But, wouldn't it be FAR QUICKER to take the hit on allocation/deallocation time, and
			[move LAST element to DELETED slot, and adjust reported size/length] so it's now:
			
			for(int i=0; i < ARRAY_SIZE; i++)  // no if statement branch cost AND no overhead on empty elements 
				{
				doThingOn(data[i]);
				}
				
			BUT, if we do have references, how do we deal with MOVED references?
				onDelete we basically have to scan:
			
			onDelete()
				{
				int deadIndex = 312;
				for(int i=0; i < ARRAY_SIZE; i++)   
					{
					hasAnyReferenceTo(deadIndex, data[i]); //check if its storing any dead references
					}
				int oldIndex = 401;
				int newIndex = 312;
				for(int i=0; i < ARRAY_SIZE; i++)   
					{
					hasAnyReferenceTo(deadIndex, data[i]); // if anyone has 401 references, update to point to 312; 
					}
				}
	*/
	
	//@nogc bool empty(){return true;}
    //@nogc auto front(){return tuple(K.init, V.init);}
    //@nogc void popFront(){}
	
	// https://dlang.org/library/std/range/interfaces/input_range.html
	// http://ddili.org/ders/d.en/foreach_opapply.html
	 /+int opApply(int delegate(ref int, ref int) dg) const {
        int result = 0;
		immutable long begin = 0;
		long end = size;
        for (int i = begin; (i + 1) < end; i += 5) {
            int first = i;
            int second = i + 1;

            result = dg(first, second);

            if (result) {
                break;
            }
        }

        return result;
    }+/
	
	@nogc size_t length()
		{
		return size-totalFree;
		}
	
	@nogc ref T opIndex(size_t i){
        return data[i];
		}
	
	//https://forum.dlang.org/post/heeaancctxcbjcsddmhc@forum.dlang.org	
	@nogc auto opOpAssign(string op:"~")(T i){ 
//		if(op =="~=" || op == "-="){
		add(i);
		}	
	
	@nogc void add(T value){ // worst O(n)
		size_t i = 0;
		while(isUsed[i] == true)
			{
			i++;
			assert(i<size, "Tried to add to a full static pool! This is a design failure.");
			}
		data[i] = value;
		isUsed[i] = true;
		totalFree--;
		usedSize++;
		//writeln("inserting ", data[i], " into slot: ", i);
		}
	
	@nogc T get(size_t index){
		return data[index];
		}

	@nogc T[memSize] getall(){
		return data;
		}
	
	@nogc size_t howManyFree(){
		return totalFree;
		}
	
	@nogc void remove2(size_t index){ // O(1)		not same as remove since you don't use data = data.remove(23);
		assert(index<size, "index went passed the pool!");
		assert(isUsed[index] == true, "tried to delete an already deleted index. Confirm code correctness.");
		isUsed[index] = false;
		data[index] = T.init;
		totalFree++;
		usedSize--;
	//	writeln("1 removed object at index ", index, " totalFree:", totalFree);
		} // we COULD reset data back to NaN or .init or whatever for debugging. But otherwise it should not matter.

	 @nogc ref memoryPool!T remove(size_t index){ // O(1)		not same as remove since you don't use data = data.remove(23);
		assert(index<size, "index went passed the pool!");
		assert(isUsed[index] == true, "tried to delete an already deleted index. Confirm code correctness.");

		// if were not the last element, move the last element here.
		if(index != usedSize-1) 
			{
			data[index] = data[usedSize-1];
			// clear old moved index
			isUsed[usedSize-1] = false;
			data[usedSize-1] = T.init;
			}else{
			// clear index
			isUsed[index] = false;
			data[index] = T.init;
			}
		
		totalFree++;
		usedSize--;
		//writeln("2 removed object at index ", index, " totalFree:", totalFree);
		return this;
		} // we COULD reset data back to NaN or .init or whatever for debugging. But otherwise it should not matter.
	
	@nogc void remove(T object){ // O(N)
		int index=-1;
		for(int i = 0; i < size; i++)
			{
			if(data[i] is object)
				{
				remove(i);
				index = i;
				break;
				}
			}
//		assert(index != -1, "object wasn't found in remove(T object)!");
		//writeln("3 removed object at index ", index, " totalFree:", totalFree);
		}

	@nogc void clearAll(){
		for(int i = 0; i < size; i++){isUsed[i] = false; data[i] = T.init;}
		totalFree=size;
		usedSize=0;

//		writeln("emptied.");
		}
	}

//=============================================================================
int main(string [] args)
	{
	string testModeArg="";
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
			testModeArg=args[1].toLower;
			}
		}

	if(testModeArg != "")
		{
		import aimod : test__angleToward;
		switch(testModeArg.toLower)
			{
			case "test":
				runConsoleTests();
			break;
			case "testangle":
				test__angleToward();
			break;
			case "allegrotest":
				runAllegroTests();
			break;
			case "testcache":
				testCachedAA();
			break;
			case "testmemorypool":
				testMemoryPool();
			break;
			case "teststaticstrings":
				testStaticStrings();
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
