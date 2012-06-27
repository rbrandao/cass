interface LifeCycle{
	command void init();
	event void initDone(error_t error);

	command void stop();
	event void stopDone(error_t error);


	command void addOption(uint8_t * option, uint16_t value);	
}