/**
 * Desenvolvido para a disciplina de Redes de Sensores Sem Fio (INF-2592)
 * ministrada na Pontifícia Universidade Católica pela Prof. Noemi Rodriguez
 *
 * @author Mauricio Rosas
 * @author Rafael Brandão
 * @date  Junho, 2012
 *
 * Wiring do componente que encapsula a eleição de líderes (algoritmo bully)
 * para o projeto final proposto
 */
 
 #include "cass.h"

configuration LeaderElectionC{
	provides interface LeaderElection;
	provides interface LifeCycle;
}

implementation{
	components LeaderElectionP;
	components HopRadioC;
	
	components dummyBSC;
	
	components new TimerMilliC() as startElectionTimer;
	components new TimerMilliC() as sendResponseTimer;
	components new TimerMilliC() as announceVictoryTimer;
	components new TimerMilliC() as waitResponsesTimer;
	components new TimerMilliC() as waitVictoryTimer;

	LeaderElectionP.GroupSend		-> HopRadioC.AMSend;
	LeaderElectionP.GroupReceive	-> HopRadioC.Receive;
	LeaderElectionP.RadioLifeCycle 	-> HopRadioC.LifeCycle;
	
	LeaderElection					= LeaderElectionP.LeaderElection;
	LifeCycle						= LeaderElectionP.LifeCycle;
	
	LeaderElectionP.startElectionTimer		-> startElectionTimer;
	LeaderElectionP.sendResponseTimer		-> sendResponseTimer;
	LeaderElectionP.waitResponsesTimer		-> waitResponsesTimer;
	LeaderElectionP.waitVictoryTimer		-> waitVictoryTimer;
	LeaderElectionP.announceVictoryTimer	-> announceVictoryTimer;
	
}

