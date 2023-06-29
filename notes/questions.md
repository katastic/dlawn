we could do pixel shader based lighting, multitexturing, as well as distance from light source.

	a second lighting shader
	
	see https://github.com/liballeg/allegro5/blob/master/examples/ex_shader_multitex.c

         al_set_shader_sampler("tex2", bitmap[1], 1);

see also al_get_default_shader_source for default fragment shaders?


---> SHADER WEBSITE
http://shdr.bkcore.com/#1/lZAxT8MwEIX/yslTClGbiLK0YkJiAzGxUFSZxEldOb7Idlraqv+ds92kUGBgiGL7fXf37h1YiUXXCO0sm72y1ohCWokaVrJetVAp5G6+0BtudlLXsBHFDVRPaBqu6JkElCU0XOpktNCHhYaIlNLAXTgmWZqn2WgOk0noCRpRD1yBCgcyP5M7oRRuPea/4IJ6VlVnBdHjW7iGEl1ycpLSuNHck7VaPhhe35/bTpO+7ipOSyEfZ54+svTPfblzRr53TkSbLVrpiPqp6D6KTsuKzpSF618fOaEf37UpNFgK9SLF9ne5NbgWhR826P8I/6TS6tGC3IvkqxkKIV5jXD4fvxzxF7YIDOH1mw+phYyfT69Ud+mXCqkmxPuWstCVzeLfTmy351qLpQ97vLbs+Ak=


we could make a class that encapsulates allegro so you operate on relevant functions through a pointer and can only have that pointer if allegro is setup correctly.


don't classes automatically have a super pointer or parent pointer? So do the component types need to be sent a pointer? Also do they need to be TEMPLATES and do they need to be CLASSes so we have to heap allocate them? maybe try structs

we probably should setup a logic timer and have it have precedence over graphics. but if we frame lock at 30 fps, how are 
	we doing graphics? Unless we're doing some sort of client-side prediction / extrapolation by continuing to update velocities
	there's nothing changing between frames. So keep 60 Hz logic, but skip frames if we have to?


move molto code to all use the actual internal function since all Allegro 5 functions just chain call to it anyway:

_draw_tinted_rotated_scaled_bitmap_region

[naming]
==========================================================================================================================

	pair	x,y
	ipair	i,j		"integer pair"
	apair	a,m		"angle pair"
	vpair	r,s?	"viewport pair"			but r is used for radius! 
	rpair	rx,ry	[not used]
			u,v		used anywhere? texture coordinates? for loops?

	dimen	w,h		not thrilled about these names!
	idimen	w,h

	likewise, using 

		idimen size;	<--- "size" is a very common term!
		
		also myObject.size.w
		is less nice than myObject.w

also:

	rect	(x,y,w,h)
	irect	(x,y,w,h)	(WARN: currently still using x,y!)


and what about when we need to iterate with for loops? We need additional letters.

[todo]
==========================================================================================================================
 - I removed the implicit TILE_W conversions on pair -> ipair. They broke pixel map collisions when we added a TILE_W != 1 
	and ipairs can be used for more things than just tile locations. If you want a tpair, or, an ipair!tile (user defined attribute)
	maybe. But easiest would be a explicit method for ipair to take a pair (or vice versa) and do a conversion. The biggest
	thing we're doing is simply dividing both components by the TILE_W and TILE_H.


 - all that freaking work setting up DUB and it's slightly _slower_ than a simple bash script.
 - rdmd might be faster? DUB might be faster once the project gets larger?

	--> rename and add:
		- actionUp/down could be on onActionUp
		- need to add RELEASE methods so we can do "hold button to keep moving" level trigger style instead of clonk style 
		edge trigger style.

	- we could add a category system to graph statistics so that you just say you want to time a section and it auto adds. 
	associated array? That way we could make it easier to time random things like "loading map" "processing byte array" etc
	we don't have to have them attached to a GUI graph. Instead we could just have the graph attachable to any timed event stats.

[gameplay/mechanics]
==========================================================================================================================
	- force player to go outside for extra reasons? resources? go from point-a to b? Forcing them to go uotside to endure
	meteor showers. That, or simply have the shower keep collapsing inward. But the solution there would simply be "Stay 
	ahead of the meteor swarm so you never get hit" which isn't as fun as actively avoiding meteors.
	
	- ropes + fall damage?


[molto notes]
==========================================================================================================================

	- we're still not using DUB or cmake/etc?! thank goodness compile times are so short.

	- we should go through the API and decide on names/interfaces
	
		- up/down/left/right is easy and memorized. but, it's not consistent.
		- onUp(), onDown(), onLeft(), onRight() might be better because ON is used for [events], whereas
			[no verb] or doThing() would be [actions].
			
	clean up interfacing so we don't bleed/spaghetti interface things which makes it a PITA to maintain these across new game ideas.

[game notes]
==========================================================================================================================

 - How do we steer from the front/rear instead of the center?
	
	see wheelBase, L
	
	https://asawicki.info/Mirror/Car%20Physics%20for%20Games/Car%20Physics%20for%20Games.html
	http://engineeringdotnet.blogspot.com/2010/04/simple-2d-car-physics-in-games.html
	
	
	- Do we allow slip?
	
[graph.d]
==========================================================================================================================

support EXPORTING (png, or CSV data) the data from a graph based on time, or a trigger.
	- (slow) at the end of every frame, for example.
	- at a specific [event], such as when a certain effect has been triggered.

we could add an EVENT marker (with an icon?) to graphs, as well as a vertical line. 
That way we can denote things that happen at a specific time.

currently we're doing RATES, but we can instead do a full delta time graph. like:

	|		input	logic		draw
	|		.		.			|-----------------------------------|
	|		.		.			|
	|		.		.			|
	|		.		|-----------|
	|				|
	|		|-------|
	|		|
	-------------------------------------------------------------------
	|
	start
	of
	frame

or multiple events or frames. like show 4 frames worth, and we show if one frame is longer than the rest and we mark the start of each one.
	(not sure what usefulness it could be)
	
also other visualizations like waterfall graphs, heatmaps, etc.

specific colors for specific marked regions.

alarm sound/warning flash when something goes out of range / autoexport.
