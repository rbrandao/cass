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

module LeaderElectionP{
	
	provides interface LeaderElection;
	provides interface LifeCycle;

	uses interface Timer<TMilli> as startElectionTimer;
	uses interface Timer<TMilli> as sendResponseTimer;
	uses interface Timer<TMilli> as waitResponsesTimer;
	uses interface Timer<TMilli> as waitVictoryTimer;
	uses interface Timer<TMilli> as announceVictoryTimer;
	
	uses interface SplitControl as Radio;
	uses interface Boot;
	
	uses interface AMSend as GroupSend;
	uses interface Receive as GroupReceive;
	uses interface LifeCycle as RadioLifeCycle;
}

implementation{
	bool radioBusy;
	bool isElectionRunning;
	message_t sendBuff;
	nx_uint16_t	hopsNum;
	nx_uint16_t leaderID;
	nx_uint16_t groupID;
	nx_uint16_t lastReceivedID;
	nx_uint32_t nodeDelay;
	

	/*
	 * Interface Boot
	 * 
	 * TODO: Verificar onde vai ser o boot posteriormente
	 */
	
	event void Boot.booted(){
		dbg("leaderElection","LeaderElectionP Boot.booted()\n");
		
		//Inicia componente de eleição
		call LifeCycle.init();
		
		//Cria um único grupo (para testes)
		call LifeCycle.setProperty("groupID", groupID);
		
		//Define número de hops (para testes)
		call LifeCycle.setProperty("hops", HOPS_MAX_NUMBER);
		
		//Inicia rádio
		call Radio.start();
	}

	/*
	 * Interface Radio
	 */
	 
	event void Radio.startDone(error_t error){
		dbg("leaderElection","LeaderElectionP Radio.startDone()\n");

		if(error == SUCCESS){
			
			//Inicializa rádio através da interface LifeCycle
			call RadioLifeCycle.init();		
	
			radioBusy = FALSE;
		
			if(TOS_NODE_ID == ELECTION_STARTER){
				dbg("leaderElection","LeaderElectionP Iniciando nova eleição em %dms\n",nodeDelay);
	
				//Dispara timer para início da eleição
				call startElectionTimer.startOneShot(nodeDelay);
			}
		}
		else{
			call Radio.start();
		}
	}

	event void Radio.stopDone(error_t error){
		dbg("leaderElection","LeaderElectionP Radio.stopDone()\n");
	}


	/*
	 * Interface LeaderElection
	 */
	 
	command bool LeaderElection.isElectionRunning(){
		return isElectionRunning;
	}
	
	command nx_uint16_t LeaderElection.retrieveLeader(){
		return leaderID;
	}

	command error_t LeaderElection.startNewElection(){
		cassMsg_t data;
		
		if(radioBusy){
			dbg("leaderElection", "LeaderElection.startElection(): radioBusy=TRUE Returning!\n");
			return 0;
		}
		radioBusy = TRUE;
		
		data.serverID = TOS_NODE_ID;
		data.clientID = AM_BROADCAST_ADDR;
		data.messageType = ELECTION_MSG_ID;
		data.groupID = groupID;
		
		memcpy(call GroupSend.getPayload(&sendBuff, call GroupSend.maxPayloadLength()), &data, sizeof(cassMsg_t));

		return call GroupSend.send(data.clientID, &sendBuff, sizeof(cassMsg_t));
	}

	command error_t LeaderElection.announceVictory(cassMsg_t *data){
		if(radioBusy){
			dbg("leaderElection", "LeaderElection.announceVictory(): radioBusy=TRUE Returning!\n");
			return 0;
		}
		radioBusy = TRUE;
		
		memcpy(call GroupSend.getPayload(&sendBuff, call GroupSend.maxPayloadLength()), data, sizeof(cassMsg_t));

		return call GroupSend.send(data->clientID, &sendBuff, sizeof(cassMsg_t));
	}

	command error_t LeaderElection.sendResponse(cassMsg_t *data){
		if(radioBusy){
			dbg("leaderElection", "LeaderElection.sendResponse(): radioBusy=TRUE Returning!\n");
			return 0;
		}
		radioBusy = TRUE;
		
		memcpy(call GroupSend.getPayload(&sendBuff, call GroupSend.maxPayloadLength()), data, sizeof(cassMsg_t));

		return call GroupSend.send(data->clientID, &sendBuff, sizeof(cassMsg_t));
	}


	/*
	 * Interfaces GroupSend/GroupReceive
	 */
	
	 event void GroupSend.sendDone(message_t *msg, error_t error){
		 cassMsg_t data;
		 radioBusy = FALSE;
	
		 memcpy(&data, call GroupSend.getPayload(msg, call GroupSend.maxPayloadLength()), sizeof(cassMsg_t));
	
		 if(error == SUCCESS){
			 switch(data.messageType){
				 case ELECTION_MSG_ID:
					 if(data.serverID == TOS_NODE_ID){
						 dbg("leaderElection","LeaderElectionP GroupSend.sendDone(): Eleição iniciada (timeout=%d)\n",ELECTION_TIMEOUT);
		
						 isElectionRunning = TRUE;
						 lastReceivedID = TOS_NODE_ID;
		
						 //Dispara timer para finalização da eleição
						 call waitResponsesTimer.startOneShot(ELECTION_TIMEOUT);
	 
						 break;
					 }
			 }
		 }
		 else {
			 dbg("leaderElection","LeaderElectionP GroupSend.sendDone() Erro=%d\n",error);
		 }
	 }
	
	event message_t * GroupReceive.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t data;

		dbg("leaderElection","LeaderElectionP GroupReceive.receive()\n");
		memcpy(&data,payload,sizeof(cassMsg_t));
	
		switch(data.messageType){
			case ELECTION_MSG_ID:
				dbg("leaderElection","LeaderElectionP GroupReceive.receive(): Nova eleição recebida de ID=%d\n",data.serverID);
				
				lastReceivedID = data.serverID;
	
				//Caso o iniciante desta eleição tenha ID menor, inicia-se outra imediatamente (bully)
				if(data.serverID < TOS_NODE_ID){
					//Responde com ID
					call sendResponseTimer.startOneShot(nodeDelay);
		
					//Dispara timer para início da eleição
					call startElectionTimer.startOneShot(nodeDelay*2);
				}
			
				break;
			
			case RESPONSE_MSG_ID:
				dbg("leaderElection","LeaderElectionP GroupReceive.receive(): Resposta recebida de ID=%d\n",data.serverID);
				
				//Caso receba um ID maior espera pelo anuncio da vitoria
				if(data.serverID > TOS_NODE_ID){
	
					dbg("leaderElection","LeaderElectionP GroupReceive.receive(): ID maior recebido, aguardando sua notificação (NodeID=%d)\n", data.serverID);
		
					if(call waitVictoryTimer.isRunning()){
						call waitVictoryTimer.stop();
					}
		
					//Guarda maior ID recebido
					lastReceivedID = data.serverID;
		
					call waitVictoryTimer.startOneShot(ELECTION_TIMEOUT*2);
				}
				
				break;
	
			case VICTORY_MSG_ID:
				dbg("leaderElection","LeaderElectionP GroupReceive.receive(): Vitória recebida de ID=%d\n",data.serverID);
				
				//Guarda ID líder eleito
				leaderID = data.serverID;
		
				//Fim da eleição
				isElectionRunning = FALSE;
		
				dbg("leaderElection","LeaderElectionP GroupReceive.receive(): Líder eleito=%d\n",leaderID);
		
				//Cancela timer caso o líder esperado seja declarado
				if(leaderID >= lastReceivedID){
					if(call waitVictoryTimer.isRunning()){
						call waitVictoryTimer.stop();
					}
				}
				
				break;
		}

		
		return msg;
	}

	/*
	 * Timers
	 */

	event void startElectionTimer.fired(){
		call LeaderElection.startNewElection();
	}
	
	event void announceVictoryTimer.fired(){
		cassMsg_t data;
		data.serverID = leaderID;
		data.clientID = AM_BROADCAST_ADDR;
		data.groupID = groupID;
		data.messageType = VICTORY_MSG_ID;
		
		call LeaderElection.announceVictory(&data);
	}

	event void waitResponsesTimer.fired(){
		//Se ao fim do tempo de eleição TOS_NODE_ID for o maior, declara-se líder
		if(lastReceivedID == TOS_NODE_ID){
			leaderID = TOS_NODE_ID;
			
			//Anuncia vitória da eleição, com timer para evitar possíveis colisões
			call announceVictoryTimer.startOneShot(nodeDelay);
		}
	}

	event void waitVictoryTimer.fired(){
		//O líder não foi declarado em tempo hábil, uma nova eleição deve ser iniciada
		call startElectionTimer.startOneShot(nodeDelay);
	}


	event void sendResponseTimer.fired(){
		cassMsg_t data;
		data.serverID = TOS_NODE_ID;
		data.clientID = lastReceivedID;
		data.groupID = groupID;
		data.messageType = RESPONSE_MSG_ID;
		
		call LeaderElection.sendResponse(&data);
	}

	
	/*
	 * Eventos do Radio LifeCycle
	 */
	 
	event void RadioLifeCycle.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void RadioLifeCycle.initDone(error_t error){
		// TODO Auto-generated method stub
	}


	/*
	 * LeaderElection LifeCycle
	 */
	 
	command void LifeCycle.init(){
		//Inicializa variáveis
		radioBusy = TRUE;
		isElectionRunning = FALSE;
		leaderID = 0;
		lastReceivedID = 0;
		nodeDelay = (TOS_NODE_ID * 15)+50;
		groupID = 1;
		hopsNum = HOPS_MAX_NUMBER;
		
	}

	command void LifeCycle.setProperty(uint8_t *option, uint16_t value){
		if(strcmp(option,"hops") == 0){
			dbg("lifeCycle", "LeaderElection: Set Hops:%u.\n", value);
			hopsNum = value;
		}
		
		if(strcmp((char*)option, "groupID") == 0){
			dbg("lifeCycle", "LeaderElection: Set GroupID:%u.\n",value);
			groupID = value;
		}
		
		//Deep configuration.
		call RadioLifeCycle.setProperty(option, value);
	}

	command void LifeCycle.stop(){
		
		//Finaliza eventual eleição em andamento
		isElectionRunning = FALSE;
		
		if(call announceVictoryTimer.isRunning()){
			call announceVictoryTimer.stop();
		}
		if(call startElectionTimer.isRunning()){
			call startElectionTimer.stop();
		}
		if(call sendResponseTimer.isRunning()){
			call sendResponseTimer.stop();
		}
		if(call waitResponsesTimer.isRunning()){
			call waitResponsesTimer.stop();
		}
		if(call waitVictoryTimer.isRunning()){
			call waitVictoryTimer.stop();
		}
	}
}

