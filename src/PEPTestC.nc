configuration PEPTestC{
}
implementation{
	components PEPTestP;
	components PEC;
    components MainC;    
    components ActiveMessageC;
    components new TimerMilliC() as Timer;
    components new TimerMilliC() as TimerTX;
    components new DemoSensorC() as TempSensor;
    components new DemoSensorC() as PhotoSensor;
	
	PEPTestP.Boot -> MainC.Boot;
    PEPTestP.Radio -> ActiveMessageC;
    PEPTestP.Timer -> Timer;
    PEPTestP.TimerTX -> TimerTX;
    
    PEPTestP.TempSensor -> TempSensor.Read;
    PEPTestP.PhotoSensor -> PhotoSensor.Read;
	
	PEPTestP.MessageDissemination -> PEC.MessageDissemination;
	PEPTestP.PELifeCycle -> PEC.LifeCycle;
	//PEPTestP.PhotoSensor -> Stub
	//PEPTestP.TempSensor -> Stub 
}