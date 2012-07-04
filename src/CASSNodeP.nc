/**
 * Desenvolvido para a disciplina de Redes de Sensores Sem Fio (INF-2592)
 * ministrada na Pontifícia Universidade Católica pela Prof. Noemi Rodriguez
 *
 * @author Mauricio Rosas
 * @author Rafael Brandão
 * @date  Junho, 2012
 *
 * Implementação do componente que encapsula a eleição de líderes (algoritmo bully)
 * para o projeto final proposto
 */

#include "cass.h"

module CASSNodeP{
	uses interface LeaderElection;
	uses interface ProbeEcho as MessageDissemination;
	uses interface P2PRadio as Radio;
		
	uses interface SplitControl as RadioBoot;
	uses interface Boot;
	provides interface Boot as BSBoot;
		
	uses interface LifeCycle as RadioLifeCycle;
	uses interface LifeCycle as MessageDisseminationLifeCycle;
	uses interface LifeCycle as LeaderElectionLifeCycle;
	
	uses interface Packet;
	uses interface AMSend as Dummy;
	uses interface Receive as BSReceive;
	uses interface AMSend as BSSend;
}

implementation{
	
	message_t sendBuff;

	/*
	 * Interface Boot
	 */
	
	event void Boot.booted(){
		dbg("cassNode","CASNodeP Boot.booted()\n");
		
		//Cria um único grupo (para testes)
		call RadioLifeCycle.setProperty("groupID", 1);
		call MessageDisseminationLifeCycle.setProperty("groupID", 1);
		call LeaderElectionLifeCycle.setProperty("groupID", 1);
		
		//Define número de hops (para testes)
		call RadioLifeCycle.setProperty("hops", HOPS_MAX_NUMBER);
		call MessageDisseminationLifeCycle.setProperty("hops", HOPS_MAX_NUMBER);
		call LeaderElectionLifeCycle.setProperty("hops", HOPS_MAX_NUMBER);
		
		//Inicia componente Radio
		if(TOS_NODE_ID == 1){
			//caso seja o BaseStation
			signal BSBoot.booted();
		}
		else
			call RadioBoot.start();
		
	}

	/*
	 * Interface RadioBoot
	 */
	 
	event void RadioBoot.startDone(error_t error){
		dbg("cassNode","CASNodeP Radio.startDone()\n");

		if(error == SUCCESS){
			
			//Inicializa componentes atraves da interface LifeCycle
			call RadioLifeCycle.init();
			call MessageDisseminationLifeCycle.init();
			call LeaderElectionLifeCycle.init();
			
			if(TOS_NODE_ID == 1){
				//Define que o BaseStation é o root
				call Radio.setRoot();
			}
	
		}
		else{
			call RadioBoot.start();
		}
	}

	event void RadioBoot.stopDone(error_t error){
		dbg("cassNode","CASNodeP Radio.stopDone()\n");
	}
	
	event void MessageDisseminationLifeCycle.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void MessageDisseminationLifeCycle.initDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void LeaderElectionLifeCycle.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void LeaderElectionLifeCycle.initDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void MessageDissemination.echoDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void MessageDissemination.receiveProbe(cassMsg_t data){
		//TODO: TimerTX	
	
		cassMsg_t message;
		nx_int16_t sensorValue;
		error_t returnValue;
		
		dbg("cassNode","Recebi um Probe do Nó:%u.\n",data.srcID);
	
		switch(data.value){ //value = SENSOR_TYPE
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
	
		returnValue = call MessageDissemination.echo(message);
		if (returnValue != SUCCESS){
			dbg("cassNode","ProbeEcho.receiveProbe(): Erro '%u'  ao enviar mensagem para o nó %u!\n",returnValue, TOS_NODE_ID);    	
		}
	}

	event void MessageDissemination.probeDone(nx_uint16_t value){
		cassMsg_t data;
	
		dbg("cassNode","CASSNodeP MessageDissemination.probeDone()\n");
	
		data.srcID = TOS_NODE_ID;
		data.destID = AM_BROADCAST_ADDR;
		data.value = value;
		data.groupID = 0;
		data.hops = 0;
		//data.messageType = PHOTO
		
		
		memcpy(call Packet.getPayload(&sendBuff, call Packet.maxPayloadLength()), &data, sizeof(cassMsg_t));

		dbg("cassNode","CASSNodeP Enviando valor lido para BaseStation (valor=%u)\n", data.value);

		//Envia mensagem do BS para o líder do grupo
		call Radio.send(data.destID, &sendBuff, sizeof(cassMsg_t));
	}

	event void Radio.sendDone(message_t *msg, error_t error){
		// TODO Auto-generated method stub
	}

	event message_t * Radio.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t data;
		
		dbg("cassNode","CASSNodeP Radio.receive()\n");
		
		memcpy(&data,payload,sizeof(cassMsg_t));
		
		//Se for BaseStation
		if(TOS_NODE_ID == 1){
			if(data.messageType == ROUTING_MSG_ID){
				dbg("cassNode", "CASSNodeP Rota para o líder da sala (%u) definida!\n",data.value);
	
				//BSSend.send(): Informando ao java que a rota para a sala está definida
	
				//TODO Definir a sala no BaseStation
			}
			else {
				//TODO: Repassar mensagem para o cliente java
				//call BSSend.send(am_addr_t addr, message_t *msg, uint8_t len)
			}
		}
		else {
			dbg("cassNode","CASSNodeP Radio.receive() Enviando probe para o grupo (sensor=%d)\n",data.messageType);
			
			call MessageDissemination.probe(data.messageType);
		}
		
		return msg;
	}

	event message_t * BSReceive.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t data;
	
		dbg("cassNode","CASSNodeP BSReceive.receive()\n");
	
		memcpy(&data,payload,sizeof(cassMsg_t));
		
		memcpy(call Packet.getPayload(&sendBuff, call Packet.maxPayloadLength()), &msg, sizeof(cassMsg_t));

		dbg("cassNode","CASSNodeP Enviando mensagem para o líder (grupo=%u)\n", data.groupID); //TODO Verificar groupID

		//Envia mensagem do BS para o líder do grupo
		call Radio.send(data.destID, &sendBuff, sizeof(cassMsg_t));
	
		return msg;
	}

	event void LeaderElection.announceVictoryDone(error_t error){
		if(call LeaderElection.retrieveLeader() == TOS_NODE_ID){
			cassMsg_t msg;
			msg.destID = AM_BROADCAST_ADDR;
			msg.srcID = TOS_NODE_ID;
			msg.value = TOS_NODE_ID;
			msg.messageType = ROUTING_MSG_ID;
			msg.groupID = 0;
			msg.hops = 0;
			
			memcpy(call Packet.getPayload(&sendBuff, call Packet.maxPayloadLength()), &msg, sizeof(cassMsg_t));

			call Radio.send(msg.destID, &sendBuff, sizeof(cassMsg_t));
		}
	}

	event void LeaderElection.startElectionDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void LeaderElection.receiveResponse(cassMsg_t *data){
		// TODO Auto-generated method stub
	}

	event void RadioLifeCycle.initDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void RadioLifeCycle.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void Dummy.sendDone(message_t *msg, error_t error){
		// TODO Auto-generated method stub
	}


	event void BSSend.sendDone(message_t *msg, error_t error){
		// TODO Auto-generated method stub
	}
}

