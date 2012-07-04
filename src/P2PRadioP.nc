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
    uses interface StdControl as RoutingControl;
    uses interface CtpPacket as CtpPacket;
    uses interface AMPacket;
	
	uses interface RootControl;	
}
implementation{
	bool sendBusy = TRUE;
	uint parentID;
	nx_uint16_t messageID;
	p2pCache_t leaderBuffer[MAX_LEADER_BUFFER_LEN]; //Só para o Root que precisará do caminhos para os lideres
	uint16_t lastLeaderBuffer; 
	message_t sendBuff;

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
		

		call RoutingControl.start();
		dbg("p2pRadio","LifeCycle.init: Componente iniciado.\n");
		//call RadioLifeCycle.init();
	}

	command error_t P2PRadio.send(am_addr_t addr, message_t *msg, uint8_t len){
		cassMsg_t payload;
		int i;
		nx_uint16_t destID;
		
		memcpy(&payload,call RadioSend.getPayload(msg,call RadioSend.maxPayloadLength()),sizeof(cassMsg_t));
		destID = payload.destID;		
		
		if(call RootControl.isRoot()){
			dbg("p2pRadio","P2PRadio.send: Root enviando mensagem para o nó:%u.\n",destID);
			for(i = 0; i < MAX_LEADER_BUFFER_LEN; i++){
				if(leaderBuffer[i].originalNodeID == destID){
					payload.groupID = 0;
					payload.hops = 0;
					payload.messageType = P2P_MSG_ID;

					memcpy(call RadioSend.getPayload(&sendBuff,call RadioSend.maxPayloadLength()), &payload, sizeof(cassMsg_t));
					return call RadioSend.send(leaderBuffer[i].parentID, &sendBuff, len);
				}
			}
			return -1;
		}		
		else{
			dbg("p2pRadio","P2PRadio.send: Nó:%u enviando mensagem para o Root.\n", payload.srcID);
			if(payload.srcID != TOS_NODE_ID){				
				dbg("p2pRadio","[ERROR] P2PRadio.send: srcID deve ser o id do nó.\n");
			}
			
			return call SendCTP.send(msg, len);	
		}
	}
	
	//O nó que enviou a primeira mensagem irá definir srcID como sendo o próprio.
	//Já o destID será sempre alterado para que os nós intermediários saibam que foi o parentID. 
	event bool InterceptCTP.forward(message_t *msg, void *payload, uint8_t len){
		/*cassMsg_t* message;
		
		message = (cassMsg_t*) call CtpPacket.getPayload(msg, len);
		
		//dbg("p2pRadio","Intercept: OriginalNode:%u | ParentID:%u | groupID:%u | messageID:%u.\n",message->srcID, message->destID, message->groupID, message->messageID);
		
		leaderBuffer[lastLeaderBuffer].originalNodeID = message->srcID;
		leaderBuffer[lastLeaderBuffer].parentID = message->destID;

		message->destID = TOS_NODE_ID;		*/
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
		cassMsg_t* message;

		message = (cassMsg_t*) call RadioSend.getPayload(msg, len);
		
		if(message->destID == TOS_NODE_ID){
			dbg("p2pRadio","RadioReceive.receive: Mensagem para mim vinda do Root.\n");
			return msg;
		}
		else{
			int i;
			for(i = 0; i < MAX_LEADER_BUFFER_LEN; i++){
				if(leaderBuffer[i].originalNodeID == message->destID){
					call RadioSend.send(leaderBuffer[i].parentID, msg, len);
					dbg("p2pRadio","RadioReceive.receive: Msg destino:%u | Enviando para:%u.\n", message->destID, leaderBuffer[i].parentID);
					return msg;
				}
			}
		}
		
		dbg("p2pRadio","[ERRO] RadioReceive.receive: Não identifiquei o destino da mensagem.\n");
		return msg;
	}
	
	event message_t * ReceiveCTP.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t* message;

		message = (cassMsg_t*) call RadioSend.getPayload(msg, len);
		leaderBuffer[lastLeaderBuffer].originalNodeID = message->srcID;
		leaderBuffer[lastLeaderBuffer].parentID = message->destID;
		
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