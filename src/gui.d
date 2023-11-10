import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import g, molto;
import graph;
import viewportsmod;
import std.string;
import std.stdio;

void drawTitledWindow(pair pos, idimen size) //why is ths position AND idimen?
	{
	
	}


// do we want this kind of thing to do built-in clipping?
// we only REALLY need an pair offset, and viewport. Each subsequent call adds their window position
// and forwards that as the new offset. We're not doing rotations so unless we're doing clipping we
// don't need any extra information. (linear/stateless transformation?)
struct viewStack
	{
	pair x,y;
	pair w,h;
	int level; //draw callstack depth number 
	viewport v;
	}

// how to handle drag and drop? 
// icons? can also system shock 2 style inventory grid
// - how do we handle PIXEL PERFECT (or bounding box) matching of an item vs mouse touching the background tile? (if wanted)
// - sort feature

// we need an UNDO feature if the placement is invalid or cancelled. 

class dragAndDropGrid
	{
	rect canvas; // x,y screen coords, then w/h 
	//pair canvasPos; // do we care about a width/height?
//	rect canvas;
	
	bool eventClickAt(pair screenPos)
		{
		writeln("eventClickAt(", screenPos, ")");
	//	auto p = pair(screenPos.x - canvasPos.x, screenPos.y - canvasPos.y);
		//if(p.x < 0 || p.y < 0)return false;
		
		return checkForItemsGivenClick(screenPos);
		}
	
	bool checkForItemsGivenClick(pair hitCanvasPos)
		{
		import helper : isWithin;

		foreach(i; items)
			{
			pair itemMousePosition = i.getMousePosition();
	//		writeln("searching:", i.name);
//			writeln("hitCanvasPos ", hitCanvasPos, " vs ", "itemMousePosition ", itemMousePosition);
			
			if(
				hitCanvasPos.isWithin(itemMousePosition, pair(itemMousePosition, gridSize, gridSize))
				){
				i.eventActivate();
				con.log(i.name ~ " was found");
				return true;
				}
			}
		return false;
		}
	
	pair getWidthHeightFromGridSize(ipair grid)
		{
		return pair(gridSize*grid.i,gridSize*grid.j);
		}
	
	this()
		{
		int i=16;
		int j=5;
		gridDim = ipair(16, 5);
		canvas = rect(pair(100.0, 100.0), getWidthHeightFromGridSize(gridDim));
			{
			draggableItem d = new draggableItem(ipair(0,0), ipair(1,1), this, bh["fountain"]);
			d.name = "sword";
			items ~= d;
			}
			{
			draggableItem d = new draggableItem(ipair(0,1), ipair(1,1), this, bh["dude"]);
			d.name = "shield";
			items ~= d;
			}
			{
			draggableItem d = new draggableItem(ipair(1,1), ipair(1,1), this, bh["carrot"]);
			d.name = "armor";
			items ~= d;
			}
		}
		
//	int[16][128] gridLookupTable;  // each occupied tile
	rect dim;
	
	draggableItem[] items;
	int gridSize = 32;
	ipair gridDim;
	
	//dostuff()
	// the idea is, for the grid, each cell contains the lookup index of the relevant item in the items[] list.
	// if we find an empty place for our item (easy to search surrounding tiles on a mouse click), we just add the 
	// number to the items[] list.
	
	// essential: cohesion between the two data structures. alternatively, don't violate the one-place principle and
	// run some algorithm/search every click/sort/etc and only have either the grid, or (more likely) the items list.
	//
	// if using only the list:
	// 	- draw inventory: simple. iterate through list and draw them, no ordering required.
	//  - selecting item: mouse click test traverses all known items. fine for small lists
	//  - moving item: "test click" on SEND mouse tile location, and any nearby ones given the shape of the desired item  
	
	void drawBackground()
		{
		}
		
	void drawGrid()
		{
		int w = cast(int)canvas.w/gridSize;
		int h = cast(int)canvas.h/gridSize;
		for(int i = 0; i < w; i++)
			{
			al_draw_line(
						canvas.x + gridSize*(i), 
						canvas.y, 
						canvas.x + gridSize*(i), 
						canvas.y + canvas.h-gridSize, white, 1.0f);
			}
		for(int j = 0; j < h; j++)
			{
			al_draw_line(
						canvas.x             ,
						canvas.y + gridSize*(j), 
						canvas.x + canvas.w-gridSize, 
						canvas.y + gridSize*(j), white, 1.0f);
			}
		}
	
	void draw(viewport v)
		{
		drawBackground();
		drawGrid();
		foreach(i; items)
			{
			i.draw(canvas, v);
			}
		}
	
	}

// when we [[release]] do we reset on failure, or simply keep holding it until a valid is placed?
// maybe it depends on the event. pressing [escape] or [right click] is reset for example.
class draggableItem
	{
	bool hasBeenActivated = false;
	
	bool eventActivate()
		{
		hasBeenActivated = !hasBeenActivated;
		con.log(name ~ " has been activated!");
		return true;
		} /// double click or right-click activate
	// do we want other event options? right-click drop down options like SS1 change burst type, or ammo type?	
	
	bool eventDropIntoWorld()
		{
		return true;
		}
	
	bool eventTrash()
		{
		return true;
		// delete me?
		}
	
	
	pair getMousePosition()
		{
		auto p = pair(
			owner.canvas.x + gridPosition.i*owner.gridSize, 
			owner.canvas.y + gridPosition.j*owner.gridSize); // this can't be right?
		writeln("getMousePosition = ", p);
		return p;
		}

	this(ipair _gridPosition, ipair _bulkSize, dragAndDropGrid _owner, bitmap* b)
		{
		owner = _owner;
		gridPosition = _gridPosition;
		bulkSize = _bulkSize;
		image = b;
		}
		
	dragAndDropGrid owner; // for requesting deletion, and drawing gridsize, and canvas dim.
	bool isPickedUp; // if true, mouse coordinates can float to follow mouse and when set 
					// back we update to table coordinates, on fail to set, we reset back to mouseX, mouseY
	
//		float tableMouseX, tableMouseY; //screen/mouse position of our top-left point in table FROM gridPosition
//		float floatingMouseX, floatingMouseY; // are these TABLE RELATIVE though or SCREEN RELATIVE? What if we're dragging between windows or out of window!
//		float mouseWidth, mouseHeight; /// pixel width/height of graphic. Could also just use image->w,h
	
	void pickUp()
		{
		isPickedUp=true;
		}

	void attemptPlace(pair goalPosition)
		{
		isPickedUp=false;
		if(isOutsideWindow(goalPosition))
			{
			dropItemIntoWorld(); // call drop item or whatever.
			removeMeFromList();
			return;
			} else if (canMoveTo(goalPosition))
			{
			moveItemTo(goalPosition);
			} else {
			return; // do nothing
			}
		}
		
	bool canMoveTo(pair goal)
		{
		// grid owner should be doing this.
		assert(false);
		return false;
		}
		
	void moveItemTo(pair goal)
		{
		// grid owner should be doing this.
		assert(false);
		}
		
	void cancelPlace()
		{
		isPickedUp = false;
		}
		
	bool isOutsideWindow(pair testPos)
		{
		rect dim = owner.dim;
		return (testPos.x < dim.x || testPos.x > dim.x+dim.w-1 ||
				testPos.y < dim.y || testPos.y > dim.y+dim.y-1)
			? true : false;
		}
		
	void dropItemIntoWorld(){}
	void removeMeFromList(){}
	
	ipair gridPosition; // where in inventory is it if it's placed. top-left
	ipair bulkSize; // width/height of item (no support for L-shaped/odd-shaped items. 1x1. 3x1, 2x2, etc)
	bool flipVertical; // if we have system shock 1/remake style rotatable items
	bool flipHorizontal;
	string name;
	string description;
	bitmap* image; // no animated/modifiable images
	void* myItemPtr; //for command callbacks

	void draw(rect canvas, viewport v)
		{
		drawBitmap(image, 
			pair(v.x + canvas.x + gridPosition.i*owner.gridSize, 
				 v.y + canvas.y + gridPosition.j*owner.gridSize), hasBeenActivated);
		}
	}

/// of all areas on screen, given Z order, a mouse click, drag, etc command goes to that zone owner.
/// a window would have a window on bottom, a title bar above that, and window buttons on top of that	
class mouseZone // name
	{
	// dimen/idimen, or rect/irect whats' the difference
	dimen dim;
	void* componentOwner; // window, canvas, titlebar, button, etc
	}

class viewBox
	{
	pair pos;
	idimen size;
	float alpha=1.0;
	string title="";
	size_t selectedGraph=0;
	intrinsicGraph!float[] graphs;
	
	void drawTitle()
		{
		drawText(pos.x, pos.y, white, "asdlgknasdglkgands");
		}
		
	void drawDialog()
		{
		al_draw_filled_rectangle(pos.x, pos.y, pos.x + size.w, pos.y + size.h, color(1,0,0,1));
		}
	
	void onDraw(viewport v)
		{
		drawTitle();
		drawDialog();
		if(graphs.length > 0)
			{
			graphs[selectedGraph].drawInterally(v, pos, size);
			}
		}

	void updateTitleText()
		{
		title = format("graph %d / %d - %s", selectedGraph+1, graphs.length, graphs[selectedGraph].name);
		}
		
	void actionPrevious()
		{
		selectedGraph--;
		if(selectedGraph < 0)selectedGraph = cast(int)graphs.length - 1;
		if(graphs.length == 0)selectedGraph = 0;
		updateTitleText();
		}
		
	void actionNext()
		{
		selectedGraph++;
		if(selectedGraph > cast(int)graphs.length-1)selectedGraph = 0;
		if(graphs.length == 0)selectedGraph = 0;
		updateTitleText();
		}
	}

class element
	{
	pair pos;
	idimen size;
	}

class button : element
	{
	void onClick(){}
	void onRelease(){}
	}
	
class dialogBox : element
	{
	string text;
	button[] buttons;
	}

class yesNoDialog : dialogBox /// modal dialog
	{
	// yes/no  , okay/cancel
	this(string _text)
		{
		text = _text;
		buttons ~= new button;
		buttons ~= new button;
		}
	}
	
class okDialog : dialogBox
	{
	this(string _text)
		{
		text = _text;
		buttons ~= new button;
		}
	}

class guiType
	{
	}
