#include "cass.h"
#include <Ctp.h>

configuration P2PRadioC{
	provides interface P2PRadio;
	provides interface LifeCycle;
}
implementation{
	components P2PRadioP;
	components new AMSenderC(P2P_ID) as RadioSend;
    components new AMReceiverC(P2P_ID) as RadioReceive;
    components CollectionC as Collector;
    components new CollectionSenderC(0xee);

	P2PRadioP.RadioSend = RadioSend;
	P2PRadioP.RadioReceive = RadioReceive;
	//P2PRadioP.Router = Coll	
	    
}