#ifndef CASS_H
#define CASS_H

enum {
	CASS_ID = 100,
	P2P_ID = 101,
	HOPS_MAX_NUMBER = 3,

	TIMER_PERIOD = 2000,
	DELAY_TIME = 1050,
	MAX_MESSAGE_ID_BUFFER_LEN = 5,
	MAX_LEADER_BUFFER_LEN = 10,

	PHOTO_MSG_ID = 501,
	TEMP_MSG_ID = 502,
	SENSOR = TEMP_MSG_ID,
	
	//Identificador da mensagem P2P
	P2P_MSG_ID = 301,
	

	/*
	 * Eleição de líder
	 */
	 
	//Identificadores das mensagens de eleição de líder
	ELECTION_MSG_ID = 200,
	RESPONSE_MSG_ID = 201,
	VICTORY_MSG_ID = 202,

	//Tempo máximo de espera pela eleição
	ELECTION_TIMEOUT = 5000,
	
	//Node que iniciará a primeira eleição
	ELECTION_STARTER = 1,
	
	
	/*
	 * Disseminação de mensagens
	 */

	//Identificadores das mensagens de disseminação
	PROBE_MSG_ID = 130,
	ECHO_MSG_ID =  131,
	DISCOVER_MSG_ID = 132,
	 
	//Máximo de vizinhos
	MAX_NEIGHBOURS = 6,
	
	//Timeout para finalização de um probe 
	PROBE_TIMEOUT = 5000,
};

// broadcast
typedef nx_struct cass {
	nx_uint16_t srcID; // ID do nó de origem.
	nx_uint16_t destID; // ID do nó de destino.
	nx_uint16_t messageID; // Contador da mensagem.
	nx_uint16_t groupID; // grupo que receberá a mensagem.
	nx_uint16_t hops; // número de saltos da mensagem.
	nx_uint16_t value; // valor da mensagem.
	nx_uint16_t messageType; //tipo da mensagem.
} cassMsg_t;

typedef nx_struct p2pCache {
	nx_uint16_t originalNodeID; // ID do nó que enviou a mensagem.
	nx_uint16_t parentID; //ID de onde a mensagem chegou.
} p2pCache_t;


#endif /* CASS_H */
