#include "cass.h"


module GroupRadioTestP{
		uses interface Boot;
		uses interface AMSend as RadioSend;
		uses interface Receive as RadioReceive;
		uses interface LifeCycle as RadioLifeCycle;
		uses interface SplitControl as Radio;
		uses interface Timer<TMilli> as Timer;
}
implementation{

bool sendBusy = TRUE;
message_t sendBuff;
uint16_t groupID;
uint8_t msgID;


	event void Boot.booted(){
		dbg("Test","Boot.booted()\n");
		groupID = TOS_NODE_ID % 2;
		msgID = 1;
		
		call RadioLifeCycle.setProperty((uint8_t*)"groupID", groupID);
		call Radio.start();
	}	
	
	event void RadioLifeCycle.initDone(error_t error){
		dbg("Test","RadioLifeCycle.initDone()\n");
		
	}
	
	event void Radio.startDone(error_t error){
        dbg("Test","Radio.startDone()\n");
	
        if(error != SUCCESS){
        	call Radio.start();	    	
	    	return;
        }
        call RadioLifeCycle.init();
    	sendBusy = FALSE;
    	
		call Timer.startOneShot(10 * TOS_NODE_ID);
    }
    
	event void Timer.fired(){
		cassMsg_t message;
		error_t returnValue = SUCCESS;
		
		dbg("Test","Timer.fired()\n");
		if(sendBusy){
			dbg("Test","Timer.fired(): Radio ocupado.\n");
		}
		
		sendBusy = TRUE;
		message.serverID = TOS_NODE_ID;
		message.clientID = AM_BROADCAST_ADDR;
		message.groupID = groupID;
		message.messageID = msgID++;
		message.value = TOS_NODE_ID + msgID;
		memcpy(call RadioSend.getPayload(&sendBuff,call RadioSend.maxPayloadLength()), &message, sizeof(cassMsg_t));
		
		returnValue = call RadioSend.send(AM_BROADCAST_ADDR, &sendBuff, sizeof(cassMsg_t));
		if (returnValue != SUCCESS){
    		dbg("Test","Timer.fired(): erro ao enviar mensagem para o id %u!\n",msgID);    	
		}
		
	}		

	event void RadioLifeCycle.stopDone(error_t error){
		dbg("Teste","RadioLifeCycle.stopDone()\n");
	}


	event void RadioSend.sendDone(message_t *msg, error_t error){
		dbg("Test","RadioSend.sendDone()\n");
	}

	event message_t * RadioReceive.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t message;

		
		memcpy(&message, payload, sizeof(cassMsg_t));
		dbg("Test"," RadioReceive.receive(): MyGID:%u MessageGID:%u MessageID:%u ServerID:%u \n",groupID, message.groupID, message.messageID,message.serverID);
		
		return msg;
	}

	event void Radio.stopDone(error_t error){
		dbg("Test"," Radio.stopDone()\n");
	}
}