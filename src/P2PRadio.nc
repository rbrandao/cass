interface P2PRadio{

	//A implementaćão não utiliza o addr. Mas deixamos porque poderíamos remover 
	// essa interface e deixar as interfaces AMSend, Receive e RootControl.
	command error_t send(am_addr_t addr, message_t* msg, uint8_t len);
	event void sendDone(message_t* msg, error_t error);	
	event message_t* receive(message_t* msg, void* payload, uint8_t len);
	
	command void setRoot();	
	command bool isRoot();
}