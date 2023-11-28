/+
	
	system shock 2 weapon slot: if you have a 2x1 weapon (are there any?) it should take a full 3x1 slot but be centered.
		looks like during dev they made all weapons 3x1 but some were 2x1.

+/
/+

	BUG: mouse-over is drawn with datagrid so if multiple grids they overwrite each other. mouse-over needs a separate draw function in the drawstack.

+/

// BUG: mouse-over description should be for the window not indivudal grids?
// either way, it's not FORWARDING mouse leaving events so they're not always
// removing the mouse-over description and sometimes we have multiple mouse-overs at the same time.

// todo feature: if we care. support/implement item rotation.

// what about character slot positions for items/weapons/armor?
// system shock 2 simply extends the UI slots with certain grid slot being special
// and the UI graphics basically hide that.

/+
	deus ex has the grid + hotbar with numbers showing over the item that its assigned to.
	items STAY ON THE GRID
	
	diablo - items leave the grid and the drop locations are not NECESSARILY lined up with 
	the grid. the weapon and armor slots ARE lined up. But the amulet and two ring slots are offset by half a slot
	
	might and magic 6
		- huge grid per character. drag items ONTO CHARACTER portrart and they equip the person in a third person view (changing the sprite). However you can RETRIEVE items
		by picking specific areas of the portrait. Think like a pixelgrid HTML lookup for 
		what type to try and take from the character.
		
		there's also a secondary view with 6 rings, guantlet, and amulet. And wierdly enough
		the grid sizes are BIGGER for the same items. Not only visually, they're actually spaced
		out further. 
		
		neo-scavenger is much like this. drag onto a portrat
		
	space station 13
		- much different. different parts of body, and they can open up
		- some slots are specific, some are your hands for operating on things
		- does any other game really do this? Where you use your hands to open bags?
+/

// do we want a seperate pair type for screenPos vs canvasPos that type-check fails if
// you don't convert?

// ISSUE: What if we drop a 2x2 ON ITSELF but on a NEW position?
// Q:is there a simpler case we can brute force all these problems? 
// I have a grid. Place on grid. Test for valid grid. Is not valid? Revert.

// For now, [HALF FIXED] if we drop it on itself anywhere, revert. Still need to handle
// dropping on offset position.

// [+] -- BUG: you can drop items OUTSIDE the grid!

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

// how to handle drag and drop? 
// icons? can also system shock 2 style inventory grid
// - how do we handle PIXEL PERFECT (or bounding box) matching of an item vs mouse touching the background tile? (if wanted)
// - sort feature
// we need an UNDO feature if the placement is invalid or cancelled. 
class gridWindow
	{
	rect canvas;
	dragAndDropGrid[] grids;

	bool areWeCarryingAnItem = false;
	draggableItem itemWereCarrying = null;

	bool draw(viewport v) // WARN: We have no z-ordering here
		{
		foreach(gr; grids)
			{
			gr.draw(v);
			}
		return true;
		}

	bool checkMouseInside(pair screenPos)
		{
		if(screenPos.x - canvas.x < 0 ||
		   screenPos.y - canvas.y < 0 ||
		   screenPos.x - canvas.x > canvas.w ||
		   screenPos.y - canvas.y > canvas.h)return false;
		return true;
		}

	// should rename onClick()
	void onClick(pair pos) /// if any sub-elements, forward the event
		{
		foreach(gr; grids)
			{
			if(gr.checkMouseInside(pos))
				{
				gr.eventClickAt(pos);
				}
			}
		}

	void eventHandleMouse(pair pos) /// if any sub-elements, forward the event
		{
		foreach(gr; grids)
			{
			if(gr.checkMouseInside(pos))
				{
				gr.eventHandleMouseMovement(pos);
				}else{
				gr.eventMouseOutside(); // notify mouse is outside for cleanup functions
				}
			}
		}
		
	this(pair pos)
		{
		dragAndDropGrid dg = new dragAndDropGrid(this, pair(pos, 0, 0), ipair(10,4));
		grids ~= dg;
		dragAndDropGrid dg2 = new dragAndDropGrid(this, pair(pos, 0, 130), ipair(2,2));
		grids ~= dg2;
		dragAndDropGrid dg3 = new dragAndDropGrid(this, pair(pos, 330, 0), ipair(3,3));
		grids ~= dg3;
		
		dg.items ~= new draggableItem(ipair(0,0), ipair(1,3), dg, bh["wrench"], "Wrench", "a useful tool to do wrenching jobs");
		dg.items ~= new draggableItem(ipair(1,0), ipair(1,1), dg, bh["ammo"], "Ammo", "Silver-tipped .32 JHP specially crafted for werewolves.");
		dg.items ~= new draggableItem(ipair(2,0), ipair(1,1), dg, bh["hypo"], "Hypo", "A medical hypo full of a strange concontion");
		dg.items ~= new draggableItem(ipair(3,0), ipair(1,1), dg, bh["disk"], "Disk", "A data disk full of all your diary entries");

		dg3.items ~= new draggableItem(ipair(0,0), ipair(1,3), dg3, bh["laserpistol"], "Laser Pistol", "The Apollo H4 Argon-Suspension Laser Pistol is a weapon in System Shock 2, and is the most basic Energy Weapon. This weapon relies on refracted light to damage its target, while the energy bolt projectile shown in-game is fast and small.");
		dg3.items ~= new draggableItem(ipair(1,2), ipair(1,1), dg3, bh["implant1"], "Implant", "a useful implant");
		dg3.items ~= new draggableItem(ipair(2,2), ipair(1,1), dg3, bh["implant2"], "Implant2", "a useful implant2");
		dg3.items ~= new draggableItem(ipair(1,0), ipair(2,2), dg3, bh["armor"], "Armor", "Fiber-reinforced metal pieces wrapped in canvas.");
		}
	}

class dragAndDropGrid
	{
	gridWindow owner;
	rect canvas; /// x,y screen coords, then w/h .. w/h are DERIVED from gridDim
	draggableItem[] items;
	int gridSize = 32; /// in pixels
//	ipair gridDim;  // 
	int numHiddenColumns=3;
	bool isDrawingMouseOverlay = false;
	draggableItem mouseOverlayItem = null;
	pair mouseOverlayScreenPos;

	bool checkMouseInside(pair screenPos)
		{
		if(screenPos.x - canvas.x < 0 ||
		   screenPos.y - canvas.y < 0 ||
		   screenPos.x - canvas.x > canvas.w ||
		   screenPos.y - canvas.y > canvas.h)return false;
		return true;
		}
		
	int charWidth = 9;
	int charHeight = 17;

	void drawMouseOverItemName(pair pos, draggableItem i){
		float r=4;
		int textBoxWidth = 250;

		drawRoundedFilledRectangle(
			rect(pair(pos,-r,-r), pair(textBoxWidth+r*2, (cast(float)charHeight)+r*2)), 
			color(.7,.7,7,.60), //white ish
			r/2
			);
		
		drawFilledRectangle(rect(pos, pair(textBoxWidth, cast(float)charHeight)), black); 
		drawText(pos, white, i.name);
		}
		
	void drawMouseOverItemDescription(pair pos, draggableItem i){
		float r=4;
		int textBoxWidth = 250;
		string[] strings = splitStringArrayAtWidth3(i.description, textBoxWidth);
		
		drawRoundedFilledRectangle(
			rect(pair(pos,-r,-r), pair(textBoxWidth+r*2, (cast(float)charHeight*strings.length)+r*2)), 
			color(.7,.7,7,.60), //white ish
			r/2
			);
		
		drawFilledRectangle(rect(pos, pair(textBoxWidth, cast(float)charHeight*strings.length)), black); 
		drawTextArray(pos, white, strings);
		}

	void eventHandleMouseMovement(pair screenPos){ /// every mouse movement we tell dialog to check if we're inside. Otherwise we could have some sort of dialog handler ONLY send events when inside. 
		if(checkMouseInside(screenPos)){
			auto r = findItemsGivenClick(screenPos);
			if(r){
				isDrawingMouseOverlay = true;
				mouseOverlayItem = r;
				mouseOverlayScreenPos = screenPos;
				}else{
				isDrawingMouseOverlay = false;
				}
			}else{
			isDrawingMouseOverlay = false;
			}
		}
	
	this(gridWindow _owner,pair pos, ipair gridDim){
		owner = _owner;
//		gridDim = ipair(10, 4);
		canvas = rect(pair(pos), pair(gridDim.i*gridSize, gridDim.j*gridSize)); //getWidthHeightFromGridSize(gridDim));
		}

	ipair screenToGrid(pair screenPos)
		{
		return ipair((screenPos-pair(canvas.x,canvas.y))/gridSize);
		}

	bool attemptPlaceAt(pair screenPos)
		{
		writeln("attemptPlaceAt ", screenPos);
		if(canWePlaceAt(screenPos))
			{
			import std.algorithm.mutation : remove;
			owner.itemWereCarrying.owner.items = owner.itemWereCarrying.owner.items.remove!(a => a == owner.itemWereCarrying); // remove us from old list
			// FYI this is O(n) removal. It detects multiple and will not terminate early on first match.
			
			owner.itemWereCarrying.owner = this; // reset tracking variable
			owner.itemWereCarrying.owner.items ~= owner.itemWereCarrying; // add us to new list

			owner.itemWereCarrying.gridPosition = screenToGrid(screenPos);
			owner.itemWereCarrying.isPickedUp = false;
			owner.areWeCarryingAnItem = false;
			return true;
			}
		return false;
		}

	bool attemptSwapAt(pair screenPos, draggableItem result)
		{
		writeln("attemptSwapAt ", screenPos);
		if(canWePlaceAt(screenPos))
			{
			owner.itemWereCarrying.gridPosition = screenToGrid(screenPos);
			owner.itemWereCarrying.isPickedUp = false;
			
			owner.itemWereCarrying = result;
			owner.itemWereCarrying.isPickedUp = true;
			return true;
			}
		return false;
		}

	bool canWePlaceAt(pair screenPos)
		{
		if(screenPos.x - canvas.x < 0 ||
		   screenPos.y - canvas.y < 0 ||
		   screenPos.x - canvas.x > canvas.w ||
		   screenPos.y - canvas.y > canvas.h)return false;
		return true;
		}

	void eventMouseOutside()
		{
		isDrawingMouseOverlay = false;
		}

	bool eventClickAt(pair screenPos)
		{
		writeln("eventClickAt(", screenPos, ")");

		if(!owner.areWeCarryingAnItem)
			{
			writeln("2 PICKUP");
			// check if we're touching a new item to pickup
			auto result = findItemsGivenClick(screenPos);
			if(result !is null)
				{
	//			result.eventActivate();
				result.actionPickUp();
				owner.itemWereCarrying = result;
				owner.areWeCarryingAnItem = true;
				return true;
				}
			}else{ // if we ARE carrying an item:  check if there's a spot clear at the point
				// THE ISSUE. what if we're taking up more than one spot?
				// we gotta search all spots.
				// AND, if we only have ONE replacement, we replace it.
				// HOWEVER, if more than ONE we just reject the placement.
			auto result = findItemsGivenClick(screenPos);
			writeln("3 CARRYING");
			if(result is null)// if no item is there, we can place it
				{
				writeln("4 EMPTY DROP");
	//			result.eventActivate();
				attemptPlaceAt(screenPos);
				return true;
				}else {					
				writeln("5 ATTEMPT SWAP");
				if(result == owner.itemWereCarrying)
					{
					owner.itemWereCarrying.isPickedUp = false;
					owner.areWeCarryingAnItem = false;
					// NOTE: This fails if we're trying to MOVE a 2x2 one space over (by clicking inside itself but not the 0x0 position)
					}else{
					int val=0;
					for(int i=0; i<=owner.itemWereCarrying.bulkSize.i;i++)
						for(int j=0; j<=owner.itemWereCarrying.bulkSize.j;j++)
							{
							writeln("i,j", i, ",", j);
							auto t = findItemsGivenClick(pair(screenPos, i*gridSize, j*gridSize)); // logic bug: this should only ever equal one or zero unless we have overlaps
							if(t !is null && t !is owner.itemWereCarrying) //if we find an item in a bulkslot that isn't us, increment val
								val++;
								
							// does this FAIL if we drop an item on itself?
							}
					if(val == 1)
						{
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
	
	draggableItem findItemsGivenClick(pair hitCanvasPos)
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
		
	void drawBackground()
		{
		with(canvas)
			al_draw_filled_rectangle(x, y, x + w, y + h, color(.2,.2,.2,.5));
		}
		
	void drawGrid()
		{
		int w = cast(int)canvas.w/gridSize - numHiddenColumns;
		int h = cast(int)canvas.h/gridSize;
		for(int i = 0; i < w+1; i++)
			{
			al_draw_line(
						canvas.x + gridSize*(i), 
						canvas.y, 
						canvas.x + gridSize*(i), 
						canvas.y + canvas.h, white, 1.0f);
			}
		for(int i = w; i < w+1+numHiddenColumns; i++)
			{
			al_draw_line(
						canvas.x + gridSize*(i), 
						canvas.y, 
						canvas.x + gridSize*(i), 
						canvas.y + canvas.h, green, 1.0f);
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
	
		if(isDrawingMouseOverlay)
			{
			drawMouseOverItemName(pair(mouseOverlayScreenPos, 48, 0), mouseOverlayItem);
			drawMouseOverItemDescription(pair(mouseOverlayScreenPos, 48, 25), mouseOverlayItem);
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

	this(ipair _gridPosition, ipair _bulkSize, dragAndDropGrid _owner, bitmap* _b, string _name, string _description)
		{
		owner = _owner;
		gridPosition = _gridPosition;
		bulkSize = _bulkSize;
		image = _b;
		name = _name;
		description = _description;
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
	irect dim; // i hate this name conflict with dimen/idimen
	//pair pos;
	//idimen size;
	bool isInside(pair pos)
		{
		return true;
		}

	void eventOnClick(pair pos)
		{
		}
	}
	
class windowElement : element
	{
	string title;
	element[] elements;
	
	override void eventOnClick(pair pos)
		{
		foreach(e; elements)
			{
			if(e.isInside(pos))e.eventOnClick(pos);
			}
		}
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
