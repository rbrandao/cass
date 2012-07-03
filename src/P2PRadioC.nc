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
    components new CollectionSenderC(P2P_ID);
    
    
	P2PRadioP.P2PRadio = P2PRadio;
	P2PRadioP.LifeCycle = LifeCycle;

	P2PRadioP.RadioSend -> RadioSend;
	P2PRadioP.RadioReceive -> RadioReceive;
	P2PRadioP.SendCTP -> CollectionSenderC;
	P2PRadioP.RootControl -> Collector;
	P2PRadioP.ReceiveCTP -> Collector.Receive[P2P_ID];
	P2PRadioP.InterceptCTP -> Collector.Intercept[P2P_ID];
	P2PRadioP.RoutingControl -> Collector;
	P2PRadioP.PacketCTP -> Collector.Packet;
}
