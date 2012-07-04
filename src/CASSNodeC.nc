/**
 * Desenvolvido para a disciplina de Redes de Sensores Sem Fio (INF-2592)
 * ministrada na Pontifícia Universidade Católica pela Prof. Noemi Rodriguez
 *
 * @author Mauricio Rosas
 * @author Rafael Brandão
 * @date  Junho, 2012
 *
 * Wiring do componente que encapsula os nós da infraestrutura CASS
 * para o projeto final proposto
 */
 
 #include "cass.h"

configuration CASSNodeC{
}

implementation{
	components CASSNodeP;
	components P2PRadioC;
	components PEC;
	components LeaderElectionC;
	components MainC;
	components ActiveMessageC;
	components BaseStationC;

	components new AMSenderC(1);
	
	CASSNodeP.Radio				-> P2PRadioC.P2PRadio;
	CASSNodeP.RadioLifeCycle	-> P2PRadioC.LifeCycle;
	
	CASSNodeP.Packet 			-> AMSenderC.Packet;
	CASSNodeP.Dummy 			-> AMSenderC.AMSend; //Necessário para a interface Packet funcionar.

	CASSNodeP.Boot				-> MainC;
	CASSNodeP.BSBoot			<- BaseStationC.Boot;
	CASSNodeP.RadioBoot			-> ActiveMessageC.SplitControl;
	
	CASSNodeP.MessageDissemination			-> PEC.ProbeEcho;
	CASSNodeP.MessageDisseminationLifeCycle	-> PEC.LifeCycle;

	CASSNodeP.LeaderElection			-> LeaderElectionC.LeaderElection;
	CASSNodeP.LeaderElectionLifeCycle	-> LeaderElectionC.LifeCycle;
	
	//CASSNodeP.BSReceive	-> BaseStationC.Receive;
	//CASSNodeP.BSSend	-> BaseStationC.AMSend;		
}

