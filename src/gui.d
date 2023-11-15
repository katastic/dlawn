
// -- BUG: you can drop items OUTSIDE the grid!

// ISSUE: What if we drop a 2x2 ON ITSELF but on a NEW position?
// Q:is there a simpler case we can brute force all these problems? 
// I have a grid. Place on grid. Test for valid grid. Is not valid? Revert.

// For now, [HALF FIXED] if we drop it on itself anywhere, revert. Still need to handle
// dropping on offset position.

// minor BUG: if we do the "faded item to mark old position" when we replace it with a new item
// the fade is still there superimposed with the replaced position.
// - do we get rid of fade altogether, or, only use it when not replacing an item? Then is 
// it even useful to mark original position?


// BUG: I'm able to drop a 2x2 onto a 1x1 by leaving it on position 1x1 inside the 2x2?
// I think it's because we MOVED IT it's not registering correctly anymore.

// [+] BUG TO FIX: [1,1] disk dropped on top of a [1,3] wrench. The disk fits, it swaps
// but now the wrench is being placed in the disk's spot. Which ONLY has room for [1,1].
// The wrench is now superimposed on the two lower item spots.
// Solution: [[TEST]] the swap end location before commiting to the reversal.
// [+] BUG. if we auto replace, instead of just pickup the old item (which we should probably do)
// we can end up replacing the item INSIDE the NEW item. 2x2 next to a 1x1. Move 2x2 onto 1x1.
// 1x1 is now INSIDE 2x2 at position 0x1. 
// <-- fixed by picking up next item and testing all locations

// ADD
// - basic sort functionality
// - sort by type

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
	draggableItem[] items;
	int gridSize = 32;
	ipair gridDim;
	
	this()
		{
		gridDim = ipair(10, 4);
		canvas = rect(pair(600.0, 200.0), getWidthHeightFromGridSize(gridDim));
		
		items ~= new draggableItem(ipair(0,0), ipair(1,3), this, bh["wrench"], "wrench");
		items ~= new draggableItem(ipair(1,0), ipair(1,1), this, bh["ammo"], "ammo");
		items ~= new draggableItem(ipair(2,0), ipair(1,1), this, bh["hypo"], "hypo");
		items ~= new draggableItem(ipair(3,0), ipair(1,1), this, bh["disk"], "disk");
		items ~= new draggableItem(ipair(4,0), ipair(2,2), this, bh["armor"], "armor");
		}
	
	bool areWeCarryingAnItem = false;
	draggableItem itemWereCarrying = null;

	ipair screenToGrid(pair screenPos)
		{
		return ipair((screenPos-pair(canvas.x,canvas.y))/gridSize);
		}

	bool attemptPlaceAt(pair screenPos)
		{
		writeln("attemptPlaceAt ", screenPos);
		if(canWePlaceAt(screenPos))
			{
//			writeln("1 ", screenPos, "    ", pair(canvas.x,canvas.y) );
//			writeln("2 ", (screenPos-pair(canvas.x,canvas.y)));
//			writeln("3 ", (screenPos-pair(canvas.x,canvas.y))/gridSize);
//			writeln("4 ", ipair((screenPos-pair(canvas.x,canvas.y))/gridSize));
			itemWereCarrying.gridPosition = screenToGrid(screenPos);
//			writeln("the new gridposition is:", itemWereCarrying.gridPosition);
			itemWereCarrying.isPickedUp = false;
			areWeCarryingAnItem = false;
			return true;
			}
		return false;
		}

	bool attemptSwapAt(pair screenPos, draggableItem result)
		{
		writeln("attemptSwapAt ", screenPos);
		if(canWePlaceAt(screenPos))
			{
			itemWereCarrying.gridPosition = screenToGrid(screenPos);
			itemWereCarrying.isPickedUp = false;
			
			itemWereCarrying = result;
			itemWereCarrying.isPickedUp = true;
			return true;
			}
		return false;
		}

	bool canWePlaceAt(pair screenPos)
		{
		if(screenPos.x - canvas.x < 0 ||
		   screenPos.y - canvas.y < 0 ||
		   screenPos.x - canvas.x > gridDim.i*gridSize ||
		   screenPos.y - canvas.y > gridDim.j*gridSize)return false;
		return true;
		}

	bool eventClickAt(pair screenPos)
		{
		writeln("eventClickAt(", screenPos, ")");

		if(!areWeCarryingAnItem)
			{
			writeln("2 PICKUP");
			// check if we're touching a new item to pickup
			auto result = checkForItemsGivenClick(screenPos);
			if(result !is null)
				{
	//			result.eventActivate();
				result.actionPickUp();
				itemWereCarrying = result;
				areWeCarryingAnItem = true;
				return true;
				}
			}else{ // if we ARE carrying an item:  check if there's a spot clear at the point
				// THE ISSUE. what if we're taking up more than one spot?
				// we gotta search all spots.
				// AND, if we only have ONE replacement, we replace it.
				// HOWEVER, if more than ONE we just reject the placement.
			auto result = checkForItemsGivenClick(screenPos);
			writeln("3 CARRYING");
			if(result is null)// if no item is there, we can place it
				{
				writeln("4 EMPTY DROP");
	//			result.eventActivate();
		/*
				if(itemWereCarrying.actionPlaceAtGrid(ipair(cast(int)(screenPos.x-canvas.x)/gridSize, cast(int)(screenPos.y-canvas.y)/gridSize))) // on true, we placed it (there's nothing in the way)
					{
					writeln("4");
					areWeCarryingAnItem = false;  // how could this possibly fail???
					}else{
					writeln("5");
					areWeCarryingAnItem = true;
					}*/
				attemptPlaceAt(screenPos);
				return true;
				}else {					
				writeln("5 ATTEMPT SWAP");
				if(result == itemWereCarrying)
					{
					itemWereCarrying.isPickedUp = false;
					areWeCarryingAnItem = false;
					// NOTE: This fails if we're trying to MOVE a 2x2 one space over (by clicking inside itself but not the 0x0 position)
					}else{
					int val=0;
					for(int i=0; i<=itemWereCarrying.bulkSize.i;i++)
						for(int j=0; j<=itemWereCarrying.bulkSize.j;j++)
							{
							writeln("i,j", i, ",", j);
							auto t = checkForItemsGivenClick(pair(screenPos, i*gridSize, j*gridSize)); // logic bug: this should only ever equal one or zero unless we have overlaps
							if(t !is null && t !is itemWereCarrying) //if we find an item in a bulkslot that isn't us, increment val
								val++;
								
							// does this FAIL if we drop an item on itself?
							}
					if(val == 1)
						{
						/+ SWAP ITEM CODE
						  - Fails if big item replaces small item (overlaps more items)
						result.isPickedUp = false;
						ipair tempPos = itemWereCarrying.gridPosition;
						itemWereCarrying.actionPlaceAtGrid(
							ipair(cast(int)(screenPos.x-canvas.x)/gridSize, 
								cast(int)(screenPos.y-canvas.y)/gridSize));
						result.gridPosition = tempPos;
						itemWereCarrying = null; 
						areWeCarryingAnItem = false;
						+/
						/+
						result.isPickedUp = true;
							
						ipair tempPos = itemWereCarrying.gridPosition;
						itemWereCarrying.actionPlaceAtGrid(
							ipair(cast(int)(screenPos.x-canvas.x)/gridSize, 
								cast(int)(screenPos.y-canvas.y)/gridSize));
						itemWereCarrying = result;
						result.gridPosition = tempPos;
						+/
				//		areWeCarryingAnItem = false;	
						attemptSwapAt(screenPos, result);
						}else{
						writeln("REJECTED NUMBER OF ITEMS (error if==0):", val);
						assert(val != 0, "REJECT ITEMS");
						}
					}
				}
			}
		return false;
		}
	
	draggableItem checkForItemsGivenClick(pair hitCanvasPos)
		{
		import helper : isWithin;

		foreach(it; items)
			{
			writeln("searching:", it.name);
			pair itemMousePosition = it.getMousePosition();
//			writeln("hitCanvasPos ", hitCanvasPos, " vs ", "itemMousePosition ", itemMousePosition);
			
			if(
				hitCanvasPos.isWithin(itemMousePosition, 
					pair(itemMousePosition, 
						gridSize*it.bulkSize.i, 
						gridSize*it.bulkSize.j))
				){
				con.log(it.name ~ " was found");
				return it;
				}
			}
		con.log("none found");
		return null;
		}

	pair getWidthHeightFromGridSize(ipair grid)
		{
		return pair(gridSize*grid.i,gridSize*grid.j);
		}
		
//	int[16][128] gridLookupTable;  // each occupied tile
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
		with(canvas)
			al_draw_filled_rectangle(x, y, x + w, y + h, color(.2,.2,.2,.5));
		}
		
	void drawGrid()
		{
		int w = cast(int)canvas.w/gridSize;
		int h = cast(int)canvas.h/gridSize;
		for(int i = 0; i < w+1; i++)
			{
			al_draw_line(
						canvas.x + gridSize*(i), 
						canvas.y, 
						canvas.x + gridSize*(i), 
						canvas.y + canvas.h, white, 1.0f);
			}
		for(int j = 0; j < h+1; j++)
			{
			al_draw_line(
						canvas.x             ,
						canvas.y + gridSize*(j), 
						canvas.x + canvas.w, 
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
	dragAndDropGrid owner; // for requesting deletion, and drawing gridsize, and canvas dim.

	ipair gridPosition; // where in inventory is it if it's placed. top-left
	ipair bulkSize; // width/height of item (no support for L-shaped/odd-shaped items. 1x1. 3x1, 2x2, etc)
	bool flipVertical; // if we have system shock 1/remake style rotatable items
	bool flipHorizontal;
	string name;
	string description;
	bitmap* image; // no animated/modifiable images
	void* myItemPtr; //for command callbacks

	bool hasBeenActivated = false;
	bool isPickedUp; // if true, mouse coordinates can float to follow mouse and when set 
					// back we update to table coordinates, on fail to set, we reset back to mouseX, mouseY
	
//		float tableMouseX, tableMouseY; //screen/mouse position of our top-left point in table FROM gridPosition
//		float floatingMouseX, floatingMouseY; // are these TABLE RELATIVE though or SCREEN RELATIVE? What if we're dragging between windows or out of window!
//		float mouseWidth, mouseHeight; /// pixel width/height of graphic. Could also just use image->w,h
	
	bool actionPickUp()
		{
		isPickedUp = true;
		return true;
		}

	bool actionPlaceAtGrid(ipair _gridPosition) // this should be in grid???
		{
		writeln("actionPlaceAtGrid: ", _gridPosition);
		isPickedUp = false;
		gridPosition = _gridPosition;
		return true;
		}
	
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
		writeln("getMousePosition = ", p, " grid:", gridPosition.i, ",", gridPosition.j);
		return p;
		}

	this(ipair _gridPosition, ipair _bulkSize, dragAndDropGrid _owner, bitmap* _b, string _name)
		{
		owner = _owner;
		gridPosition = _gridPosition;
		bulkSize = _bulkSize;
		image = _b;
		name = _name;
		}
		
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
		rect dim = owner.canvas;
		return (testPos.x < dim.x || testPos.x > dim.x+dim.w-1 ||
				testPos.y < dim.y || testPos.y > dim.y+dim.y-1)
			? true : false;
		}
		
	void dropItemIntoWorld(){}
	void removeMeFromList(){}

	void draw(rect canvas, viewport v)
		{
		if(!isPickedUp)
			{
			drawBitmap(image, 
				pair(v.x + canvas.x + gridPosition.i*owner.gridSize, 
					 v.y + canvas.y + gridPosition.j*owner.gridSize), hasBeenActivated);
			}
		else
			{
			// draw half transparent
/+			drawTintedBitmap(image, 
				color(1.0,1.0,1.0,0.25),
				pair(v.x + canvas.x + gridPosition.i*owner.gridSize, 
					 v.y + canvas.y + gridPosition.j*owner.gridSize), hasBeenActivated);
+/
			// draw following mouse
			drawBitmap(image, 
				pair(mouse_x, mouse_y), hasBeenActivated);
			}
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
