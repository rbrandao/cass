#include "cass.h"

module PEPTestP{
	uses {
		interface MessageDissemination;
		interface LifeCycle as PELifeCycle;
		
		interface Boot;
		interface SplitControl as Radio;
		interface Timer<TMilli> as Timer;
		interface Timer<TMilli> as TimerTX;
		}
}
implementation{
	bool sendBusy = TRUE;
	message_t sendBuff;
	
	cassMsg_t dataG;

	event void Boot.booted(){
		dbg("Test","Boot.booted().\n");

		call Radio.start();
	}	

	event void Radio.startDone(error_t error){
        dbg("Test","Radio.startDone().\n");
	
        if(error != SUCCESS){
        	call Radio.start();	    	
	    	return;
        }
		call PELifeCycle.setProperty((uint8_t*)"groupID", 0); //Todo mundo no mesmo grupo.
		call PELifeCycle.setProperty((uint8_t*)"hops", 5);
        
        call PELifeCycle.init();
    	sendBusy = FALSE;
    	
    	
    	if(TOS_NODE_ID == 1){    		
			call Timer.startOneShot(500);
		}
    }
    
    
	event void Timer.fired(){
		call MessageDissemination.sendMessage(TEMP_MSG_ID);		
	}
	
	event void MessageDissemination.receiveRequest(cassMsg_t data){
		call TimerTX.startOneShot(55 * TOS_NODE_ID);
		memcpy(&dataG, &data, sizeof(cassMsg_t));
	}
	
	event void TimerTX.fired(){
		cassMsg_t message;
		nx_int16_t sensorValue;
		error_t returnValue;
		dbg("Test","Recebi um Probe do Nó:%u.\n",dataG.srcID);
		
		switch(dataG.value){ //value = SENSOR_TYPE
			case(PHOTO_MSG_ID):
				sensorValue = 367; //call PhotoStub
			break;
			case(TEMP_MSG_ID):
				sensorValue = 911; //call TempStub
			break;
			default:
				sensorValue = 0;
			break;	
		}
		
		message.srcID = TOS_NODE_ID;
		message.destID = AM_BROADCAST_ADDR; //message.destID = data.srcID;
		message.groupID = 0;
		message.hops = 0;
		message.messageID = 0;
		message.value = sensorValue;
		message.messageType = ECHO_MSG_ID;
		
		returnValue = call MessageDissemination.replyRequest(message);
		if (returnValue != SUCCESS){
    		dbg("Test","ProbeEcho.receiveProbe(): Erro '%u'  ao enviar mensagem para o nó %u!\n",returnValue, TOS_NODE_ID);    	
		}
	}

	event void MessageDissemination.receiveResponse(nx_uint16_t data){
		dbg("Test","--- Recebi a média: %u.\n",data);
		//Envia para o Cliente via P2P.
	}

	event void MessageDissemination.replyRequestDone(error_t error){	}
	event void PELifeCycle.stopDone(error_t error){	}
	event void PELifeCycle.initDone(error_t error){	}
	event void Radio.stopDone(error_t error){	}
}