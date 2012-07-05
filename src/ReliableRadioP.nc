#include <string.h>
#include "cass.h"

module ReliableRadioP{
	provides interface AMSend;
	provides interface Receive;
	provides interface LifeCycle;
	
	uses interface AMSend as RadioSend;
	uses interface Receive as RadioReceive;
	uses interface PacketAcknowledgements as RadioAcks;
	uses interface Timer<TMilli> as DelayTimer;
}
implementation{
	int16_t triesNum;
	reliableCache_t cache[MAX_RELIABLE_BUFFER_LEN];
	int lastCashIndex;
	
	command void LifeCycle.init(){
		error_t error = SUCCESS;
		int i;
		dbg("lifeCycle", "ReliableR:LifeCycle.init(): Initiated.\n");
	
		lastCashIndex = 0; 
		for(i = 0; i < MAX_LEADER_BUFFER_LEN ; i++){
			cache[i].messageID = 0;
			cache[i].tries = 0;			
		}

		signal LifeCycle.initDone(error);
	}
	
	command void LifeCycle.setProperty(uint8_t * option, uint16_t value){
		if(strcmp((char*)option, "tries") == 0){
			dbg("lifeCycle", "ReliableR:LifeCycle.init(): Set Tries:%u.\n",value);
			triesNum = (int16_t)value;
		}
	}
	
	command void * AMSend.getPayload(message_t *msg, uint8_t len){
		return call RadioSend.getPayload(msg, len);
	}

	command uint8_t AMSend.maxPayloadLength(){
		return call RadioSend.maxPayloadLength();
	}

	command error_t AMSend.send(am_addr_t addr, message_t *msg, uint8_t len){
		cassMsg_t payload;
	
		memcpy(&payload,call RadioSend.getPayload(msg,call RadioSend.maxPayloadLength()),sizeof(cassMsg_t));
	
		if(addr == AM_BROADCAST_ADDR){
			dbg("reliableRadio", "RelRadio:AMSend.send(): Mensagem:%u via BROADCAST.\n", payload.messageID);
			return call RadioSend.send(addr, msg, len);
		}
	
		cache[lastCashIndex].messageID = payload.messageID;
		cache[lastCashIndex].tries = triesNum;	
		lastCashIndex = (lastCashIndex + 1) % MAX_RELIABLE_BUFFER_LEN;
		
		call RadioAcks.requestAck(msg);
		return call RadioSend.send(addr, msg, len);
	}

	command error_t AMSend.cancel(message_t *msg){
		return call RadioSend.cancel(msg);
	}
	
	event void DelayTimer.fired(){
		//TODO: Criado para enviar a mensagem novamente com algum um delay preestabelecido.
		//Teríamos que alterar a struct para guardar a mensagem ao invés do ID.
	}

	event void RadioSend.sendDone(message_t *msg, error_t error){
		cassMsg_t payload;
		int i;
	
		if(call RadioAcks.wasAcked(msg)){
			signal AMSend.sendDone(msg, error);
			return;
		}
	
		memcpy(&payload,call RadioSend.getPayload(msg,call RadioSend.maxPayloadLength()),sizeof(cassMsg_t));	
	
		for(i = 0; i < MAX_LEADER_BUFFER_LEN ; i++){
			if(cache[i].messageID == payload.messageID){
				break;
			}
		}
	
		if(i < MAX_LEADER_BUFFER_LEN){
			cache[i].tries = cache[i].tries - 1;
			if(cache[i].tries < 0){
				dbg("reliableRadio", "RelRadio:RadioSend.sendDone(): Erro ao enviar MsgID=%u|destID=%u|srcID=%u.\n",
						payload.messageID, payload.destID, payload.srcID);
				signal AMSend.sendDone(msg, 10);
				return;
			}
	
			dbg("reliableRadio", "RelRadio:RadioSend.sendDone(): Reenviando MsgID=%u|destID=%u|srcID=%u|Tries=%u.\n", 
					payload.messageID, payload.destID, payload.srcID, cache[i].tries);
			call RadioSend.send(payload.destID, msg, sizeof(cassMsg_t));
		}
		else{
			//dbg("reliableRadio", "RelRadio:RadioSend.sendDone(): Mesnagem '%u' não encontrada no cache.\n", payload.messageID);
			signal AMSend.sendDone(msg, error);			
		}
	}

	event message_t * RadioReceive.receive(message_t *msg, void *payload, uint8_t len){
			return signal Receive.receive(msg, payload, len);
	}
	
	command void LifeCycle.stop(){
		dbg("lifeCycle", "GroupRadio: Stopped.\n");
	}


	
}
