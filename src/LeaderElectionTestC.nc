configuration LeaderElectionTestC{
}
implementation{
	components LeaderElectionTestP;
	components LeaderElectionC;
    components MainC;
    components ActiveMessageC;
    
    LeaderElectionTestP.Boot -> MainC.Boot;
    LeaderElectionTestP.Radio -> ActiveMessageC;
    LeaderElectionTestP.LifeCycle -> LeaderElectionC.LifeCycle;
    LeaderElectionTestP.LeaderElection -> LeaderElectionC.LeaderElection;
}