configuration PEPTestC{
}
implementation{
	components PEPTestP;
	components PEC;
    components MainC;    
    components ActiveMessageC;
    components new TimerMilliC() as Timer;
    components new TimerMilliC() as TimerTX;
	
	PEPTestP.Boot -> MainC.Boot;
    PEPTestP.Radio -> ActiveMessageC;
    PEPTestP.Timer -> Timer;
    PEPTestP.TimerTX -> TimerTX;
	
	PEPTestP.MessageDissemination -> PEC.MessageDissemination;
	PEPTestP.PELifeCycle -> PEC.LifeCycle;
	//PEPTestP.PhotoSensor -> Stub
	//PEPTestP.TempSensor -> Stub 
}