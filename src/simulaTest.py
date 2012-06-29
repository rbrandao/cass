#coding: UTF-8
#Programa Python para simulacao de aplicacoes com troca de mensagens

from TOSSIM import *
import sys

t = Tossim([])
r = t.radio()
f = open("topoTest.txt", "r") #arquivo com a topologia da rede

#configura a topologia da rede
lines = f.readlines()	
for line in lines:
  s = line.split()
  if (len(s) > 0):
    print " ", s[0], " ", s[1], " ", s[2];
    r.add(int(s[0]), int(s[1]), float(s[2]))

t.addChannel("Test", sys.stdout)
t.addChannel("group", sys.stdout)
t.addChannel("lifeCycle", sys.stdout)
t.addChannel("hops", sys.stdout)

noise = open("meyer-heavy.txt", "r") #introduz ruido na comunicacao
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(1, 6):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(1, 6):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel()

for i in range(1,6):
  t.getNode(i).bootAtTime(1000 + (i * 10));

for i in range(0, 10000):
  t.runNextEvent()

