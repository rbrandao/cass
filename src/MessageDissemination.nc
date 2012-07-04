#include "cass.h"

interface MessageDissemination{
	//Comando e evento para envio/recibmento da disseminação de mensagem
	//command error_t sendMessage(cassMsg_t *data);
	command error_t sendMessage();
	event void receiveResponse(cassMsg_t *data);
	
	//Evento de fim de disseminação  (todas as respostas recebidas)
	event void messageDisseminationDone(cassMsg_t *data);

	//Comando para saber se existe disseminação em curso
	command bool isDisseminationRunning();
}