var PPDevice = new ParallelPortDevice(); //Construct a Parallel Port Object

//Create a custom dialog with only one exit button to exit the script when needed
function Dialog(parent)
{
	QDialog.call(this, parent);
	var frameStyle = QFrame.Sunken | QFrame.Panel;
	var layout = new QGridLayout;
	layout.setColumnStretch(1, 1);	
	layout.setColumnMinimumWidth(1, 300);
	/////////////////////////////////////////////////////
	this.exitButton = new QPushButton("Exit");	
	layout.addWidget(this.exitButton, 99, 0);
	/////////////////////////////////////////////////////
	this.setLayout(layout);
	this.windowTitle = "Menu Dialog";
}

Dialog.prototype = new QDialog();

Dialog.prototype.keyPressEvent = function(e /*QKeyEvent e*/)
{
	if(e.key() == Qt.Key_Escape)
		this.close();
	else
		QDialog.keyPressEvent(e);
}

Dialog.prototype.closeEvent = function() 
{
	Log("Dialog closeEvent() detected!");
	CleanupScript();
}

function CleanupScript()
{
	//Close dialog
	mainDialog.close();
	//Stop running ParallelPort threads
	PPDevice.StopGenerateThread();
	PPDevice.StopCaptureThread();	
	//Disconnect the signal/slots
	ConnectDisconnectScriptFunctions(false);
	//Set all objects to null
	PPDevice = null;
	//Set all functions to null
	ConnectDisconnectScriptFunctions = null;	
	PPGenerateThreadStarted = null;	
	PPGenerateThreadTriggered = null;	
	PPGenerateThreadStopped = null;	
	PPCaptureThreadStarted = null;	
	PPCaptureThreadTriggered = null;	
	PPCaptureThreadStopped = null;	
	PauseMills = null;
	CleanupScript = null;
	//Dialog
	Dialog.prototype.keyPressEvent = null;
	Dialog.prototype.closeEvent = null;	
	Dialog.prototype = null;
	Dialog = null;	
	//Post
	Log("Finished script cleanup, ready for garbage collection!");
	BrainStim.cleanupScript();
}

function PPGenerateThreadStarted()
{
	Log("PPGenerateThreadStarted() called");
	for (var i = 0; i < arguments.length; ++i)
		Log("\t arg[" + i + "]: " + arguments[i]); 
}

function PPGenerateThreadTriggered()
{
	Log("PPGenerateThreadTriggered() called");
		for (var i = 0; i < arguments.length; ++i)
		Log("\t arg[" + i + "]: " + arguments[i]); 
}

function PPGenerateThreadStopped()
{
	Log("PPGenerateThreadStopped() called");
		for (var i = 0; i < arguments.length; ++i)
		Log("\t arg[" + i + "]: " + arguments[i]); 
}

function PPCaptureThreadStarted()
{
	Log("PPCaptureThreadStarted() called");
		for (var i = 0; i < arguments.length; ++i)
		Log("\t arg[" + i + "]: " + arguments[i]); 
}

function PPCaptureThreadTriggered()
{
	Log("PPCaptureThreadTriggered() called");
		for (var i = 0; i < arguments.length; ++i)
		Log("\t arg[" + i + "]: " + arguments[i]); 
}

function PPCaptureThreadStopped()
{
	Log("PPCaptureThreadStopped() called");
		for (var i = 0; i < arguments.length; ++i)
		Log("\t arg[" + i + "]: " + arguments[i]); 
}

function ConnectDisconnectScriptFunctions(Connect)
//This function can connect or disconnect all signal/slot connections defined by the boolean parameter 
{
	if(Connect) //This parameter defines whether we should connect or disconnect the signal/slots.
	{
		Log("... Connecting Signal/Slots");
		try 
		{	
			mainDialog.exitButton["clicked()"].connect(this, this.CleanupScript);
			PPDevice.GenerateThreadStarted.connect(this, this.PPGenerateThreadStarted);
			PPDevice.GenerateThreadTriggered.connect(this, this.PPGenerateThreadTriggered);
			PPDevice.GenerateThreadStopped.connect(this, this.PPGenerateThreadStopped);
			PPDevice.CaptureThreadStarted.connect(this, this.PPCaptureThreadStarted);
			PPDevice.CaptureThreadTriggered.connect(this, this.PPCaptureThreadTriggered);
			PPDevice.CaptureThreadStopped.connect(this, this.PPCaptureThreadStopped);
		} 
		catch (e) 
		{
			Log(".*. Something went wrong connecting the Signal/Slots:" + e); //If a connection fails warn the user!
		}		
	}
	else
	{
		Log("... Disconnecting Signal/Slots");
		try 
		{	
			mainDialog.exitButton["clicked()"].disconnect(this, this.CleanupScript);
			PPDevice.GenerateThreadStarted.disconnect(this, this.PPGenerateThreadStarted);
			PPDevice.GenerateThreadTriggered.disconnect(this, this.PPGenerateThreadTriggered);
			PPDevice.GenerateThreadStopped.disconnect(this, this.PPGenerateThreadStopped);
			PPDevice.CaptureThreadStarted.disconnect(this, this.PPCaptureThreadStarted);
			PPDevice.CaptureThreadTriggered.disconnect(this, this.PPCaptureThreadTriggered);
			PPDevice.CaptureThreadStopped.disconnect(this, this.PPCaptureThreadStopped);
		} 
		catch (e) 
		{
			Log(".*. Something went wrong disconnecting the Signal/Slots:" + e); //If a disconnection fails warn the user!
		}		
	}	
}

function PauseMills(millis)
{
	var date = new Date();
	var curDate = null;
     
	do { curDate = new Date(); }
	while(curDate-date < millis)
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Create and show the dialog
var mainDialog = new Dialog();
mainDialog.show();
ConnectDisconnectScriptFunctions(true);

//Configure the Parallel Port
Log("The default BaseAdress is: " + PPDevice.BaseAddress); //Read the default Parallel Port BaseAddress
PPDevice.BaseAddress = 4368; //4368 (decimal) == 1110 (hexadecimal) 
Log("The changed BaseAdress is: " + PPDevice.BaseAddress); //Read the changed Parallel Port BaseAddress again
Log("The current Port Description" + PPDevice.GetPortDescription());
//Read/Write some Port Values at the new BaseAddress
for (i=0;i<5;i++) //Create a simple for-loop
{
	PPDevice.PortWrite(64); //64 => only bit6 (0..7) is active
	Log(PPDevice.PortRead());
	Pause(25); //Wait some time, this blocks the script
	PPDevice.PortWrite(33); //33(=1+32) => bit0 and bit5 (0..7) are active 
	Log(PPDevice.PortRead());
	Pause(25);
}

//Start a capture thread
PPDevice.ConfigurePortForInput();
PPDevice.StartCaptureThread(4370, 1, 2, 0, 100);//(const short baseAddress, const short mask, const short method, const int postLHDelay = 0, const int postHLDelay = 0);

//Start a generate thread
//PPDevice.StartGenerateThread(4370, 2, 1, 1, 0, 500, 1000);//(const short baseAddress,const short method, const short outputMask, const short activeValue, const short inActiveValue, const int activePulseTime, const int repetitionTime);