configuration dummyBSC{
}
implementation{
	components dummyBSP as BSP;
	components SerialActiveMessageC as Serial;
	BSP.SerialControl -> Serial.SplitControl;
}