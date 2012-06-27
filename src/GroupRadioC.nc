#include "cass.h"

configuration GroupRadioC{
	provides interface AMSend;
	provides interface Receive;
	provides interface LifeCycle;
}
implementation{
	components GroupRadioP;
	components new AMSenderC(CASS_ID) as RadioSend;
    components new AMReceiverC(CASS_ID) as RadioReceive;  
	
	GroupRadioP.RadioSend -> RadioSend.AMSend;
	GroupRadioP.RadioReceive -> RadioReceive.Receive;
	
	GroupRadioP.AMSend = AMSend;
	GroupRadioP.Receive = Receive;
	GroupRadioP.LifeCycle = LifeCycle;
}