#include "cass.h"


module LeaderElectionTestP{
		uses interface Boot;
		uses interface SplitControl as Radio;
		uses interface LifeCycle;
		uses interface LeaderElection;
}
implementation{

	nx_uint16_t msgID;
	
	event void Boot.booted(){
		dbg("Test","Test Boot.booted()\n");
		msgID = 1;
		
		call LifeCycle.setProperty((uint8_t*)"groupID", 1);
		call LifeCycle.setProperty((uint8_t*)"hops", 10);
		call Radio.start();
	}	
	

	event void Radio.startDone(error_t error){
		dbg("Test","Test Radio.startDone()\n");
		
		if(error == SUCCESS){
			call LifeCycle.init();
		}
		else{
			call Radio.start();
		}
	}

	event void Radio.stopDone(error_t error){
		dbg("Test","Test Radio.stopDone()\n");
	}

	event void LifeCycle.stopDone(error_t error){
		dbg("Test","Test LifeCycle.stopDone()\n");
	}

	event void LifeCycle.initDone(error_t error){
		dbg("Test","Test LifeCycle.initDone()\n");
	}

	event void LeaderElection.startElectionDone(error_t error){
		dbg("Test","Test LeaderElection.startElectionDone()\n");
	}

	event void LeaderElection.receiveResponse(cassMsg_t *data){
		dbg("Test","Test LeaderElection.receiveResponse()\n");
	}

	event void LeaderElection.announceVictoryDone(error_t error){
		dbg("Test","Test LeaderElection.announceVictoryDone()\n");
	}
}