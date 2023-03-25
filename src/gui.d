import g, molto;

class element
	{
	pair pos;
	dimen size;
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
