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
