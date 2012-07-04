/**
 * Desenvolvido para a disciplina de Redes de Sensores Sem Fio (INF-2592)
 * ministrada na Pontifícia Universidade Católica pela Prof. Noemi Rodriguez
 *
 * @author Mauricio Rosas
 * @author Rafael Brandão
 * @date  Junho, 2012
 *
 * Wiring do componente que encapsula a disseminação de mensagens (algoritmo Probe/Echo)
 * para o projeto final proposto
 */
 
#include "cass.h"

configuration ProbeEchoC{
	provides interface LifeCycle;
	provides interface MessageDissemination;
}

implementation{
	components ProbeEchoP;
	//components ActiveMessageC, MainC, LedsC;
	//components dummyBSC;
	
	//Timers
	components new TimerMilliC() as discoverSendTimer;
	components new TimerMilliC() as probeSendTimer;
	components new TimerMilliC() as echoSendTimer;
	components new TimerMilliC() as alreadyProbingSendTimer;
	components new TimerMilliC() as probeTimeoutTimer;
	
	//Radio
	components GroupRadioC;

	//Sensors
	//components new PhotoTempDeviceC() as Sensor;
	//components new PhotoC() as Sensor;
	components new DemoSensorC() as Sensor;
	
	//ProbeEchoP.Boot -> MainC;
	//ProbeEchoP.Leds -> LedsC;
	
	MessageDissemination	= ProbeEchoP.MessageDissemination;
	LifeCycle				= ProbeEchoP.LifeCycle;
	
	ProbeEchoP.discoverSendTimer 		-> discoverSendTimer;
	ProbeEchoP.probeSendTimer			-> probeSendTimer;
	ProbeEchoP.echoSendTimer 			-> echoSendTimer;
	ProbeEchoP.alreadyProbingSendTimer 	-> alreadyProbingSendTimer;
	ProbeEchoP.probeTimeoutTimer 		-> probeTimeoutTimer;
	
	//ProbeEchoP.RadioControl	-> ActiveMessageC;
	ProbeEchoP.tempSensor	-> Sensor;
	
	ProbeEchoP.GroupSend		-> GroupRadioC.AMSend;
	ProbeEchoP.GroupReceive		-> GroupRadioC.Receive;
	ProbeEchoP.RadioLifeCycle 	-> GroupRadioC.LifeCycle;
}
