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
	uses interface Timer<TMilli> as startElectionTimer;
	uses interface Timer<TMilli> as sendResponseTimer;
	uses interface Timer<TMilli> as waitResponsesTimer;
	uses interface Timer<TMilli> as waitVictoryTimer;
	uses interface Timer<TMilli> as announceVictoryTimer;
	
	provides interface LeaderElection;
	//provides interface LifeCycle;

	uses interface SplitControl as Radio;
	uses interface Boot;
	
	uses interface AMSend as GroupSend;
	uses interface Receive as GroupReceive;
}

implementation{
	bool radioBusy;
	bool isElectionRunning;
	message_t sendBuff;
	nx_uint16_t leaderID;
	nx_uint16_t lastReceivedID;
	nx_uint32_t nodeDelay;
	

	/*
	 * Interface Boot
	 */
	
	event void Boot.booted(){
		dbg("leaderElection","LeaderElectionP Boot.booted()\n");
		
		//Inicializa variáveis
		radioBusy = TRUE;
		isElectionRunning = FALSE;
		leaderID = 0;
		lastReceivedID = 0;
		nodeDelay = (TOS_NODE_ID * 15)+50;
		
		//Inicia rádio
		call Radio.start();
	}

	/*
	 * Interface Radio
	 */
	 
	event void Radio.startDone(error_t error){
		dbg("leaderElection","LeaderElectionP Radio.startDone()\n");

		if(error == SUCCESS){
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
		data.messageID = ELECTION_MSG_ID;
		
		memcpy(call GroupSend.getPayload(&sendBuff, call GroupSend.maxPayloadLength()), &data, sizeof(cassMsg_t));

		return call GroupSend.send(AM_BROADCAST_ADDR, &sendBuff, sizeof(cassMsg_t));
	}

	command error_t LeaderElection.announceVictory(cassMsg_t *data){
		if(radioBusy){
			dbg("leaderElection", "LeaderElection.announceVictory(): radioBusy=TRUE Returning!\n");
			return 0;
		}
		radioBusy = TRUE;
		
		memcpy(call GroupSend.getPayload(&sendBuff, call GroupSend.maxPayloadLength()), data, sizeof(cassMsg_t));

		return call GroupSend.send(AM_BROADCAST_ADDR, &sendBuff, sizeof(cassMsg_t));
	}

	command error_t LeaderElection.sendResponse(cassMsg_t *data){
		if(radioBusy){
			dbg("leaderElection", "LeaderElection.sendResponse(): radioBusy=TRUE Returning!\n");
			return 0;
		}
		radioBusy = TRUE;
		
		memcpy(call GroupSend.getPayload(&sendBuff, call GroupSend.maxPayloadLength()), data, sizeof(cassMsg_t));

		return call GroupSend.send(lastReceivedID, &sendBuff, sizeof(cassMsg_t));
	}


	/*
	 * Interfaces GroupSend/GroupReceive
	 */
	
	 event void GroupSend.sendDone(message_t *msg, error_t error){
		 cassMsg_t data;
		 radioBusy = FALSE;
	
		 memcpy(&data, call GroupSend.getPayload(msg, call GroupSend.maxPayloadLength()), sizeof(cassMsg_t));
	
		 if(error == SUCCESS){
			 switch(data.messageID){
				 case ELECTION_MSG_ID:
				 
					 dbg("leaderElection","LeaderElectionP GroupSend.sendDone(): Eleição iniciada\n");
		
					 isElectionRunning = TRUE;
					 lastReceivedID = TOS_NODE_ID;
		
					 //Dispara timer para finalização da eleição
					 call waitResponsesTimer.startOneShot(ELECTION_TIMEOUT);
					 
					 break;
			 }
		 }
		 else {
			 dbg("leaderElection","LeaderElectionP GroupSend.sendDone() Erro=%d\n",error);
		 }
	 }
	
	event message_t * GroupReceive.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t data;

		dbg("leaderElection","LeaderElectionP ReceiveElection.receive()\n");
		memcpy(&data,payload,sizeof(cassMsg_t));
	
		switch(data.messageID){
			case ELECTION_MSG_ID:
			
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
			
				//Caso receba um ID maior espera pelo anuncio da vitoria
				if(data.serverID > TOS_NODE_ID){
	
					dbg("leaderElection","LeaderElectionP GroupReceive.receive(): ID maior recebido, aguardando sua notificação (NodeID=%d)\n", data.serverID);
		
					if(call waitVictoryTimer.isRunning()){
						call waitVictoryTimer.stop();
					}
		
					//Guarda maior ID recebido
					lastReceivedID = data.serverID;
		
					call waitVictoryTimer.startOneShot(ELECTION_TIMEOUT);
				}
				
				break;
	
			case VICTORY_MSG_ID:
	
				//Guarda ID líder eleito
				leaderID = data.serverID;
		
				//Fim da eleição
				isElectionRunning = FALSE;
		
				dbg("leaderElection","LeaderElectionP GroupReceive.receive(): Líder eleito=%d\n",leaderID);
		
				//Cancela timer caso o líder esperado seja declarado
				if(leaderID == lastReceivedID){
					if(call waitVictoryTimer.isRunning()){
						call waitResponsesTimer.stop();
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
		
		call LeaderElection.sendResponse(&data);
	}
}

