#coding: UTF-8
#Programa Python para simulacao de aplicacoes com troca de mensagens

from TOSSIM import *
import sys

t = Tossim([])
r = t.radio()
f = open("topo.txt", "r") #arquivo com a topologia da rede

QtdGeral=0;
TempoPasso = 500.0;     #Intervalo de tempo para cada passo da funcao execTempo()

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
            #throttle.checkThrottle();
            t.runNextEvent();
            #sf.process();
        print "second:%.1f" % ((QtdGeral+qtd)*TempoPasso/1000);
        sys.stdout.flush();
    QtdGeral=QtdGeral+qtd;
    return QtdGeral;

#configura a topologia da rede
lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    print " ", s[0], " ", s[1], " ", s[2];
    r.add(int(s[0]), int(s[1]), float(s[2]))

f = open("log", "w")            #cria um arquivo de log
t.addChannel("probeEcho", f)
t.addChannel("probeEcho", sys.stdout)
t.addChannel("test", sys.stdout)

noise = open("meyer-heavy.txt", "r") #introduz ruido na comunicacao
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(1, 7):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(1, 7):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel()

t.getNode(1).bootAtTime(0);
t.getNode(2).bootAtTime(0);
t.getNode(3).bootAtTime(0);
t.getNode(4).bootAtTime(0);
t.getNode(5).bootAtTime(0);
t.getNode(6).bootAtTime(0);

for i in range(0,900000):
  t.runNextEvent();

#QtdGeral=execTempo(20,QtdGeral);
