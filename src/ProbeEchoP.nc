/**
 * Desenvolvido para a disciplina de Redes de Sensores Sem Fio (INF-2592)
 * ministrada na Pontifícia Universidade Católica pela Prof. Noemi Rodriguez
 *
 * @author Mauricio Rosas
 * @author Rafael Brandão
 * @date  Junho, 2012
 *
 * Implementação do componente que encapsula a disseminação de mensagens (algoritmo Probe/Echo)
 * para o projeto final proposto
 */
 
#include "cass.h"

module ProbeEchoP{

	provides {
		interface MessageDissemination;
		interface LifeCycle;
	}

	uses {
//		interface Boot;
//		interface Leds;
//		interface SplitControl as RadioControl;
		
		interface Timer<TMilli> as discoverSendTimer;
		interface Timer<TMilli> as probeSendTimer;
		interface Timer<TMilli> as echoSendTimer;
		interface Timer<TMilli> as alreadyProbingSendTimer;
		interface Timer<TMilli> as probeTimeoutTimer;
	
		interface Read<uint16_t> as tempSensor;
	
		interface AMSend as GroupSend;
		interface Receive as GroupReceive;
		interface LifeCycle as RadioLifeCycle;
	}
}
implementation{
	//Tasks para executar tratamentos de probes e echoes
	task void probe();
	task void alreadyProbing();
	task void echo();
	
	//Variáveis do rádio (lock e buffer)
	bool sendBusy;
	message_t sendBuff;
	
	//Array com vizinhos
	nx_uint16_t neighbours[MAX_NEIGHBOURS];
	int neighbourCount;
	
	//Identificador do mote que iniciou um probe
	nx_uint16_t reqProbeMote;
	
	//Identificador de mote que requisitou um probe enquanto outro estava senso realizado
	nx_uint16_t otherProbingMote;
	
	//Contador do número de echoes recebidos (incluindo dummy echoes)
	nx_uint16_t echoCount;

	//Contador do número de echoes recebidos (sem dummy echoes)
	nx_uint16_t echoesReceivedCount;
	
	//Valor lido no sensor
	nx_uint32_t sensorRead;
	nx_uint32_t echoSumValue;
	
	//Flag que identifica se o mote está realizando um probe
	bool isProbing;
	
	//Flag indicando se o probe foi iniciado por este node
	bool startingNode;
	
	//Valor máximo de hops na topologia
	nx_uint16_t	hopsNum;
	
	//Identificador do Grupo
	nx_uint16_t groupID;
	
	//Delay para evitar colisões
	nx_uint32_t nodeDelay;
	

	/**
	 * Auxiliar
	 */
	 
	//Função auxiliar para inserir mote vizinho no array
	bool addNeighbour(uint16_t mote){
		// Checa se vizinho já está na lista
		int i;
		for(i=0; i < neighbourCount; i++){
			if(neighbours[i] == mote){
				dbg("probeEcho","addNeighbour: Vizinho NodeID=%d já inserido! (neighbourCount=%d)\n", mote, neighbourCount);
				return TRUE;
			}
		}
		// Adiciona vizinho se ainda tiver espaço no array
		if(neighbourCount < MAX_NEIGHBOURS){
			neighbours[neighbourCount++] = mote;
			dbg("probeEcho","addNeighbour: Inserindo vizinho NodeID=%d (neighbourCount=%d)\n", mote, neighbourCount);
			return TRUE;
		}

		dbg("probeEcho","addNeighbour: Erro ao inserir vizinho NodeID=%d (neighbourCount=%d max=%d)\n", mote, neighbourCount, MAX_NEIGHBOURS);
		return FALSE;
	}

	
	/**
	 * Tasks 
	 */
 
	//Task para envio de probes
	task void probe(){
		cassMsg_t 	probeData;
		nx_uint16_t i;
	
		dbg("probeEcho","probe(): sendBusy=%s neighbourCount=%d\n",((sendBusy)?"TRUE":"FALSE"), neighbourCount);

		if (sendBusy) return;
	
		sendBusy = TRUE;
	
		//Copia array de vizinhos
//		for(i=0;i<neighbourCount;i++){
//	
//			probeData.destArray[i] = neighbours[i]; 
//	
//			dbg("probeEcho","probe(): Vizinho que deverá tratar o probe: %d\n", probeData.destArray[i]);
//	
//		}

		// Constroi resto da msg
		probeData.messageType	= PROBE_MSG_ID;
		probeData.srcID 		= TOS_NODE_ID;
		probeData.sensorType	= SENSOR;
		probeData.motes			= neighbourCount; 				//Numero de motes que receberão este probe
		probeData.groupID		= groupID;

		// Copia payload para o buffer da mensagem
		memcpy(call GroupSend.getPayload(&sendBuff,call GroupSend.maxPayloadLength()), &probeData, sizeof(cassMsg_t));

		dbg("probeEcho","probeSend.send(): SrcID=%d DestID=AM_BROADCAST_ADDR TOS_NODE_ID=%d Motes=%d Sensor=%d\n", probeData.srcID, TOS_NODE_ID, probeData.motes, probeData.sensorType);
	
		call GroupSend.send(AM_BROADCAST_ADDR, &sendBuff, sizeof(cassMsg_t));
	
	}

	//Task para responder um probe caso o mote já esteja realizando um probe prévio (dummy msg)
	task void alreadyProbing(){
		cassMsg_t 	echoData;
	
		dbg("probeEcho","alreadyProbing(): sendBusy=%s\n",((sendBusy)?"TRUE":"FALSE"));

		if (sendBusy) return;
	
		sendBusy = TRUE;

		// Constroi msg
		echoData.messageType 	= ECHO_MSG_ID;
		echoData.srcID 			= TOS_NODE_ID;
		echoData.destID			= otherProbingMote;
		echoData.value			= 0;
		echoData.motes			= 0;
		echoData.groupID		= groupID;

		// Copia payload para o buffer da mensagem
		memcpy(call GroupSend.getPayload(&sendBuff,call GroupSend.maxPayloadLength()), &echoData, sizeof(cassMsg_t));

		dbg("probeEcho","echoSend.send(): SrcID=%d DestID=%d (dummy msg)\n", echoData.srcID, echoData.destID);
	
		call GroupSend.send(echoData.destID, &sendBuff, sizeof(cassMsg_t));
	
	}
	
	//Task para envio de echoes
	task void echo(){
		cassMsg_t 	echoData;
	
		dbg("probeEcho","echo(): sendBusy=%s\n",((sendBusy)?"TRUE":"FALSE"));

		if (sendBusy) return;
	
		sendBusy = TRUE;

		// Constroi msg
		echoData.messageType	= ECHO_MSG_ID;
		echoData.srcID 			= TOS_NODE_ID;
		echoData.destID			= reqProbeMote;
		echoData.motes			= echoesReceivedCount+1;
		echoData.readValue		= echoSumValue + sensorRead;
		echoData.groupID		= groupID;

		// Copia payload para o buffer da mensagem
		memcpy(call GroupSend.getPayload(&sendBuff,call GroupSend.maxPayloadLength()), &echoData, sizeof(cassMsg_t));

		dbg("probeEcho","echoSend.send(): SrcID=%d DestID=%d Motes=%d Value=%d\n", echoData.srcID, echoData.destID, echoData.motes, echoData.readValue);
	
		// Envia probe com delay baseado no ID do mote
		call GroupSend.send(echoData.destID, &sendBuff, sizeof(cassMsg_t));
	
	}
	
	
	
	/**
	 * Timers
	 */
	event void alreadyProbingSendTimer.fired(){
		post alreadyProbing();
	}
 
	event void probeSendTimer.fired(){
		post probe();
	}
	
	event void probeTimeoutTimer.fired(){
		if(isProbing){
			echoSumValue 		= 0;
			echoCount			= 0;
			echoesReceivedCount = 0;
	
			call probeSendTimer.startOneShot(0);
			call probeTimeoutTimer.startOneShot(PROBE_TIMEOUT);
		}
	}
	
	event void echoSendTimer.fired(){
		post echo();
	}
	
	// Timer para evitar colisão no envio da resposta de discover
	event void discoverSendTimer.fired(){
		cassMsg_t Data;
	
		dbg("probeEcho","discoverSendTimer.fired()\n");

		if (sendBusy){ 
			dbg("probeEcho","discoverSendTimer.fired() sendBusy=TRUE RETURNING!\n");
			return;
		}
	
		sendBusy = TRUE;

		// Constroi msg
		Data.messageType	= DISCOVER_MSG_ID;
		Data.destID			= AM_BROADCAST_ADDR;
		Data.srcID			= TOS_NODE_ID;
		Data.groupID		= groupID;

		// Copia payload para o buffer da mensagem
		memcpy(call GroupSend.getPayload(&sendBuff,call GroupSend.maxPayloadLength()), &Data, sizeof(cassMsg_t));

		dbg("probeEcho","discoverSend.send(): SrcID=%d DestID=AM_BROADCAST_ADDR TOS_NODE_ID=%d\n", Data.srcID, TOS_NODE_ID);
	
		call GroupSend.send(Data.destID, &sendBuff, sizeof(cassMsg_t));
	}	

	/**
	 * Sensors
	 */
 
	//Tratador do evento de leitura do sensor de temperatura
	event void tempSensor.readDone(error_t result, uint16_t val){

		if (result != SUCCESS)	dbg("probeEcho","tempSensor.readDone(): Error=%d\n",result);
	
		dbg("probeEcho","tempSensor.readDone(): Valor lido=%d echoCount=%d neighbourCount=%d\n",val,echoCount, neighbourCount);
	
		sensorRead = val;
	
		//Caso só tenha um vizinho ou todos os echos já chegaram pode retornar o echo
		if (neighbourCount == 1 || echoCount == neighbourCount){
			// Envia echo com delay baseado no ID do mote
			call echoSendTimer.startOneShot(nodeDelay);
		}
	}

	/**
	 * Interface MessageDissemination
	 */
	command bool MessageDissemination.isDisseminationRunning(){
		return isProbing;
	}

	command error_t MessageDissemination.sendMessage(){
		startingNode = TRUE;
		
		return post probe();
	}

	/**
	 * Interface LifeCycle
	 */
	command void LifeCycle.stop(){
		//Finaliza eventual probing em andamento
		isProbing = FALSE;
		
		if(call probeSendTimer.isRunning()){
			call probeSendTimer.stop();
		}		
		if(call alreadyProbingSendTimer.isRunning()){
			call alreadyProbingSendTimer.stop();
		}
		if(call probeTimeoutTimer.isRunning()){
			call probeSendTimer.stop();
		}
		if(call echoSendTimer.isRunning()){
			call echoSendTimer.stop();
		}
	}

	command void LifeCycle.setProperty(uint8_t *option, uint16_t value){
//		if(strcmp(option,"hops") == 0){
//			dbg("lifeCycle", "probeEcho: Set Hops:%u.\n", value);
//			hopsNum = value;
//		}
		
		if(strcmp((char*)option, "groupID") == 0){
			dbg("lifeCycle", "probeEcho: Set GroupID:%u.\n",value);
			groupID = value;
		}
		
		//Deep configuration.
		call RadioLifeCycle.setProperty(option, value);
	}

	command void LifeCycle.init(){
		//Inicializa variáveis
		sendBusy 		= TRUE;
		isProbing 		= FALSE;
		//probeFinalized 	= FALSE;
		neighbourCount 	= 0;
		nodeDelay 		= (TOS_NODE_ID * 15)+50;
		hopsNum 		= HOPS_MAX_NUMBER;
		
		// inicializa estrutura de vizinhos com zero
		memset(neighbours, 0, MAX_NEIGHBOURS);
		
		reqProbeMote 		= 0;
		otherProbingMote 	= 0;
		sensorRead 			= 0;
		echoSumValue 		= 0;
		echoCount			= 0;
		echoesReceivedCount = 0;
		
		// Inicia radio
		call RadioLifeCycle.init();
		
		// Inicia timer com diferentes temporizações baseadas no ID do mote para descoberta de vizinhos
		call discoverSendTimer.startOneShot(nodeDelay);
	
	}

	/**
	 * Eventos de envio e recebimento do GroupRadio
	 */
	event void GroupSend.sendDone(message_t *msg, error_t error){
		cassMsg_t data;
		
		sendBusy = FALSE;
		
		if (error)	{
			dbg("probeEcho","GroupSend.sendDone(): Error=%d\n",error);
			return;
		}
		
		
		memcpy(&data,call GroupSend.getPayload(&sendBuff,call GroupSend.maxPayloadLength()),sizeof(cassMsg_t));
		
		switch(data.messageType){
			case PROBE_MSG_ID:
				isProbing = TRUE;
				
				//Dispara timer para timeout do probe
				call probeTimeoutTimer.startOneShot(PROBE_TIMEOUT);
				break;
		}
	}

	event message_t * GroupReceive.receive(message_t *msg, void *payload, uint8_t len){
		cassMsg_t data;
		int i;
		memcpy(&data,payload,sizeof(cassMsg_t));

		switch(data.messageType)
		{
			case DISCOVER_MSG_ID:
				dbg("probeEcho","discoverReceive.receive(): SrcID=%d DestID=%d TOS_NODE_ID=%d\n", data.srcID, data.destID, TOS_NODE_ID);
	
				// Adiciona node da mensagem como vizinho
				addNeighbour(data.srcID);
				
				break;

			case PROBE_MSG_ID:
				dbg("probeEcho","probeReceive.receive(): SrcID=%d TOS_NODE_ID=%d Motes=%d isAlreadyProbing=%s\n", data.srcID, TOS_NODE_ID, data.motes, (isProbing)?"TRUE":"FALSE");
	
				//Verifica se o mote que recebeu a mensagem é um dos destinatários
//				for(i=0;i<data.motes;i++){
//					if(data.destArray[i] == TOS_NODE_ID){

						//Caso já esteja realizando um probe, responde rapidamente com mensagem vazia
						if(isProbing){
							otherProbingMote = data.srcID;
	
							// Envia probe (dummy) com delay baseado no ID do mote
							call alreadyProbingSendTimer.startOneShot(nodeDelay);
	
							return msg;
						}
						else {
							//Sou um dos destinatários e não estou realizando probes
							reqProbeMote = data.srcID;
	
							//Caso este node tenha outros vizinhos repassa o probe
							if(neighbourCount > 1){
								// Reenvia probe com delay baseado no ID do mote
								call probeSendTimer.startOneShot(nodeDelay);
							}

							call tempSensor.read();
//						}
//					}	
				}
				
				break;
				
				case ECHO_MSG_ID:
					echoSumValue+=data.readValue;
					echoCount++;
		
					if(data.readValue == 0)
						dbg("probeEcho","echoReceive.receive() (Dummy): SrcID=%d DestID=%d TOS_NODE_ID=%d echoCount=%d neighbourCount=%d isAlreadyProbing=%s\n", data.srcID, data.destID, TOS_NODE_ID, echoCount, neighbourCount, (isProbing)?"TRUE":"FALSE");
					else {
						echoesReceivedCount++;
						dbg("probeEcho","echoReceive.receive(): SrcID=%d DestID=%d TOS_NODE_ID=%d echoCount=%d validEchoes=%d neighbourCount=%d isAlreadyProbing=%s\n", data.srcID, data.destID, TOS_NODE_ID, echoCount, echoesReceivedCount, neighbourCount, (isProbing)?"TRUE":"FALSE");
						
						//Sinaliza evento de recebimento de echo valido para o iniciador do probe
						if(startingNode){
							signal MessageDissemination.receiveResponse(&data);
						}
					}
		
					//Caso tenha recebido todos os echoes esperados
					if(isProbing && echoCount == neighbourCount){
						isProbing = FALSE;
							
						// Caso este mote não seja o iniciador do probe, repassa echo (com delay baseado no ID)
						if(!startingNode){
							dbg("probeEcho","echoReceive.receive(): TODOS OS ECHOES RECEBIDOS! Valor total=%d Num. Motes=%d Média=%f echoCount=%d neighbourCount=%d validEchoes=%d\n", echoSumValue, data.motes, (float)((float)echoSumValue/(float)(data.motes+1)), echoCount, neighbourCount, echoesReceivedCount);
							
							call echoSendTimer.startOneShot(nodeDelay);
						}
						else {
							dbg("probeEcho","echoReceive.receive(): Probe/Echo finalizado!\n");
							startingNode = FALSE;
							
							//TODO: está retornando a soma dos valores de leitura
							data.readValue = echoSumValue;
							data.motes = echoesReceivedCount;
							
							signal MessageDissemination.messageDisseminationDone(&data);
						}
		
					}
					
					break;
			}


		return msg;
	}

	/**
	 * Eventos do RadioLifeCycle
	 */
	event void RadioLifeCycle.initDone(error_t error){
		sendBusy = FALSE;
	}

	event void RadioLifeCycle.stopDone(error_t error){
		// TODO Auto-generated method stub
	}
}
