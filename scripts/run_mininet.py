#!/usr/bin/env python3
import os
import sys
import time
import signal
from mininet.net import Mininet
from mininet.node import RemoteController, OVSSwitch
from mininet.link import TCLink
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from topo import MyTopo
from mininet.log import setLogLevel
setLogLevel('info')

pid_dir = "pids_temporales"

# Leer número de switches desde CLI
if len(sys.argv) < 2:
    print("Uso: sudo python3 run_mininet.py <cantidad_switches>")
    sys.exit(1)

num_switches = int(sys.argv[1])

# Inicializar topología
topo = MyTopo(num_switches)
net = Mininet(
    topo=topo,
    switch=OVSSwitch,
    controller=None,
    autoSetMacs=True,
    autoStaticArp=True,
    link=TCLink
)

# Agregar controller remoto (como hacías con --controller remote)
c0 = net.addController('c0', controller=RemoteController, ip='127.0.0.1', port=6653)

# Iniciar red
net.start()

# Guardar PIDs de los hosts
for host in net.hosts:
    nombre = host.name
    pid = host.pid
    with open(os.path.join(pid_dir, f"{nombre}.pid"), "w") as f:
        f.write(str(pid))

# Manejador para detener la red al recibir Ctrl+C o kill
def detener_red(signum, frame):
    net.stop()
    sys.exit(0)

signal.signal(signal.SIGINT, detener_red)
signal.signal(signal.SIGTERM, detener_red)

# Esperar indefinidamente
while True:
    time.sleep(1)
