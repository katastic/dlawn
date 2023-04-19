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

void drawTitledWindow(pair pos, idimen size)
	{
	
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
		if(selectedGraph < 0)selectedGraph = graphs.length - 1;
		if(graphs.length == 0)selectedGraph = 0;
		updateTitleText();
		}
		
	void actionNext()
		{
		selectedGraph++;
		if(selectedGraph > graphs.length-1)selectedGraph = 0;
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
