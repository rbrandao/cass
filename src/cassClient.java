import java.io.File;
import java.io.IOException;
import java.net.Socket;
import java.util.Timer;
import java.util.TimerTask;

import net.tinyos.message.*;
import net.tinyos.tools.PrintfMsg;
import net.tinyos.util.*;

public class cassClient implements MessageListener
{
	MoteIF mote;
	Timer Timeout, TPeriodic;
	int reqSeq=0;
	int reqSensor=0;
	int reqServer=0;
	int reqClient=0;
	int msgCount=0;
	boolean waitFlag=false;
	
	
	/* Main entry point */
	void run(int client, int server, int sensor) throws InterruptedException, IOException {
		Socket socket = null;
		String host;
		int port;
		host="localhost";
		port=9002;
		boolean serviceOFF=true;

		TPeriodic = new Timer();
		Timeout = new Timer();

//		System.out.print("Testing the port:");
		while (serviceOFF) {
			try {
				socket = new Socket(host, port);
			} catch (IOException e) {
				System.out.print(".");
				//				e.printStackTrace();
			}
			Thread.sleep(1000);
			if (socket!=null) {
				serviceOFF=false;
				socket.close();
			}
		}
		mote = new MoteIF(PrintStreamMessenger.err);
//		System.out.println("Port connected!");
		mote.registerListener(new cassMsg(), this);
		
		reqSensor = sensor;
		reqClient = client;
		reqServer = server;
		TPeriodic.schedule(new sendRequestTsk(), 0, 2000);
	}

	class sendRequestTsk extends TimerTask {
        public void run() {
        	msgCount++;
        	waitFlag = true;
    		sendRequest(reqClient,reqServer,reqSensor);
    		Timeout.schedule(new TimeOutTsk(), 500);
        }
	}

	class TimeOutTsk extends TimerTask {
        public void run() {
        	if (waitFlag==true)
        	  System.out.println("Timeout msg:" + msgCount);
        }
	}
	
	/**
	 * Received a message from BaseStation
	 */
	synchronized public void messageReceived(int dest_addr, Message msg) {
//		System.out.println("messageReceived:: Type="+ msg.amType() + " size="+msg.dataLength());
//		System.out.println(".");
		// Received a dataBSMsg
		if (msg instanceof cassMsg) {
			cassMsg omsg = (cassMsg)msg;
			waitFlag=false;
			if (omsg.get_ClientID()==reqClient) {
				double a = 0.00130705;
				double b = 0.000214381;
				double c = 0.000000093;
				double R1 = 10000;
				double ADC_FS = 1023;
				double Temp=0;
				double ADC = (double)omsg.get_Value();
				double Rthr = (R1 * (ADC_FS - ADC)) / ADC;
				Temp = (1 / (a + (b * Math.log(Rthr)) + (c * Math.pow(Math.log(Rthr),3.0))))-272.15;
				if (reqSensor==1) { // Temperature
					String Text = "Mote "+ omsg.get_ServerID()+ " Req="+ omsg.get_Seq() + " Temp sensor = " + String.format("%.2f",Temp) + " graus Celsius";
					System.out.println(Text);
				} else { //Photo
					String Text = "Mote "+ omsg.get_ServerID()+  " Req="+ omsg.get_Seq() + " Photo sensor = " + omsg.get_Value();				
					System.out.println(Text);
				}
				
			}
		}			
	
	}
	
	void sendRequest(int client, int server, int sensor){
		cassMsg msg = new cassMsg();
		reqSeq++;

		msg.set_MsgType((short)msg.AM_TYPE);
		msg.set_ClientID(client);
		msg.set_ServerID(server);
		msg.set_Seq(reqSeq);
		msg.set_SensorType((short)sensor);
		try {
			mote.send(server, msg);
		}
		catch (IOException e) {
			System.out.println("request: Can not send message to Base Station");
			e.printStackTrace();
		}
		
	}
	
	public static void main(String[] args) throws InterruptedException, IOException {

		if ((args.length==3) && (Integer.decode(args[0])>0 && Integer.decode(args[1])>0 && (args[2].equals("T")||args[2].equals("P")))) {
			int Sensor = (args[2].equals("T"))?1:2;
			int Client = Integer.decode(args[0]);
			int Server = Integer.decode(args[1]);
			cassClient me = new cassClient();
			me.run(Client,Server,Sensor);
		} else {
			System.out.println("Invalid argument>> java cassClient <client id> <server id> <T|P> ");
		}

	}
}