configuration HopRadioC{
	provides interface AMSend;
	provides interface Receive;
	provides interface LifeCycle;
}
implementation{
	components HopRadioP;
	components GroupRadioC;
	
	HopRadioP.RadioSend -> GroupRadioC.AMSend;
	HopRadioP.RadioReceive -> GroupRadioC.Receive;
	HopRadioP.RadioLifeCycle -> GroupRadioC.LifeCycle;
	
	HopRadioP.AMSend = AMSend;
	HopRadioP.Receive = Receive;
	HopRadioP.LifeCycle = LifeCycle;
}