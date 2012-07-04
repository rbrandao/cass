#include "cass.h"

interface ProbeEcho{
	command error_t probe(nx_uint16_t sensorType); //Inicia o Probe
	event void probeDone(nx_uint16_t value); //Finaliza o Probe recebendo o valor esperado.
	
	event void receiveProbe(cassMsg_t data); // O nó recebeu um Probe.	
	command error_t echo(cassMsg_t data); //Envia um echo.
	event void echoDone(error_t error); //Echo enviado.

}