#!/bin/bash

echo "=== Iniciando Mininet ==="

MODO_BACKGROUND=false
NUM_SWITCHES=2

# Parsear argumentos
for arg in "$@"; do
    case $arg in
        --background)
            MODO_BACKGROUND=true
            shift
            ;;
        *)
            NUM_SWITCHES=$arg
            ;;
    esac
done

echo "Iniciando topología con $NUM_SWITCHES switches..."

if [ ! -f "../topo.py" ]; then
    echo "ERROR: No se encuentra el archivo topo.py"
    exit 1
fi

echo "Limpiando instancias previas de Mininet..."
sudo mn -c > /dev/null 2>&1 || { echo "ERROR: No se pudo limpiar Mininet"; exit 1; }
echo "Instancias previas limpiadas correctamente."
echo "========================================"

if $MODO_BACKGROUND; then
    setsid sudo python3 run_mininet.py $NUM_SWITCHES > logs/mininet.log 2>&1 < /dev/null &
    echo $! > pids_temporales/mininet.pid
else
    sudo mn --custom ../topo.py --topo mytopo,$NUM_SWITCHES --mac --arp --switch ovsk --controller remote
fi
