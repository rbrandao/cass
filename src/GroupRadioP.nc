#include <string.h>
#include "cass.h"

module GroupRadioP{
	provides interface AMSend;
	provides interface Receive;
	provides interface LifeCycle;
	
	uses interface AMSend as RadioSend;
	uses interface Receive as RadioReceive;
	uses interface Packet as RadioPacket;
}
implementation{
	uint16_t groupID = 0;
	
	command void LifeCycle.init(){
		error_t error = SUCCESS;
		dbg("lifeCycle", "GroupRadio: Initiated.\n");
		
		signal LifeCycle.initDone(error);
	}
	
	command void LifeCycle.addOption(uint8_t * option, uint16_t value){
		if(strcmp((char*)option, "groupID") == 0){
			dbg("lifeCycle", "GroupRadio: Set GroupID:%u.\n",value);
			groupID = value;
		}
	}
	
	command void * AMSend.getPayload(message_t *msg, uint8_t len){
		return call RadioSend.getPayload(msg, len);
	}

	command uint8_t AMSend.maxPayloadLength(){
		return call RadioSend.maxPayloadLength();
	}

	command error_t AMSend.send(am_addr_t addr, message_t *msg, uint8_t len){
		return call RadioSend.send(addr, msg, len);
	}

	command error_t AMSend.cancel(message_t *msg){
		return call RadioSend.cancel(msg);
	}

	event void RadioSend.sendDone(message_t *msg, error_t error){
		signal AMSend.sendDone(msg, error);
	}

	event message_t * RadioReceive.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t message;
		
		memcpy(&message, payload, sizeof(cassMsg_t));
		if(groupID == message.groupID){
			dbg("groupRadio","Repassando mensagem do grupo %u.\n",groupID);	
			return signal Receive.receive(msg, payload, len);
		}
		
		return msg;
	}
	
	command void LifeCycle.stop(){
		dbg("lifeCycle", "GroupRadio: Stopped.\n");
	}

}