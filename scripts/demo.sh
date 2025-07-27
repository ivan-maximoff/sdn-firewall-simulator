#!/bin/bash
chmod +x *.sh
mkdir -p pids_temporales resultados logs

echo "=== Iniciando Demo ==="

NUM_SWITCHES=${1:-2}

echo ""
echo "=== PASO 1: Iniciando controlador POX ==="
./start_controller.sh --background

echo ""
echo "Esperando que el controlador esté listo..."
sleep 2

# Verificar que el controlador se inició correctamente
if sudo lsof -i :6653 >/dev/null 2>&1; then
    echo "Controlador listo en puerto 6653"
else
    echo "Error: Controlador no se pudo iniciar"
    echo "Ver logs: cat logs/controller.log"
    exit 1
fi

echo ""
echo "=== PASO 2: Iniciando mininet ==="
./start_mininet.sh $NUM_SWITCHES --background

sleep 2

echo ""
echo "=== PASO 3: Ejecutando Casos de Prueba ==="
# Caso 1: Bloqueo por puerto destino 80
# h1 → h4 por TCP puerto 80
setsid ./run_test.sh 1 h1 h4 10.0.0.4 80 tcp $NUM_SWITCHES

# Caso 2: Bloqueo por combinación IP origen + puerto destino + protocolo UDP
# h1 → h3 por UDP puerto 5001
setsid ./run_test.sh 2 h1 h3 10.0.0.3 5001 udp $NUM_SWITCHES

# Caso 3: Bloqueo por combinación IP origen y destino
# h1 → h2 por TCP puerto 5002
setsid ./run_test.sh 3 h1 h2 10.0.0.2 5002 tcp $NUM_SWITCHES

# Caso 4: Comunicación permitida
# h3 → h1 por TCP puerto 5002
setsid ./run_test.sh 4 h3 h1 10.0.0.1 5002 tcp $NUM_SWITCHES


echo ""
echo "=== Limpieza ==="

if [ -f pids_temporales/mininet.pid ]; then
    MININET_PID=$(cat pids_temporales/mininet.pid)
    echo "Matando Mininet (PID $MININET_PID)..."
    kill $MININET_PID 2>/dev/null
    sleep 2
    rm -r pids_temporales/mininet.pid
    rm -r pids_temporales/h1.pid
    rm -r pids_temporales/h2.pid
    rm -r pids_temporales/h3.pid
    rm -r pids_temporales/h4.pid
else
    echo "No se encontró PID de Mininet."
fi

if [ -f pids_temporales/pox.pid ]; then
    CONTROLLER_PID=$(cat pids_temporales/pox.pid)
    echo "Matando controlador POX (PID $CONTROLLER_PID)..."
    kill $CONTROLLER_PID 2>/dev/null
    rm -f pids_temporales/pox.pid
else
    echo "No se encontró archivo pox.pid. Controlador ya finalizado o no se registró."
fi

echo ""
echo "Demo terminada."
echo "En la carpeta 'resultados' se guardan los casos de prueba con sus capturas y logs."
echo "Logs de mininet guardados en: logs/mininet.log"
echo "Logs del controlador guardados en: logs/controller.log"