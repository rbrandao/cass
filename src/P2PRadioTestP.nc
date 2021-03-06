#include "cass.h"

module P2PRadioTestP {
	uses interface Boot;
	uses interface P2PRadio;
	uses interface LifeCycle as RadioLifeCycle;
	uses interface SplitControl as Radio;
	uses interface Timer<TMilli> as Timer;
	uses interface Packet;
	uses interface AMSend as Dummy;
}
implementation {

	bool sendBusy = TRUE;
	message_t sendBuff;
	uint8_t msgID;

	event void Boot.booted() {
		dbg("Test", "Boot.booted()\n");
		msgID = 1;

		call Radio.start();
	}

	event void RadioLifeCycle.initDone(error_t error) {
		dbg("Test", "RadioLifeCycle.initDone()\n");
	}

	//O nó 4 e 5 enviarão uma mensagem para o Root(nó 1)
	// que ao receber uma mensagem reenviará uma requisicão ao nós novamente.
	event void Radio.startDone(error_t error) {
		dbg("Test", "Radio.startDone()\n");

		if(error != SUCCESS) {
			call Radio.start();
			return;
		}
		call RadioLifeCycle.init();
		sendBusy = FALSE;

		if(TOS_NODE_ID == 1) {
			dbg("Test", "Sou o Root.\n");
			call P2PRadio.setRoot();
		}

		if(TOS_NODE_ID == 4 || TOS_NODE_ID == 5) {
			call Timer.startOneShot(100 * TOS_NODE_ID);
		}
	}

	event void Timer.fired() {
		cassMsg_t message;
		error_t returnValue = SUCCESS;

		dbg("Test", "Enviando mensagem para o Root.\n");
		if(sendBusy) {
			dbg("Test", "Timer.fired(): Radio ocupado.\n");
		}

		sendBusy = TRUE;
		message.srcID = TOS_NODE_ID;
		message.destID = 0;
		message.groupID =  TOS_NODE_ID % 3;
		message.hops = 0;
		message.messageID = msgID++;
		message.value = TOS_NODE_ID + msgID;
		memcpy(call Packet.getPayload(&sendBuff, call Packet.maxPayloadLength()), 
				&message, sizeof(cassMsg_t));

		returnValue = call P2PRadio.send(AM_BROADCAST_ADDR, &sendBuff,
				sizeof(cassMsg_t));
		if(returnValue != SUCCESS) {
			dbg("Test", "Timer.fired(): Erro '%u'  ao enviar mensagem para o id %u!\n",
					returnValue, msgID);
		}
	}

	event message_t * P2PRadio.receive(message_t * msg, void * payload,
			uint8_t len) {
		error_t returnValue;
		cassMsg_t message;
		cassMsg_t reply;

		memcpy(&message, payload, sizeof(cassMsg_t));
		if(call P2PRadio.isRoot()) {
			dbg("Test",
					"Root: recebi a mensagem. Reenviando um mensagem para o grupo:%u.\n", 
					message.groupID);
			reply.srcID = TOS_NODE_ID;
			reply.destID = 0;
			reply.groupID = message.groupID;
			reply.hops = 0;
			reply.messageID = msgID++;
			reply.messageType = PHOTO_MSG_ID;
			reply.value = 100 + message.srcID;

			memcpy(call Packet.getPayload(&sendBuff, call Packet.maxPayloadLength()), 
					&reply, sizeof(cassMsg_t));
			returnValue = call P2PRadio.send(AM_BROADCAST_ADDR, &sendBuff,
					sizeof(cassMsg_t));
			if(returnValue != SUCCESS) {
				dbg("Test",
						" P2PRadio.receive(): Erro '%u'  ao enviar mensagem para o id %u!\n",
						returnValue, msgID);
			}
		}
		else {
			dbg("Test", "O root me enviou o valor:%u.\n", message.value);
		}

		return msg;
	}

	event void RadioLifeCycle.stopDone(error_t error) {
		dbg("Teste", "RadioLifeCycle.stopDone()\n");
	}

	event void P2PRadio.sendDone(message_t * msg, error_t error) {
		dbg("Test", "RadioSend.sendDone()\n");
	}

	event void Radio.stopDone(error_t error) {
		// TODO Auto-generated method stub
	}

	event void Dummy.sendDone(message_t * msg, error_t error) {
		// TODO Auto-generated method stub
	}
}