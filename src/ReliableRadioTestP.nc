#include "cass.h"


module ReliableRadioTestP{
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
uint8_t msgID;


	event void Boot.booted(){
		dbg("Test","Boot.booted()\n");
		
		call RadioLifeCycle.setProperty((uint8_t*)"tries", 3);
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
    	msgID = 1;
    	
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
		message.srcID = TOS_NODE_ID;
		message.destID = AM_BROADCAST_ADDR;
		message.groupID = 0;
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
		dbg("Test"," RadioReceive.receive(): Mensagem:%u recebida com sucesso.\n", message.messageID);
		
		return msg;
	}

	event void Radio.stopDone(error_t error){
		dbg("Test"," Radio.stopDone()\n");
	}
}