#include "cass.h"

module P2PRadioP{
	provides interface P2PRadio;
	provides interface LifeCycle;
	
	uses interface AMSend as RadioSend;
	uses interface Receive as RadioReceive;
	//uses interface LifeCycle as RadioLifeCycle;
	
	uses interface Send as SendCTP;
	uses interface Receive as ReceiveCTP;
	uses interface Intercept as InterceptCTP;
	
	uses interface RootControl;	
}
implementation{
	bool sendBusy = TRUE;
	uint parentID;
	nx_uint16_t messageID;
	p2pCache_t leaderBuffer[MAX_LEADER_BUFFER_LEN]; //Só para o Root que precisará do caminhos para os lideres
	uint16_t lastLeaderBuffer; 

	command void LifeCycle.stop(){
		//call RadioLifeCycle.stop();
	}

	command void LifeCycle.setProperty(uint8_t *option, uint16_t value){
		//call RadioLifeCycle.setProperty(option, value);
	}

	command void LifeCycle.init(){
		int i;

		parentID = 0;
		sendBusy = FALSE;
		messageID = 1;
		lastLeaderBuffer = 0;
		for(i = 0; i < MAX_LEADER_BUFFER_LEN ; i++){
			leaderBuffer[i].originalNodeID = 0;
			leaderBuffer[i].parentID = 0;
		}
		
		//call RadioLifeCycle.init();
	}

	command error_t P2PRadio.send(am_addr_t addr, message_t *msg, uint8_t len){
		cassMsg_t *payload;
		int i;
		nx_uint16_t clientID;
		
		payload = (cassMsg_t*) call RadioSend.getPayload(msg, len);
		clientID = payload->clientID;		
		
		if(call RootControl.isRoot()){
			dbg("p2p","P2PRadio.send: Root enviando mensagem para o nó:%u.\n",clientID);
			for(i = 0; i < MAX_LEADER_BUFFER_LEN; i++){
				if(leaderBuffer[i].originalNodeID == clientID){
					payload->groupID = 0;
					payload->hops = 0;
					payload->messageType = P2P_MSG_ID;

					return call RadioSend.send(leaderBuffer[i].parentID, msg, len);
				}
			}
			return -1;
		}		
		else{
			dbg("p2p","P2PRadio.send: Nó:%u enviando mensagem para o Root.\n");
			if(payload->serverID != TOS_NODE_ID){				
				dbg("p2p","[ERROR] P2PRadio.send: serverID deve ser o id do nó.\n");
			}
			
			return call SendCTP.send(msg, len);	
		}
	}
	
	//O nó que enviou a primeira mensagem irá definir serverID como sendo o próprio.
	//Já o clientID será sempre alterado para que os nós intermediários saibam que foi o parentID. 
	event bool InterceptCTP.forward(message_t *msg, void *payload, uint8_t len){
		cassMsg_t* message = (cassMsg_t*) payload;

		leaderBuffer[lastLeaderBuffer].originalNodeID = message->serverID;
		leaderBuffer[lastLeaderBuffer].parentID = message->clientID;

		message->clientID = TOS_NODE_ID;		
		return TRUE;
	}

	command void P2PRadio.setRoot(){
		call RootControl.setRoot();
	}
	
	command bool P2PRadio.isRoot(){
		return call RootControl.isRoot();
	}

	//Esse recebimento ocorre quando o Root está enviando para um 
	event message_t * RadioReceive.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t* message = (cassMsg_t*) payload;
		
		if(message->clientID == TOS_NODE_ID){
			dbg("p2p","RadioReceive.receive: Mensagem para mim vinda do Root.\n");
			signal P2PRadio.receive(msg, payload, len);
			return msg;
		}
		else{
			int i;
			for(i = 0; i < MAX_LEADER_BUFFER_LEN; i++){
				if(leaderBuffer[i].originalNodeID == message->clientID){
					call RadioSend.send(leaderBuffer[i].parentID, msg, len);
					dbg("p2p","RadioReceive.receive: Msg destino:%u | Enviando para:%u.\n", message->clientID, leaderBuffer[i].parentID);
					return msg;
				}
			}
		}
		
		dbg("p2p","[ERRO] RadioReceive.receive: Não identifiquei o destino da mensagem.\n");
		return msg;
	}
	
	event message_t * ReceiveCTP.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t* message;
		
		message = (cassMsg_t*) payload;
		leaderBuffer[lastLeaderBuffer].originalNodeID = message->serverID;
		leaderBuffer[lastLeaderBuffer].parentID = message->clientID;
		
		lastLeaderBuffer = lastLeaderBuffer % MAX_LEADER_BUFFER_LEN;
		signal P2PRadio.receive(msg, payload, len);		
		return msg;
	}

	event void RadioSend.sendDone(message_t *msg, error_t error){
		sendBusy = FALSE;
		signal P2PRadio.sendDone(msg, error);
	}
	
	event void SendCTP.sendDone(message_t *msg, error_t error){
		sendBusy = FALSE;
		signal P2PRadio.sendDone(msg, error);
	}
	
}