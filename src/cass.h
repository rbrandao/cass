#ifndef CASS_H
#define CASS_H

enum {
	CASS_ID = 100, 
	HOPS_MAX_NUMBER = 3,

	TIMER_PERIOD = 2000,
	DELAY_TIME = 1050,
	MAX_MESSAGE_ID_BUFFER_LEN = 5,

	//Tempo máximo de espera pela eleição
	ELECTION_TIMEOUT = 5000,
	
	//Node que iniciará a primeira eleição
	ELECTION_STARTER = 10,
	
	ELECTION_MSG_ID = 200,
	RESPONSE_MSG_ID = 201,
	VICTORY_MSG_ID = 202
};

// broadcast
typedef nx_struct cass {
	nx_uint16_t serverID; // ID do Servidor.
	nx_uint16_t clientID; // ID do Cliente.
	nx_uint16_t messageID; // id da mensagem.
	nx_uint16_t groupID; // grupo que receberá a mensagem.
	nx_uint16_t hops; // número de saltos da mensagem.
	nx_uint16_t value; // valor da mensagem.
	nx_uint16_t electionMsgID; //tipo da mensagem de eleição
} cassMsg_t;



#endif /* CASS_H */
