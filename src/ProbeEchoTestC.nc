configuration ProbeEchoTestC{
}

implementation{
	components dummyBSC;
    components ProbeEchoTestP;
    components MainC;
    components ProbeEchoC;
	components ActiveMessageC;
    components new TimerMilliC() as Timer;
    
    ProbeEchoTestP.Boot -> MainC.Boot;
    ProbeEchoTestP.Radio -> ActiveMessageC;

    ProbeEchoTestP.LifeCycle -> ProbeEchoC.LifeCycle;
    ProbeEchoTestP.MessageDissemination -> ProbeEchoC.MessageDissemination;
    ProbeEchoTestP.Timer -> Timer;
}
