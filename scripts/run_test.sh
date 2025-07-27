#!/bin/bash

# Verificar argumentos
if [ "$#" -ne 7 ]; then
    echo "Uso: $0 <número_de_caso> <host_origen> <host_destino> <IP_destino> <puerto> <tcp|udp> <cantidad_de_switches>"
    exit 1
fi

CASO_NUM=$1
ORIGEN=$2
DESTINO=$3
DEST_IP=$4
PUERTO=$5
PROTOCOLO=$6
CANT_SWITCHES=$7

# Validar protocolo
if [[ "$PROTOCOLO" != "tcp" && "$PROTOCOLO" != "udp" ]]; then
    echo "Error: protocolo inválido. Debe ser 'tcp' o 'udp'."
    exit 1
fi

CASO_DIR="resultados/caso$CASO_NUM"

echo "=== Caso $CASO_NUM: $ORIGEN → $DESTINO por ${PROTOCOLO^^}:$PUERTO ==="

if [ -d "$CASO_DIR" ]; then
    echo "[*] Eliminando carpeta existente $CASO_DIR..."
    rm -rf "$CASO_DIR"
fi
mkdir -p "$CASO_DIR"

# Obtener PIDs
ORIGEN_PID=$(cat "pids_temporales/${ORIGEN}.pid")
DESTINO_PID=$(cat "pids_temporales/${DESTINO}.pid")

if [ -z "$ORIGEN_PID" ] || [ -z "$DESTINO_PID" ]; then
    echo "Error: no se encontraron los PIDs de $ORIGEN o $DESTINO"
    exit 1
fi

echo "[*] Iniciando capturas con tcpdump..."
sudo mnexec -a "$ORIGEN_PID" tcpdump -i "${ORIGEN}-eth0" -w "$CASO_DIR/${ORIGEN}.pcapng" > /dev/null 2>&1 &
PID_ORIGEN_CAPTURE=$!

sudo mnexec -a "$DESTINO_PID" tcpdump -i "${DESTINO}-eth0" -w "$CASO_DIR/${DESTINO}.pcapng" > /dev/null 2>&1 &
PID_DESTINO_CAPTURE=$!

sudo tcpdump -i s1-eth1 -w "$CASO_DIR/s1.pcapng" > /dev/null 2>&1 &
PID_S1_CAPTURE=$!

sudo tcpdump -i s${CANT_SWITCHES}-eth1 -w "$CASO_DIR/s${CANT_SWITCHES}.pcapng" > /dev/null 2>&1 &
PID_SMAX_CAPTURE=$!

sleep 2

echo "[*] Iniciando servidor iperf en $DESTINO..."
PROTO_FLAG=""
[[ "$PROTOCOLO" == "udp" ]] && PROTO_FLAG="-u"
sudo mnexec -a "$DESTINO_PID" iperf -s $PROTO_FLAG -p "$PUERTO" > "$CASO_DIR/servidor.log" 2>&1 &
PID_SERV=$!

sleep 2

echo "[*] Ejecutando cliente iperf en $ORIGEN..."
sudo mnexec -a "$ORIGEN_PID" iperf -c "$DEST_IP" -p "$PUERTO" $PROTO_FLAG > "$CASO_DIR/cliente.log" 2>&1

echo "[*] Finalizando capturas..."
kill "$PID_ORIGEN_CAPTURE" "$PID_DESTINO_CAPTURE" "$PID_S1_CAPTURE" "$PID_S5_CAPTURE" "$PID_SERV" 2>/dev/null || true

echo "=== Caso $CASO_NUM completado. Resultados en: $CASO_DIR ==="
