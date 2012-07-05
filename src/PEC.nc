configuration PEC{
	provides{
		interface MessageDissemination;
		interface LifeCycle;
		}	
}
implementation{
	components PEP;
	components HopRadioC;
	components new TimerMilliC() as ProbeTimeoutTimer;
	
	PEP.RadioSend -> HopRadioC.AMSend;
	PEP.RadioReceive -> HopRadioC.Receive;
	PEP.RadioLifeCycle -> HopRadioC.LifeCycle;
	PEP.ProbeTimeoutTimer -> ProbeTimeoutTimer;
	
	PEP.MessageDissemination = MessageDissemination;
	PEP.LifeCycle = LifeCycle;
}