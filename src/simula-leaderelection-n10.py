#!/usr/bin/python

import sys
from TOSSIM import *

# Criacao dos componentes basicos do TOSSIM
t = Tossim([])
m = t.mac()
r = t.radio()

sfFlag=True;
liveFlag= True;

# Inicializacao do SerialForwader na porta 9002
try:
	sf = SerialForwarder(9002)
except NameError:
	sfFlag=False;
    	print "Executando sem o SerialForward!"

# Definicao do "passo" do "tempo real"
if (sfFlag and liveFlag):
	throttle = Throttle(t, 10)

# Alguns canais dos componentes de comunicacao do TinyOS
#t.addChannel("AM", sys.stdout);
#t.addChannel("Acks", sys.stdout);
#t.addChannel("Packet", sys.stdout);
#t.addChannel("Serial", sys.stdout);

# Colocar aqui os canais da sua aplicacao
#t.addChannel("Metrics", sys.stdout)
t.addChannel("leaderElection", sys.stdout)
t.addChannel("groupRadio", sys.stdout)
t.addChannel("hopRadio", sys.stdout)
t.addChannel("lifeCycle", sys.stdout)

# Global vars - nao os valores aqui!
Motes=10
Group = list();
QtdGeral=0;
BS_ID=0;
ROOT_MOTE=0;
MoteInic=0;
TempoPasso = 500.0;     # step time duration for log


#--------------------------------------------
#configura a topologia da rede

def constroiTopo():
	Gain=85.5;
	print "Building topology: n=10 dense";

	topo = open("topo-n10-denso.txt", "w") #replica topologia em arquivo

	for i in range(1,Motes-3,4):
		#nodes n1 -> n2,n3,n4
		r.add(i, i+1, Gain)
		topo.write("{n1}  {n2}  {gain}\n".format(n1=i,n2=i+1,gain=Gain))
		r.add(i, i+2, Gain)
		topo.write("{n1}  {n2}  {gain}\n".format(n1=i,n2=i+2,gain=Gain))
		r.add(i, i+3, Gain)
		topo.write("{n1}  {n2}  {gain}\n".format(n1=i,n2=i+3,gain=Gain))

		#nodes n2,n3,n4 -> n1
		r.add(i+1, i, Gain)
		topo.write("{n1}  {n2}  {gain}\n".format(n1=i+1,n2=i,gain=Gain))
		r.add(i+2, i, Gain)
		topo.write("{n1}  {n2}  {gain}\n".format(n1=i+2,n2=i,gain=Gain))
		r.add(i+3, i, Gain)
		topo.write("{n1}  {n2}  {gain}\n".format(n1=i+3,n2=i,gain=Gain))

		#nodes n2->n3
		r.add(i+1, i+2, Gain)
		topo.write("{n1}  {n2}  {gain}\n".format(n1=i+1,n2=i+2,gain=Gain))
		#nodes n3->n2
		r.add(i+2, i+1, Gain)
		topo.write("{n1}  {n2}  {gain}\n".format(n1=i+2,n2=i+1,gain=Gain))
		#nodes n3->n4
		r.add(i+2, i+3, Gain)
		topo.write("{n1}  {n2}  {gain}\n".format(n1=i+2,n2=i+3,gain=Gain))
		#nodes n4->n3
		r.add(i+3, i+2, Gain)
		topo.write("{n1}  {n2}  {gain}\n".format(n1=i+3,n2=i+2,gain=Gain))
		if (i-3 > 0):
			#nodes n5->n2,n3,n4
			r.add(i, i-3, Gain)
			topo.write("{n1}  {n2}  {gain}\n".format(n1=i,n2=i-3,gain=Gain))
			r.add(i, i-2, Gain)
			topo.write("{n1}  {n2}  {gain}\n".format(n1=i,n2=i-2,gain=Gain))
			r.add(i, i-1, Gain)
			topo.write("{n1}  {n2}  {gain}\n".format(n1=i,n2=i-1,gain=Gain))
			#nodes n2,n3,n4 -> n5
			r.add(i-3, i, Gain)
			topo.write("{n1}  {n2}  {gain}\n".format(n1=i-3,n2=i,gain=Gain))
			r.add(i-2, i, Gain)
			topo.write("{n1}  {n2}  {gain}\n".format(n1=i-2,n2=i,gain=Gain))
			r.add(i-1, i, Gain)
			topo.write("{n1}  {n2}  {gain}\n".format(n1=i-1,n2=i,gain=Gain))

	#node 9
	r.add(6, 9, Gain)
	topo.write("6  9  {gain}\n".format(gain=Gain))
	r.add(9, 6, Gain)
	topo.write("9  6  {gain}\n".format(gain=Gain))
	r.add(7, 9, Gain)
	topo.write("7  9  {gain}\n".format(gain=Gain))
	r.add(9, 7, Gain)
	topo.write("9  7  {gain}\n".format(gain=Gain))

	#node 10
	r.add(7, 10, Gain)
	topo.write("7  10  {gain}\n".format(gain=Gain))
	r.add(10, 7, Gain)
	topo.write("10  7  {gain}\n".format(gain=Gain))
	r.add(8, 10, Gain)
	topo.write("8  10  {gain}\n".format(gain=Gain))
	r.add(10, 8, Gain)
	topo.write("10  8  {gain}\n".format(gain=Gain))

	#fecha arquivo de topologia
	topo.close()

	noise = open("meyer-heavy.txt", "r") #introduz ruido na comunicacao
	lines = noise.readlines()
	for line in lines:
		str = line.strip()
  		if (str != ""):
			val = int(str)
    			for i in range(1, Motes+1):
				t.getNode(i).addNoiseTraceReading(val)

	for i in range(1, Motes+1):
		print "Creating noise model for ",i;
  		t.getNode(i).createNoiseModel()

#--------------------------------------------
def execPassos(passos):
    """Execute x steps"""
    if (sfFlag and liveFlag):
        throttle.checkThrottle();
    t.runNextEvent();
    if (sfFlag):
        sf.process();
    time = t.time()
    while (time + passos > t.time()):
        t.runNextEvent()


def execTempo(TempoTotal,QtdGeral):
    """Execute a while"""
    Qtd1sec = t.ticksPerSecond()
    TExec=Qtd1sec*TempoPasso/1000;
    Rodadas=TempoTotal*1000/TempoPasso;
    qtd=0.0;
    while (qtd < (Rodadas)):
        qtd=qtd+1;
        time = t.time();
        while (time + TExec > t.time()):
            if (sfFlag and liveFlag):
                throttle.checkThrottle();
            t.runNextEvent();
            if (sfFlag):
                sf.process();
        print "second:%.1f" % ((QtdGeral+qtd)*TempoPasso/1000);
        sys.stdout.flush();
    QtdGeral=QtdGeral+qtd;
    return QtdGeral;

#----------------------------------------------------------
print "******************************************************";
print "*             Inicializacao                          *";
print "******************************************************";
#
# 1. Inicializacoes
# 
# Inicializa o SerialForwarder e o throttle
if (sfFlag):
	sf.process();
if (sfFlag and liveFlag):
	throttle.initialize();

#Define a topologia n=10 esparsa
constroiTopo()

# 
# 2. Test condition
# 
Duration=20
Steps=1000

print "******************************************************";
print "*         Test Condition 1 - N=10 Dense ({Duration}s)".format(Duration=Duration);
print "******************************************************";


metLog = open("metrics-n10-denso.log", "w")            #cria um arquivo de log para o Metrics
t.addChannel("Metrics", metLog)
t.addChannel("AM", metLog);

for i in range(1,Motes+1):
	time=t.time()
	t.getNode(i).bootAtTime(time);
	print "Starting node {id} at time={time}".format(id=i, time=time)

QtdGeral=execTempo(Duration,QtdGeral);

#Remove canais de output
t.removeChannel("AM", metLog);
t.removeChannel("Metrics", metLog);

#Fecha arquivo
metLog.close()

#Desliga nodes
for i in range(1,Motes+1):
	print "Turning off node {id} at time={time}".format(id=i, time=t.time())
	t.getNode(i).turnOff();

print "******************************************************";
print "* Final do Script - N=10 Dense - Total simulation time=",QtdGeral*TempoPasso/1000
print "******************************************************";
#--------------------------------------------------------


