#include "cass.h"

module PEP{
		provides{
		interface ProbeEcho;
		interface LifeCycle;
		}
	uses{
		interface AMSend as RadioSend;
		interface Receive as RadioReceive;
		interface LifeCycle as RadioLifeCycle;
		interface Timer<TMilli> as ProbeTimeoutTimer;
		}
}
implementation{
	message_t sendBuff;
	bool sendBusy = TRUE;
	bool prober; // Sinaliza se o nó que enviou a mensagem.
	uint16_t agregatorValue;
	uint16_t echosNum;

	command void LifeCycle.init(){
		
		agregatorValue = 0;
		echosNum = 0;
		sendBusy = FALSE;
		prober = FALSE;
		call RadioLifeCycle.init();
	}

	command void LifeCycle.stop(){
		call RadioLifeCycle.stop();
	}

	command void LifeCycle.setProperty(uint8_t *option, uint16_t value){
		call RadioLifeCycle.setProperty(option, value); 
	}


	command error_t ProbeEcho.probe(nx_uint16_t sensorType){
		cassMsg_t message;
		prober = TRUE;
		
		sendBusy = TRUE;
		message.srcID = TOS_NODE_ID;
		message.destID = AM_BROADCAST_ADDR;
		message.groupID = 0;
		message.hops = 0;
		message.messageID = 0;
		message.value = sensorType;
		message.messageType = PROBE_MSG_ID;
		memcpy(call RadioSend.getPayload(&sendBuff,call RadioSend.maxPayloadLength()), &message, sizeof(cassMsg_t));
		
		dbg("probeEcho", "PEP::ProbeEcho.probe(): Enviando mensagem de Probe.\n");
		return call RadioSend.send(AM_BROADCAST_ADDR, &sendBuff, sizeof(cassMsg_t));
	}
	
	event message_t * RadioReceive.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t message;
				
		memcpy(&message, payload, sizeof(cassMsg_t));
		dbg("probeEcho", "PEP::RadioReceive.receive(): MsgID=%u.\n", message.messageID);
		if(message.messageType == PROBE_MSG_ID){
			signal ProbeEcho.receiveProbe(message);	
		}
		if(prober && message.messageType == ECHO_MSG_ID){
			
			//Quando chegar a primeira mensagem de Echo o Prober inicia um timer.
			//Esse timer espera um tempo determinado a chegada das outras mensagens e
			//depois sinaliza que o probe foi finalizado.
			if(!call ProbeTimeoutTimer.isRunning()){
				dbg("probeEcho", "PEP::RadioReceive.receive(): Iniciando Timer do Probe.\n");
				agregatorValue = 0;
				echosNum = 0;
				call ProbeTimeoutTimer.startOneShot(PROBE_TIMEOUT);
			}
			
			agregatorValue = agregatorValue + message.value;
			echosNum++;
		}
				
		return msg;
	}
	
	event void ProbeTimeoutTimer.fired(){
		prober = FALSE;
		sendBusy = FALSE;
		signal ProbeEcho.probeDone((agregatorValue/echosNum));		
	}
	
	
	event void RadioSend.sendDone(message_t *msg, error_t error){
		sendBusy = FALSE;
	}

	command error_t ProbeEcho.echo(cassMsg_t data){
		sendBusy = TRUE;
				
		if(data.messageType != ECHO_MSG_ID){
			dbg("probeEcho", "PEP::ProbeEcho.echo(): MessageType precisa ser igual a ECHO_MSG_ID.\n");
			data.messageType = ECHO_MSG_ID;
		}		
		dbg("probeEcho", "PEP::ProbeEcho.echo(): Enviando mensagem de Echo com returnValue=%u.\n",data.value);
		
		memcpy(call RadioSend.getPayload(&sendBuff,call RadioSend.maxPayloadLength()), &data, sizeof(cassMsg_t));
		return call RadioSend.send(AM_BROADCAST_ADDR, &sendBuff, sizeof(cassMsg_t));
	}

	event void RadioLifeCycle.initDone(error_t error){	}
	event void RadioLifeCycle.stopDone(error_t error){	}

	

	
}