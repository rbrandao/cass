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

module leaderElectionP{
	uses interface Timer<TMilli> as startElectionTimer;
	uses interface Timer<TMilli> as sendResponseTimer;
	uses interface Timer<TMilli> as waitResponsesTimer;
	uses interface Timer<TMilli> as waitVictoryTimer;
	uses interface Timer<TMilli> as announceVictoryTimer;
	
	provides interface leaderElection;

	uses interface SplitControl as Radio;
	uses interface Boot;
	
	uses interface AMSend as SendElection;
	uses interface Receive as ReceiveElection;
	
	uses interface AMSend as SendResponse;
	uses interface Receive as ReceiveResponse;
	
	uses interface AMSend as SendVictory;
	uses interface Receive as ReceiveVictory;
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
		dbg("finalProject","leaderElectionP Boot.booted()\n");
		
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
		dbg("finalProject","leaderElectionP Radio.startDone()\n");

		if(error == SUCCESS){
			radioBusy = FALSE;
		
			if(TOS_NODE_ID == ELECTION_STARTER){
				dbg("finalProject","leaderElectionP Iniciando nova eleição em %dms\n",nodeDelay);
	
				//Dispara timer para início da eleição
				call startElectionTimer.startOneShot(nodeDelay);
			}
		}
		else{
			call Radio.start();
		}
	}

	event void Radio.stopDone(error_t error){
		dbg("finalProject","leaderElectionP Radio.stopDone()\n");
	}


	/*
	 * Interface LeaderElection
	 */
	 
	command bool leaderElection.isElectionRunning(){
		return isElectionRunning;
	}
	
	command nx_uint16_t leaderElection.retrieveLeader(){
		return leaderID;
	}

	command error_t leaderElection.startNewElection(){
		cassMsg_t data;
		
		if(radioBusy){
			dbg("finalProject", "leaderElection.startElection(): radioBusy=TRUE Returning!\n");
			return 0;
		}
		radioBusy = TRUE;
		
		data.serverID = TOS_NODE_ID;
		
		memcpy(call SendElection.getPayload(&sendBuff, call SendElection.maxPayloadLength()), &data, sizeof(cassMsg_t));

		return call SendElection.send(AM_BROADCAST_ADDR, &sendBuff, sizeof(cassMsg_t));
	}

	command error_t leaderElection.announceVictory(cassMsg_t *data){
		if(radioBusy){
			dbg("finalProject", "leaderElection.announceVictory(): radioBusy=TRUE Returning!\n");
			return 0;
		}
		radioBusy = TRUE;
		
		memcpy(call SendVictory.getPayload(&sendBuff, call SendVictory.maxPayloadLength()), data, sizeof(cassMsg_t));

		return call SendVictory.send(AM_BROADCAST_ADDR, &sendBuff, sizeof(cassMsg_t));
	}

	command error_t leaderElection.sendResponse(cassMsg_t *data){
		if(radioBusy){
			dbg("finalProject", "leaderElection.sendResponse(): radioBusy=TRUE Returning!\n");
			return 0;
		}
		radioBusy = TRUE;
		
		memcpy(call SendResponse.getPayload(&sendBuff, call SendResponse.maxPayloadLength()), data, sizeof(cassMsg_t));

		return call SendResponse.send(lastReceivedID, &sendBuff, sizeof(cassMsg_t));
	}


	/*
	 * Interfaces Send/Receive Election
	 */
	
	event void SendElection.sendDone(message_t *msg, error_t error){
		radioBusy = FALSE;
		
		if(error == SUCCESS){
			dbg("finalProject","leaderElectionP SendElection.sendDone()\n");
			
			isElectionRunning = TRUE;
			lastReceivedID = TOS_NODE_ID;
			
			//Dispara timer para finalização da eleição
			call waitResponsesTimer.startOneShot(ELECTION_TIMEOUT);
		}
		else {
			dbg("finalProject","leaderElectionP SendElection.sendDone() Erro=%d\n",error);
		}
	}
	
	event message_t * ReceiveElection.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t data;

		dbg("finalProject","leaderElectionP ReceiveElection.receive()\n");
		memcpy(&data,payload,sizeof(cassMsg_t));

		lastReceivedID = data.serverID;

		//Caso o iniciante desta eleição tenha ID menor, inicia-se outra imediatamente (bully)
		if(data.serverID < TOS_NODE_ID){
			//Responde com ID
			call sendResponseTimer.startOneShot(nodeDelay);
			
			//Dispara timer para início da eleição
			call startElectionTimer.startOneShot(nodeDelay*2);
		}
	
		return msg;
	}


	/*
	 * Interfaces Send/Receive Response
	 */
	
	event void SendResponse.sendDone(message_t *msg, error_t error){
		dbg("finalProject","leaderElectionP SendResponse.sendDone()\n");
		
		if(error != SUCCESS)
			dbg("finalProject","leaderElectionP SendResponse.sendDone(): Error=%d\n",error);
		radioBusy = FALSE;
	}

	event message_t * ReceiveResponse.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t data;
	
		memcpy(&data,payload,sizeof(cassMsg_t));

		dbg("finalProject","leaderElectionP ReceiveResponse.receive(): ID recebido=%d\n", data.serverID);


		//Caso receba um ID maior espera pelo anuncio da vitoria
		if(data.serverID > TOS_NODE_ID){

			dbg("finalProject","leaderElectionP ReceiveResponse.receive(): ID maior recebido, aguardando sua notificação (NodeID=%d)\n", data.serverID);
	
			if(call waitVictoryTimer.isRunning()){
				call waitVictoryTimer.stop();
			}
	
			//Guarda maior ID recebido
			lastReceivedID = data.serverID;
	
			call waitVictoryTimer.startOneShot(ELECTION_TIMEOUT);
		}

		return msg;
	}

	
	/*
	 * Interfaces Send/Receive Victory
	 */
	
	event void SendVictory.sendDone(message_t *msg, error_t error){
		dbg("finalProject","leaderElectionP SendVictory.sendDone()\n");
		
		if(error != SUCCESS)
			dbg("finalProject","leaderElectionP SendVictory.sendDone(): Error=%d\n",error);
		radioBusy = FALSE;
	}

	event message_t * ReceiveVictory.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t data;

		memcpy(&data,payload,sizeof(cassMsg_t));

		//Guarda ID líder eleito
		leaderID = data.serverID;
		
		//Fim da eleição
		isElectionRunning = FALSE;
		
		dbg("finalProject","leaderElectionP ReceiveVictory.receive(): Líder eleito=%d\n",leaderID);
		
		//Cancela timer caso o líder esperado seja declarado
		if(leaderID == lastReceivedID){
			if(call waitVictoryTimer.isRunning()){
				call waitResponsesTimer.stop();
			}
		}
		
		//Repassa líder eleito
		call announceVictoryTimer.startOneShot(nodeDelay);
		
		return msg;
	}
	
	/*
	 * Timers
	 */

	event void startElectionTimer.fired(){
		call leaderElection.startNewElection();
	}
	
	event void announceVictoryTimer.fired(){
		cassMsg_t data;
		data.serverID = leaderID;
		
		call leaderElection.announceVictory(&data);
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
		
		call leaderElection.sendResponse(&data);
	}
}

