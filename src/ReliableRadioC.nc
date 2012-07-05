#include "cass.h"

configuration ReliableRadioC{
	provides interface AMSend;
	provides interface Receive;
	provides interface LifeCycle;
}
implementation{
	components ReliableRadioP, ActiveMessageC;
	components new AMSenderC(CASS_ID) as RadioSend;
    components new AMReceiverC(CASS_ID) as RadioReceive; 
    components new TimerMilliC() as DelayTimer; 
	
	ReliableRadioP.RadioSend -> RadioSend.AMSend;
	ReliableRadioP.RadioReceive -> RadioReceive.Receive;
	ReliableRadioP.RadioAcks -> RadioSend;
	ReliableRadioP.DelayTimer -> DelayTimer;
	
	ReliableRadioP.AMSend = AMSend;
	ReliableRadioP.Receive = Receive;
	ReliableRadioP.LifeCycle = LifeCycle;
	
}