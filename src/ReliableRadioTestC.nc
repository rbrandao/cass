configuration ReliableRadioTestC{
}
implementation{
	components ReliableRadioTestP;
    components MainC;
    components ReliableRadioC;
    components ActiveMessageC;
    components new TimerMilliC() as Timer;
    
    ReliableRadioTestP.Boot -> MainC.Boot;
    ReliableRadioTestP.RadioSend -> ReliableRadioC.AMSend;
    ReliableRadioTestP.RadioReceive -> ReliableRadioC.Receive;
    ReliableRadioTestP.RadioLifeCycle -> ReliableRadioC.LifeCycle;
    ReliableRadioTestP.Radio -> ActiveMessageC;
    ReliableRadioTestP.Timer -> Timer;
}