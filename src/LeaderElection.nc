/**
 * Desenvolvido para a disciplina de Redes de Sensores Sem Fio (INF-2592)
 * ministrada na Pontifícia Universidade Católica pela Prof. Noemi Rodriguez
 *
 * @author Mauricio Rosas
 * @author Rafael Brandão
 * @date  Junho, 2012
 *
 * Definição da interface do componente que encapsula a eleição de líderes (algoritmo bully)
 * para o projeto final proposto. O algoritmo 'bully' considera as seguintes premissas:
 * 
 * Quando um node N inicia ou detecta que um coordenador (líder) está offline, através de timeouts ou uma falha na comunicação, ele realiza os seguintes passos:
 * 
 * 1) N envia em broadcast uma messagem de nova eleição (electionMsg), com delay baseado em seu ID para evitar colisões;
 * 
 * 2) Se N não receber uma mensagem de resposta (responseMsg) com um NodeID maior que o seu, ele vence a eleição e 
 * dissemina em broadcast a sua vitória (victoryMsg);
 * 
 * 3) Se N receber uma resposta com um NodeID superior ao seu, N espera um tempo pré-definido para que aquele node 
 * dissemine sua vitória. Se a mensagem de vitória não for recebida à tempo, N inicia uma nova eleição;
 * 
 * 4) Se N receber uma mensagem de nova eleição de um node com menor ID, ele imediatamente inicia uma nova 
 * eleição (bully)
 * 
 */
 
#include "cass.h"

interface LeaderElection {
	
	//Comando para recuperação do líder atual (caso não exista retorna zero)
	command nx_uint16_t retrieveLeader();
	
	//Comando e evento de início de eleição
	command error_t startNewElection();
	event void startElectionDone(error_t error);
	
	//Comando e evento para envio/recibmento da mensagem de resposta
	command error_t sendResponse(cassMsg_t *data);
	event void receiveResponse(cassMsg_t *data);

	//Comando e evento de anuncio de fim de eleição
	command error_t announceVictory(cassMsg_t *data);
	event void announceVictoryDone(error_t error);

	//Comando para saber se existe uma eleição em curso
	command bool isElectionRunning();
}
