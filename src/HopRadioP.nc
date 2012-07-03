#include <string.h>
#include "cass.h"


module HopRadioP{
	provides interface AMSend;
	provides interface Receive;
	provides interface LifeCycle;

	uses interface AMSend as RadioSend;
	uses interface Receive as RadioReceive;
	uses interface LifeCycle as RadioLifeCycle;
	uses interface Packet as RadioPacket;
}
implementation{
	uint8_t msgID; //TODO: Lembrar de falar no tutorial que o Hops é o respons[avel pelo  MessageID.
	uint16_t messageBufferID[MAX_MESSAGE_ID_BUFFER_LEN];
	uint8_t bufferID;
	
	uint16_t hopsNum = 0;
	message_t sendBuff; //Utilizado para mandar a mensagem para cima.
	
	bool isDuplicateMsg(nx_uint16_t messageID);
	
	command void LifeCycle.init(){
		error_t error = SUCCESS;
		int i;
		dbg("lifeCycle", "HopLimits: Initiated.\n");
		
		bufferID = 0;
		msgID = 1;
		for (i = 0; i < MAX_MESSAGE_ID_BUFFER_LEN;  i++){
			messageBufferID[i] = 0;
		}
		
		call RadioLifeCycle.init();
		signal LifeCycle.initDone(error);
	}
	
	command void LifeCycle.setProperty(uint8_t * option, uint16_t value){
		if(strcmp((char*)option,"hops") == 0){
			dbg("lifeCycle", "HopLimits: Set Hops:%u.\n", value);
			hopsNum = value;
		}
		
		//Deep configuration.
		call RadioLifeCycle.setProperty(option, value);
	}
	
	command void * AMSend.getPayload(message_t *msg, uint8_t len){
		return call RadioSend.getPayload(msg, len);
	}

	command uint8_t AMSend.maxPayloadLength(){
		return call RadioSend.maxPayloadLength();
	}

	command error_t AMSend.send(am_addr_t addr, message_t *msg, uint8_t len){
		cassMsg_t *payload;
		
		payload = (cassMsg_t*) call AMSend.getPayload(msg, len);
		
		if(payload->messageID != 0)
			dbg("hopRadio", "Lixo no valor de MessageID. Estou sobreescrevendo.\n");
		
		if(payload->hops != 0)
			dbg("hopRadio", "Lixo no valor de HOPS. Estou sobreescrevendo.\n");
			
		payload->messageID = (TOS_NODE_ID << 8) + msgID++;
		payload->hops = hopsNum;
		return call  RadioSend.send(addr, msg, len);
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
		
		//Não reenvia a própria mensagem.
        if(message.srcID == TOS_NODE_ID){
            return msg;
        }
		
		
		if(isDuplicateMsg(message.messageID)){
			return msg;
		}
		messageBufferID[bufferID++ % MAX_MESSAGE_ID_BUFFER_LEN] = message.messageID;
		
		
		dbg("hopRadio", "Hops: RecebiMsg. Hops=%u.\n", message.hops);
		signal Receive.receive(msg, payload, len);
		
		if(message.hops > 0){
			message.hops--;
			memcpy(call RadioSend.getPayload(&sendBuff,call RadioSend.maxPayloadLength()), &message, sizeof(cassMsg_t));
			
			dbg("hopRadio", "Hops: Enviando a mensagem. Hops=%u.\n", message.hops);
			call RadioSend.send(message.destID, &sendBuff, len);
		}
		
		return msg;
	}
	
	command void LifeCycle.stop(){
		dbg("lifeCycle", "HopLimits: Stopped.\n");
		call RadioLifeCycle.stop();
	}

	event void RadioLifeCycle.initDone(error_t error){	}

	event void RadioLifeCycle.stopDone(error_t error){	}
	
	
	//Responsavel por verificar se a mensagem já foi recebida anteriormente.	
	bool isDuplicateMsg(nx_uint16_t messageID){
		int i;
		
		for (i = 0; i < MAX_MESSAGE_ID_BUFFER_LEN;  i++){
			if(messageBufferID[i] == messageID){
				return TRUE;
			}
		}
		return FALSE;
	}
		
		
		
		
		
		
}