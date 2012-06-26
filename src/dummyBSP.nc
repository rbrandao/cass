module dummyBSP{
	uses interface SplitControl as SerialControl;
}
implementation{

	event void SerialControl.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void SerialControl.startDone(error_t error){
		// TODO Auto-generated method stub
	}
}