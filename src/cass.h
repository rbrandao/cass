#ifndef CASS_H
#define CASS_H

enum {
	HOPS_MAX_NUMBER = 3,
	TIMER_PERIOD = 2000,
	DELAY_TIME = 1050,

	//Tempo máximo de espera pela eleição
	ELECTION_TIMEOUT = 5000,
	
	//Node que iniciará a primeira eleição
	ELECTION_STARTER = 10,
	
	ELECTION_AM_ID = 200,
	RESPONSE_AM_ID = 201,
	VICTORY_AM_ID = 202
};

// broadcast
typedef nx_struct cass {
	nx_uint16_t serverID; // ID do Servidor.
	nx_uint16_t clientID; // ID do Cliente.
	nx_uint16_t messageID; //id da mensagem.
	nx_uint16_t groupID; //grupo que receberá a mensagem.
	nx_uint8_t hops; // número de saltos da mensagem.
	nx_uint16_t value; //o valor da mensagem.
} cassMsg_t;



#endif // CASS_H
