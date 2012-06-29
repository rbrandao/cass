configuration HopRadioTestC{
}
implementation{
	components HopRadioTestP;
    components MainC;
    components HopRadioC;
    components ActiveMessageC;
    components new TimerMilliC() as Timer;
    
    HopRadioTestP.Boot -> MainC.Boot;
    
    HopRadioTestP.RadioSend -> HopRadioC.AMSend;
    HopRadioTestP.RadioReceive -> HopRadioC.Receive;
    HopRadioTestP.RadioLifeCycle -> HopRadioC.LifeCycle;
    
    HopRadioTestP.Radio -> ActiveMessageC;
    HopRadioTestP.Timer -> Timer;
}