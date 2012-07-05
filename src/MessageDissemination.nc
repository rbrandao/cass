#include "cass.h"

interface MessageDissemination{
	//Comando e evento para envio/recibmento da disseminação de mensagem
	command error_t sendMessage(nx_uint16_t value); 
	event void receiveResponse(nx_uint16_t value); //Evento de fim de disseminação  (todas as respostas recebidas)

	event void receiveRequest(cassMsg_t data); //Os nós receberam uma requisicao.	
	command error_t replyRequest(cassMsg_t data); //Responde a requisicao recebida.
	event void replyRequestDone(error_t error); //Resposta enviada.
}