#include "cass.h"


module ProbeEchoTestP{
	uses interface Boot;
	uses interface LifeCycle;
	uses interface MessageDissemination;
	uses interface SplitControl as Radio;
	uses interface Timer<TMilli> as Timer;
}
implementation{

	uint16_t groupID;
	uint8_t msgID;


	event void Boot.booted(){
		dbg("test","Test Boot.booted()\n");
		groupID = 1;
		msgID = 1;
	
		call LifeCycle.setProperty((uint8_t*)"groupID", groupID);
		call Radio.start();
	}	
	
	event void LifeCycle.initDone(error_t error){
		dbg("test","Test RadioLifeCycle.initDone()\n");
	
	}
	
	event void Radio.startDone(error_t error){
		dbg("test","Test Radio.startDone()\n");
	
		if(error != SUCCESS){
			call Radio.start();	    	
			return;
		}
		call LifeCycle.init();

		//Node=1 inicia um probe com 5s de delay
		if(TOS_NODE_ID == 1){
			call Timer.startOneShot(5000);
		}
	}
 
	event void Timer.fired(){
		//cassMsg_t data;
		dbg("test","Test Timer.fired()\n");

		call MessageDissemination.sendMessage(); 
	}		

	event void LifeCycle.stopDone(error_t error){
		dbg("test","Test RadioLifeCycle.stopDone()\n");
	}

	event void Radio.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void MessageDissemination.messageDisseminationDone(cassMsg_t *data){
		dbg("test","\nTest MessageDissemination.messageDisseminationDone()\n");
		
		dbg("test","Test Valor recebido=%d motes=%d\n\n",data->readValue,data->motes);
		
		exit(0);
	}

	event void MessageDissemination.receiveResponse(cassMsg_t *data){
		// TODO Auto-generated method stub
	}
}