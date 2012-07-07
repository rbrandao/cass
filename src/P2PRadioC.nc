#include "cass.h"
#include <Ctp.h>

configuration P2PRadioC{
	provides interface P2PRadio;
	provides interface LifeCycle;
}
implementation{
	components P2PRadioP;
	components ReliableRadioC as Radio;
    components CollectionC as Collector;
    components new CollectionSenderC(P2P_ID);
    components new AMSenderC(P2P_ID) as RadioSend;
    
    
	P2PRadioP.P2PRadio = P2PRadio;
	P2PRadioP.LifeCycle = LifeCycle;
	P2PRadioP.RadioSend -> Radio.AMSend;
	P2PRadioP.RadioReceive -> Radio.Receive;
	P2PRadioP.RadioLifeCycle -> Radio.LifeCycle;
	P2PRadioP.SendCTP -> CollectionSenderC;
	P2PRadioP.RootControl -> Collector.RootControl;
	P2PRadioP.ReceiveCTP -> Collector.Receive[P2P_ID];
	P2PRadioP.InterceptCTP -> Collector.Intercept[P2P_ID];
	P2PRadioP.RoutingControl -> Collector.StdControl;
	P2PRadioP.CtpPacket -> Collector.CtpPacket;
	
	P2PRadioP.AMPacket -> RadioSend;
	P2PRadioP.DummyRadio -> RadioSend.AMSend;	
}
