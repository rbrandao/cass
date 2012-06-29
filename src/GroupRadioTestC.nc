configuration GroupRadioTestC{
}
implementation{
	components GroupRadioTestP;
    components MainC;
    components GroupRadioC;
    components ActiveMessageC;
    components new TimerMilliC() as Timer;
    
    GroupRadioTestP.Boot -> MainC.Boot;
    GroupRadioTestP.RadioSend -> GroupRadioC.AMSend;
    GroupRadioTestP.RadioReceive -> GroupRadioC.Receive;
    GroupRadioTestP.RadioLifeCycle -> GroupRadioC.LifeCycle;
    GroupRadioTestP.Radio -> ActiveMessageC;
    GroupRadioTestP.Timer -> Timer;
}