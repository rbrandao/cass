#ifndef CASS_H
#define CASS_H

enum {
	CASS_ID = 100, 
	HOPS_MAX_NUMBER = 3,

	TIMER_PERIOD = 2000,
	DELAY_TIME = 1050,

	
	LIDER_ELECTION_ID = 200,
	LIDER_RESPONSE_ID = 201,
	LIDER_VICTORY_ID = 202,
	
	MAX_MESSAGE_ID_BUFFER_LEN = 5,
};

// broadcast
typedef nx_struct cass {
	nx_uint16_t serverID; // ID do Servidor.
	nx_uint16_t clientID; // ID do Cliente.
	nx_uint16_t messageID; // id da mensagem.

	nx_uint16_t groupID; // grupo que receberá a mensagem.
	nx_uint16_t hops; // número de saltos da mensagem.
	
	nx_uint16_t value; // valor da mensagem.
} cassMsg_t;



#endif /* CASS_H */
