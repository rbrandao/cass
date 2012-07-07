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
	uses interface MessageDissemination as MessageDissemination;
	uses interface P2PRadio as P2PRadio;
	
	uses interface SplitControl as RadioBoot;
	uses interface Boot;
	//uses interface Boot as BSBoot;
	
	uses interface LifeCycle as RadioLifeCycle;
	uses interface LifeCycle as MessageDisseminationLifeCycle;
	uses interface LifeCycle as LeaderElectionLifeCycle;
	
	uses interface Packet;
	uses interface AMSend as Dummy;
	uses interface AMSend as BSSend;
	
	uses interface Timer<TMilli> as EchoTimer;
	uses interface Timer<TMilli> as SendProbeTimer;
}

implementation{
	
	message_t sendBuff;
	cassMsg_t echoData;
	int ROOT_NODE = 17;
	int groupID;
	/*
	 * Interface Boot
	 */
	
	event void Boot.booted(){
		dbg("cassNode","CASNodeP Boot.booted()\n");
	
		//Define número de hops (para testes)
		call RadioLifeCycle.setProperty((uint8_t*)"hops", HOPS_MAX_NUMBER);
		
		call LeaderElectionLifeCycle.setProperty((uint8_t*)"hops", HOPS_MAX_NUMBER);
		
		call MessageDisseminationLifeCycle.setProperty((uint8_t*)"hops", HOPS_MAX_NUMBER);
		call MessageDisseminationLifeCycle.setProperty((uint8_t*)"tries", 3);
		
		//Definir as salas
		if(TOS_NODE_ID >= 1 && TOS_NODE_ID <= 4){
			groupID = 1;
		}
		else if(TOS_NODE_ID >= 5 && TOS_NODE_ID <= 8){
			groupID = 2;
		}
		else if(TOS_NODE_ID >= 9 && TOS_NODE_ID <= 13){
			groupID = 3;
		}
		else {
			groupID = 55;
		}
		
		call MessageDisseminationLifeCycle.setProperty((uint8_t*)"groupID", groupID);
		call RadioLifeCycle.setProperty((uint8_t*)"groupID", groupID);
		call LeaderElectionLifeCycle.setProperty((uint8_t*)"groupID", groupID);
	
		//Inicia componente Radio
		//if(TOS_NODE_ID == ROOT_NODE){
		//caso seja o BaseStation
		//signal BSBoot.booted();
		//}
		//else
		call RadioBoot.start();
	
	}

	/*
	 * Boot
	 */ 
	event void RadioBoot.startDone(error_t error){
		if(error == SUCCESS){			
			//Inicializa componentes atraves da interface LifeCycle
			call RadioLifeCycle.init();
			call MessageDisseminationLifeCycle.init();
			call LeaderElectionLifeCycle.init();
	
			if(TOS_NODE_ID == ROOT_NODE){
				//Define que o BaseStation é o root
				call P2PRadio.setRoot();
				call SendProbeTimer.startOneShot(10000);
			}
			dbg("cass","CASS:Inicializacao completa.\n");
		}
		else{
			call RadioBoot.start();
		}
	}
	
	/* 
	 * Quando o lider for definido, envia uma mensagem para o Root.
	 */
	event void LeaderElection.announceVictoryDone(error_t error){
		//Se o nó for o lider, enviar uma mensagem.
		
		dbg("cass","CASS:Vitoria anunciada Lider='%u'.\n",call LeaderElection.retrieveLeader());
		
		if(call LeaderElection.retrieveLeader() == TOS_NODE_ID){
			cassMsg_t msg;
			msg.destID = 0;
			msg.srcID = TOS_NODE_ID;
			msg.value = 0;
			msg.groupID = groupID;
			msg.hops = 0;
	
			dbg("cass","CASS:Lider enviando para o Root.\n");
			memcpy(call Packet.getPayload(&sendBuff, call Packet.maxPayloadLength()), &msg, sizeof(cassMsg_t));
			call P2PRadio.send(msg.destID, &sendBuff, sizeof(cassMsg_t));
		}
	}
	
	/*
	 * Recebe uma mensagem tanto do Root para o Líder como do Líder para o Root
	 */
	event message_t * P2PRadio.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t data;
			
		memcpy(&data,payload,sizeof(cassMsg_t));
		
		if(call P2PRadio.isRoot()){
			if(data.messageType == ROUTING_MSG_ID){
				dbg("cass", "CASS:Rota para o líder da sala (%u) definida.\n", data.groupID);	
				//BSSend.send(): Informando ao java que a rota para a sala está definida	
			}
			else {
				dbg("cass", "CASS:O lider '%u' enviou o valor '%u' !\n",data.groupID, data.value);
				//TODO: Repassar mensagem para o cliente java
				//call BSSend.send(am_addr_t addr, message_t *msg, uint8_t len)
			}
		}
		else {
			dbg("cass","CASS:Enviando probe para o grupo (sensor=%d)\n", data.messageType);	
			call MessageDissemination.sendMessage(data.messageType);
		}
	
		return msg;
	}
	
	/*
	 * Root envia mensagem para o lider do grupo.
	 */
	event void SendProbeTimer.fired(){
		int GROUPID = 2;
		cassMsg_t data;
		dbg("cass","===CASS:Enviando a mensagem para o nó %u.\n", GROUPID);
		
		data.srcID = TOS_NODE_ID;
		data.destID = AM_BROADCAST_ADDR;
		data.groupID = GROUPID;
		data.hops = 0;
		data.messageID = 0;
		data.messageType = 0;
		data.value = TEMP_MSG_ID;
		
		memcpy(call Packet.getPayload(&sendBuff, call Packet.maxPayloadLength()), &data, sizeof(cassMsg_t));
		call P2PRadio.send(data.destID, &sendBuff, sizeof(cassMsg_t));		
	}
	
	/*
	 * Cada nó do grupo inicia a captura do valor para enviar para o líder.
	 */
	event void MessageDissemination.receiveRequest(cassMsg_t data){
		call EchoTimer.startOneShot(55 * TOS_NODE_ID);
		memcpy(&echoData, &data, sizeof(cassMsg_t));	
	}
	
	/*
	 * Respondendo um echo para o líder.
	 */
	event void EchoTimer.fired()
	{	
		cassMsg_t message;
		nx_int16_t sensorValue;
		error_t returnValue;
	
		dbg("cassDebug","[DEBUG] Recebi um Probe do Nó:%u.\n",echoData.srcID);	
		switch(echoData.value){ //value = SENSOR_TYPE
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
			dbg("cass","ProbeEcho.receiveProbe(): Erro '%u'  ao enviar mensagem para o nó %u!\n",returnValue, TOS_NODE_ID);    	
		}
	}
	
	event void MessageDissemination.receiveResponse(nx_uint16_t value){
		cassMsg_t data;
	
		dbg("cass","CASS:Recebi a média do sensor requisitado. Enviando valor:%u para o Root.\n", data.value);
	
		data.srcID = TOS_NODE_ID;
		data.destID = AM_BROADCAST_ADDR;
		data.value = value;
		data.groupID = 0;
		data.hops = 0;
		
		memcpy(call Packet.getPayload(&sendBuff, call Packet.maxPayloadLength()), &data, sizeof(cassMsg_t));
		call P2PRadio.send(data.destID, &sendBuff, sizeof(cassMsg_t));
	}

	event void RadioBoot.stopDone(error_t error){}	
	event void MessageDisseminationLifeCycle.stopDone(error_t error){}
	event void MessageDisseminationLifeCycle.initDone(error_t error){}
	event void LeaderElectionLifeCycle.stopDone(error_t error){}
	event void LeaderElectionLifeCycle.initDone(error_t error){}
	event void P2PRadio.sendDone(message_t *msg, error_t error){}
	event void LeaderElection.startElectionDone(error_t error){}
	event void LeaderElection.receiveResponse(cassMsg_t *data){}
	event void RadioLifeCycle.initDone(error_t error){}
	event void RadioLifeCycle.stopDone(error_t error){}
	event void Dummy.sendDone(message_t *msg, error_t error){}
	event void BSSend.sendDone(message_t *msg, error_t error){}
	event void MessageDissemination.replyRequestDone(error_t error){}	
}

