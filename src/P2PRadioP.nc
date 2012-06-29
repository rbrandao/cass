module P2PRadioP{
	provides interface P2PRadio;
	provides interface LifeCycle;
	
	uses interface AMSend as RadioSend;
	uses interface Receive as RadioReceive;
	uses interface LifeCycle as RadioLifeCycle;
}
implementation{
	bool sendBusy = TRUE;	


	command void LifeCycle.stop(){
		// TODO Auto-generated method stub
	}

	command void LifeCycle.setProperty(uint8_t *option, uint16_t value){
		// TODO Auto-generated method stub
	}

	command void LifeCycle.init(){
		// TODO Auto-generated method stub
	}

	command error_t P2PRadio.send(am_addr_t addr, message_t *msg, uint8_t len){
		error_t error;
		
		return error;
	}

	command void P2PRadio.setRoot(){
		// TODO Auto-generated method stub
	}

	

	event message_t * RadioReceive.receive(message_t *msg, void *payload, uint8_t len){
		
		return msg;
	}

	event void RadioSend.sendDone(message_t *msg, error_t error){
		sendBusy = FALSE;
	}

	event void RadioLifeCycle.initDone(error_t error){	}

	event void RadioLifeCycle.stopDone(error_t error){	}
}