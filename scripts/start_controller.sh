#!/bin/bash

MODO_BACKGROUND=false

if [[ "$1" == "--background" ]]; then
    MODO_BACKGROUND=true
fi

echo "=== Iniciando Controlador POX con Firewall ==="

echo "Verificando puerto 6653..."
PROCESO=$(sudo lsof -ti :6653)

if [ ! -z "$PROCESO" ]; then
    echo "Encontrado proceso en puerto 6653 (PID: $PROCESO). Terminando..."
    sudo kill -9 $PROCESO
    sleep 2
else
    echo "Puerto 6653 libre."
fi

if [ ! -f "../pox/controlador.py" ]; then
    echo "ERROR: No se encuentra el archivo pox/controlador.py"
    exit 1
fi

if [ ! -f "../pox/pox.py" ]; then
    echo "ERROR: No se encuentra POX en pox/pox.py"
    exit 1
fi

echo "Iniciando POX en ${MODO_BACKGROUND:+segundo plano (background)}${MODO_BACKGROUND:-modo interactivo (foreground)}..."
echo "========================================"

if $MODO_BACKGROUND; then
    python2 ../pox/pox.py forwarding.l2_learning controlador openflow.of_01 --port=6653 > logs/controller.log 2>&1 &
    echo $! > pids_temporales/pox.pid
else
    python2 ../pox/pox.py forwarding.l2_learning controlador openflow.of_01 --port=6653
fi
