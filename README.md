# TP2-Redes: Software-Defined Networks con Firewall

Este proyecto implementa una topología de red parametrizable con un firewall basado en OpenFlow usando Mininet y POX.

## Requisitos

- Python 2

```bash
sudo apt install python2
```

- Mininet

```bash
sudo apt install mininet
```

- iperf para pruebas de rendimiento

```bash
sudo apt install iperf
```

- Wireshark

```bash
sudo apt install wireshark
```

- POX controller (incluido en el proyecto)

## Estructura del Proyecto

```
├── topo.py                        # Definición de topología parametrizable
├── firewall_policies.json     	   # Reglas del firewall
├── pox/
│   ├── controlador.py             # Controlador POX con firewall
│   └── nat.py                     # Controlador POX con NAT
└── scripts/
    ├── firewall_policies.json     # Reglas del firewall de los scripts
    ├── start_controller.sh        # Script para iniciar controlador
    ├── start_mininet.sh           # Script para iniciar Mininet
    ├── demo.sh                    # Demo completa
    ├── run_test.sh                # Script de pruebas automatizadas
    ├── logs/                      # Directorio de logs
    ├── resultados/                # Resultados de pruebas
    └── pids_temporales/           # PIDs de procesos temporales
```

## Scripts para probar las simulaciones

### Opción 1: Demo

```bash
cd scripts
sudo ./demo.sh [num_switches]
```

Esta opción ejecuta una demostración completa que:

- **Inicia el controlador automáticamente** en background con logging
- **Configura la topología** de Mininet con los switches especificados
- **Ejecuta 4 casos de prueba automatizados iperf**:
  1. Bloqueo de puerto 80 - prueba con TCP
  2. Bloqueo UDP 5001 desde h1 - tráfico UDP específico
  3. Bloqueo bidireccional h1-h2 - comunicación entre hosts bloqueados
  4. Comunicación permitida h3-h1 - verifica tráfico normal
- **Genera archivos de resultado** organizados por caso
- **Produce logs detallados** del controlador y Mininet

#### Interpretación de Resultados

- **Conexiones bloqueadas (TCP)**: tcp connect failed: Connection timed out
- **Tráfico UDP bloqueado**: WARNING: did not receive ack of last datagram after 10 tries, ya que iperf aunque mande por UDP cuando finaliza espera un ACK final del servidor.
- **Conexiones exitosas**: Transferencia completa con estadísticas segun el protocolo del lado del servidor
- **Capturas .pcap**: Analizables con Wireshark para ver paquetes bloqueados/permitidos

### Opción 2: Ejecución Manual Paso a Paso

#### 1. Dar permisos a los scripts

```bash
cd scripts
chmod +x *.sh
```

#### 2. Iniciar el Controlador

```bash
./start_controller.sh
```

#### 3. Iniciar Mininet (en otra terminal)

```bash
./start_mininet.sh [cantidad_de_switches]
```

### Opción 3: Comandos Básicos Desde Cero

#### 1. Iniciar el controlador POX

```bash
python2 pox/pox.py forwarding.l2_learning controlador
```

#### 2. Iniciar Mininet (en otra terminal)

```bash
sudo mn --custom topo.py --topo mytopo,<cantidad_de_switches> --mac --arp --switch ovsk --controller remote
```

## Pruebas del Firewall

### Reglas Implementadas

El firewall bloquea:

1. **Puerto 80 (TCP)**: Todo tráfico HTTP
2. **Puerto UDP 5001 desde h1**: Específicamente desde host1 (10.0.0.1)
3. **Comunicación entre hosts específicos**: Bloqueo bidireccional entre h1 y h2 definido en `firewall_policies.json`

#### Configuración de Reglas

Las reglas se definen en `scripts/firewall_policies.json`:

```json
{
	"selected_switch": 1,
	"rules": [
		{
			"dst_port": 80
		},
		{
			"src_ip": "10.0.0.1",
			"dst_port": 5001,
			"protocol": "UDP"
		},
		{
			"src_ip": "10.0.0.1",
			"dst_ip": "10.0.0.2"
		},
		{
			"src_ip": "10.0.0.2",
			"dst_ip": "10.0.0.1"
		}
	]
}
```

### Pruebas Manuales con iperf

#### 1. Abrir terminales de hosts

```bash
mininet> xterm h1 h2 h3 h4
```

#### 2. Probar bloqueo de puerto 80

```bash
# En h4:
iperf -s -p 80

# En h1:
iperf -c <IP_de_h4> -p 80

# Resultado esperado: Conexión rechazada
```

#### 3. Probar bloqueo UDP 5001 desde h1

```bash
# En h3:
iperf -s -u -p 5001

# En h1:
iperf -c <IP_de_h3> -u -p 5001

# Resultado esperado: Bloqueado
```

#### 4. Probar bloqueo entre los dos host elegidos

```bash
# En h1:
iperf -s -p 5002

# En h2:
iperf -c <IP_de_h1> -p 5002

# Resultado esperado: Conexión rechazada
```

#### 5. Probar comunicacion permitida

```bash
# En h1:
iperf -s -p 5002

# En h3:
iperf -c <IP_de_h1> -p 5002

# Resultado esperado: Funciona normal
```

## Análisis con Wireshark

```bash
# En terminal xterm de host:
sudo wireshark &
```

## Configuración del Firewall

Editar `scripts/firewall_policies.json` para modificar las reglas:

- **selected_switch**: Especifica en qué switch aplicar las reglas (1 por defecto)
- **rules**: Array de reglas con los siguientes campos opcionales:
  - `src_ip`: IP de origen
  - `dst_ip`: IP de destino
  - `src_port`: Puerto de origen
  - `dst_port`: Puerto de destino
  - `protocol`: Protocolo ("TCP" o "UDP", si no se especifica aplica a ambos)

## NAT

Primero corremos el controlador Pox:

```bash
python2 pox/pox.py controlador nat
```

Luego levantamos la topologia:

```bash
sudo mn --custom topo.py --topo mytopo,<cantidad_de_switches> --mac --arp --switch ovsk --controller remote
```

Una vez dentro de `mininet` ingresamos los siguientes comandos. Probamos con `h3`:

```bash
mininet> h3 ifconfig h3-eth0:1 192.168.1.100 netmask 255.255.255.0 up

mininet> h3 arp -s 192.168.1.1 00:00:00:00:00:01

mininet> h3 route add -host 192.168.1.1 dev h3-eth0
```
