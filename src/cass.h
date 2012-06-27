#ifndef CASS_H
#define CASS_H

enum {
	CASS_ID = 100,
	HOPS_MAX_NUMBER = 4,
	TIMER_PERIOD = 2000,
	DELAY_TIME = 1050,

	//Tempo máximo de espera pela eleição
	ELECTION_TIMEOUT = 10000,
	
	//Node que iniciará a primeira eleição
	ELECTION_STARTER = 1,
	
	//Identificadores das mensagens de eleição de líder
	ELECTION_MSG_ID = 200,
	RESPONSE_MSG_ID = 201,
	VICTORY_MSG_ID = 202
};

// broadcast
typedef nx_struct cass {
	nx_uint16_t serverID; // ID do Servidor.
	nx_uint16_t clientID; // ID do Cliente.
	nx_uint16_t messageID; //id da mensagem.
	nx_uint16_t electionMsgID; //id da mensagem de eleição de líder.
	nx_uint16_t groupID; //grupo que receberá a mensagem.
	nx_uint8_t hops; // número de saltos da mensagem.
	nx_uint16_t value; //o valor da mensagem.
} cassMsg_t;



#endif // CASS_H
