/**
 * Desenvolvido para a disciplina de Redes de Sensores Sem Fio (INF-2592)
 * ministrada na Pontifícia Universidade Católica pela Prof. Noemi Rodriguez
 *
 * @author Mauricio Rosas
 * @author Rafael Brandão
 * @date  Junho, 2012
 *
 * Implementação do componente que encapsula a eleição de líderes (algoritmo bully)
 * para o projeto final proposto
 */
 
 #include "cass.h"

configuration leaderElectionC{
	provides interface leaderElection;
}

implementation{
	components leaderElectionP;
	components ActiveMessageC;
	components MainC;
	components dummyBSC;
	
	components new TimerMilliC() as startElectionTimer;
	components new TimerMilliC() as sendResponseTimer;
	components new TimerMilliC() as announceVictoryTimer;
	components new TimerMilliC() as waitResponsesTimer;
	components new TimerMilliC() as waitVictoryTimer;
	
	components new AMSenderC(ELECTION_AM_ID) as SendElection;
	components new AMReceiverC(ELECTION_AM_ID) as ReceiveElection;

	components new AMSenderC(RESPONSE_AM_ID) as SendResponse;
	components new AMReceiverC(RESPONSE_AM_ID) as ReceiveResponse;
	
	components new AMSenderC(VICTORY_AM_ID) as SendVictory;
	components new AMReceiverC(VICTORY_AM_ID) as ReceiveVictory;

	leaderElectionP.Boot			-> MainC;
	leaderElectionP.Radio			-> ActiveMessageC;
	
	leaderElectionP.startElectionTimer		-> startElectionTimer;
	leaderElectionP.sendResponseTimer		-> sendResponseTimer;
	leaderElectionP.waitResponsesTimer		-> waitResponsesTimer;
	leaderElectionP.waitVictoryTimer		-> waitVictoryTimer;
	leaderElectionP.announceVictoryTimer	-> announceVictoryTimer;
	
	leaderElectionP.SendElection	-> SendElection;
	leaderElectionP.ReceiveElection	-> ReceiveElection;
	
	leaderElectionP.SendResponse	-> SendResponse;
	leaderElectionP.ReceiveResponse	-> ReceiveResponse;
	
	leaderElectionP.SendVictory		-> SendVictory;
	leaderElectionP.ReceiveVictory	-> ReceiveVictory;
	
	leaderElection					= leaderElectionP.leaderElection;

}

