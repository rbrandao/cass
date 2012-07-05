#include "cass.h"

module PEPTestP{
	uses {
		interface MessageDissemination;
		interface LifeCycle as PELifeCycle;
	
		interface Boot;
		interface SplitControl as Radio;
		interface Timer<TMilli> as Timer;
		interface Timer<TMilli> as TimerTX;
		interface Read<uint16_t>  as PhotoSensor;
		interface Read<uint16_t>  as TempSensor;
	}
}
implementation{
	bool sendBusy = TRUE;
	message_t sendBuff;
	
	cassMsg_t dataG;
	void replyRequest(uint16_t sensorValue);

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
		dbg("Test","Recebi um Probe do Nó:%u.\n",dataG.srcID);
	
		switch(dataG.value){ //value = SENSOR_TYPE
			case(PHOTO_MSG_ID):
			call PhotoSensor.read();
			break;
	
			case(TEMP_MSG_ID):
			call TempSensor.read();
			break;
	
			default:
			dbg("Test","Sensor cujo id=%u é desconhecido.\n",dataG.value);
			break;	
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

	event void PhotoSensor.readDone(error_t result, uint16_t val){
		replyRequest(val);
	}

	event void TempSensor.readDone(error_t result, uint16_t val){
		replyRequest(val);
	}
	
	// Envia uma mensagem de Echo para o nó.
	void replyRequest(uint16_t sensorValue){
		cassMsg_t message;
		error_t returnValue;
	
		message.srcID = TOS_NODE_ID;
		message.destID = 0;
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
}