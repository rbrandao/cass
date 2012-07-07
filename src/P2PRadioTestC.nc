configuration P2PRadioTestC{
}
implementation{
	components P2PRadioTestP;
    components dummyBSC;
    components MainC;
    components P2PRadioC;
    components ActiveMessageC;
    components new TimerMilliC() as Timer;
    components new AMSenderC(1);
    
    P2PRadioTestP.Boot -> MainC.Boot;
    P2PRadioTestP.P2PRadio -> P2PRadioC.P2PRadio;
    P2PRadioTestP.RadioLifeCycle -> P2PRadioC.LifeCycle;
    P2PRadioTestP.Radio -> ActiveMessageC;
    P2PRadioTestP.Timer -> Timer;
    P2PRadioTestP.Packet -> AMSenderC.Packet;
    P2PRadioTestP.Dummy -> AMSenderC.AMSend; //Necessário para a interface Packet funcionar.
}