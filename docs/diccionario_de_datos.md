DICCIONARIO DE DATOS 

Sistema de Monitoreo de Infraestructura y Gestión de Seguridad (Móvil) 

GOATGuard 

 

Revision 1.0 – marzo 2026 

Proyecto Integrador III — Facultad de Ingeniería de Sistemas e Informática, Universidad Pontificia Bolivariana, Seccional Bucaramanga. 

Integrantes: Juan Pablo Carvajal Giraldo, Juan David Monsalve Niño, Johan David Rodríguez Castro. 

Docente: Omar Pinzón Ardila. 

Motor de base de datos: PostgreSQL. 

1. Introducción 

El presente documento describe la estructura de datos del sistema GOATGuard, detallando cada entidad del modelo relacional, sus atributos, tipos de datos, restricciones y relaciones. Este diccionario de datos constituye un artefacto de referencia para las fases de implementación, pruebas y mantenimiento del sistema, asegurando la trazabilidad entre los requerimientos funcionales y el modelo de persistencia. 

El modelo de datos soporta los cuatro módulos del sistema: agentes de captura (registro y heartbeat), backend centralizado (ingesta y procesamiento), motor de análisis (métricas, inventario y alertas) y aplicación móvil (autenticación, consultas y notificaciones push). 

La Revisión 1.1 incorpora tres tablas nuevas — NETWORK_CURRENT_METRICS, DEVICE_CURRENT_METRICS y TOP_TALKER_CURRENT — que implementan el patrón de separación entre estado actual e historial. Estas tablas se actualizan mediante UPSERT en cada ciclo del motor y son la fuente de datos del dashboard en tiempo real (WebSocket). Las tablas históricas existentes no se modifican. 

2. Convenciones 

PK — Primary Key. Identificador único de cada registro. 

FK — Foreign Key. Referencia a la clave primaria de otra tabla. 

Nulo: Sí — El campo acepta valores nulos (dato opcional o no siempre disponible). 

Nulo: No — El campo es obligatorio (NOT NULL). 

NUMERIC(p,s) — Tipo decimal con p dígitos totales y s decimales. 

3. Entidades del Modelo de Datos 

NETWORK 

Representa un segmento de red local monitoreado por el sistema. Permite la futura extensión a múltiples redes. 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

id 

INTEGER 

PK 

No 

Identificador único autoincremental de la red. 

name 

VARCHAR(100) 

— 

No 

Nombre descriptivo asignado a la red (ej: "Red Oficina Principal"). 

subnet 

VARCHAR(45) 

— 

No 

Dirección de subred en notación CIDR (ej: 192.168.1.0/24). 

gateway 

VARCHAR(45) 

— 

No 

Dirección IP del gateway predeterminado de la red. 

created_at 

TIMESTAMP 

— 

No 

Fecha y hora de registro de la red en el sistema. 

Relaciones: 1:N con DEVICE (una red contiene múltiples dispositivos) | 1:N con NETWORK_SNAPSHOT (una red tiene múltiples snapshots) | 1:N con ALERT (una red puede generar múltiples alertas) 

 

DEVICE 

Almacena cada dispositivo descubierto en la red, ya sea por ARP o por registro de agente. Forma el inventario dinámico de activos. 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

id 

INTEGER 

PK 

No 

Identificador único autoincremental del dispositivo. 

network_id 

INTEGER 

FK 

No 

Referencia a la red (NETWORK.id) a la que pertenece. 

ip 

VARCHAR(45) 

— 

No 

Dirección IP actual del dispositivo (soporta IPv4 e IPv6). 

mac 

VARCHAR(17) 

— 

No 

Dirección MAC del dispositivo en formato AA:BB:CC:DD:EE:FF. 

hostname 

VARCHAR(255) 

— 

Sí 

Nombre de host reportado por el dispositivo o resuelto por DNS inverso. 

alias 

VARCHAR(64) 

— 

Sí 

Nombre descriptivo asignado manualmente por el administrador. 

detected_type 

VARCHAR(50) 

— 

Sí 

Tipo inferido automáticamente por fingerprinting (ej: "PC", "IoT", "Impresora"). 

device_type 

VARCHAR(50) 

— 

Sí 

Tipo de dispositivo confirmado o ajustado por el administrador. 

has_agent 

BOOLEAN 

— 

No 

Indica si el dispositivo tiene un agente de captura instalado. 

status 

VARCHAR(20) 

— 

No 

Estado actual: "active", "inactive" o "disconnected". 

first_seen 

TIMESTAMP 

— 

No 

Fecha y hora de la primera detección del dispositivo en la red. 

last_seen 

TIMESTAMP 

— 

No 

Fecha y hora de la última actividad registrada del dispositivo. 

Relaciones: N:1 con NETWORK (pertenece a una red) | 1:1 con AGENT (puede tener un agente asociado) | 1:N con ENDPOINT_SNAPSHOT (genera múltiples snapshots) | 1:N con TOP_TALKER (puede aparecer en rankings) | 1:N con ALERT (puede generar alertas) 

 

AGENT 

Registra cada agente de captura instalado en un endpoint. Controla el estado de conectividad y el heartbeat para determinar actividad. 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

id 

INTEGER 

PK 

No 

Identificador único autoincremental del agente. 

device_id 

INTEGER 

FK 

No 

Referencia al dispositivo (DEVICE.id) donde está instalado. 

uid 

VARCHAR(100) 

— 

No 

Identificador único generado por el agente (hostname + MAC). 

status 

VARCHAR(20) 

— 

No 

Estado del agente: "active" o "inactive". 

last_heartbeat 

TIMESTAMP 

— 

No 

Última señal de vida recibida por el colector. 

registered_at 

TIMESTAMP 

— 

No 

Fecha y hora del primer registro (handshake) del agente. 

Relaciones: N:1 con DEVICE (cada agente pertenece a un dispositivo) 

 

NETWORK_SNAPSHOT 

Captura periódica de las métricas globales de salud de la red en un instante de tiempo. Permite la consulta histórica. 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

id 

INTEGER 

PK 

No 

Identificador único autoincremental del snapshot. 

network_id 

INTEGER 

FK 

No 

Referencia a la red (NETWORK.id) monitoreada. 

timestamp 

TIMESTAMP 

— 

No 

Momento exacto de la captura de métricas. 

isp_latency_avg 

NUMERIC(10,2) 

— 

Sí 

Latencia promedio hacia el exterior (8.8.8.8) en milisegundos. Indicador de salud del ISP. 

packet_loss_pct 

NUMERIC(5,2) 

— 

Sí 

Porcentaje de pérdida de paquetes global. Valores >1% indican problemas de conectividad. 

jitter 

NUMERIC(10,2) 

— 

Sí 

Varianza de latencia en milisegundos. Valores altos indican inestabilidad de la conexión. 

dns_response_time_avg 

NUMERIC(10,2) 

— 

Sí 

Tiempo de respuesta DNS promedio en milisegundos. Valores >100ms indican DNS lento. 

failed_connections_global 

INTEGER 

— 

No 

Total de conexiones fallidas en la red durante la ventana de análisis. 

Relaciones: N:1 con NETWORK (pertenece a una red) | 1:N con TOP_TALKER (cada snapshot contiene un ranking) | 1:N con ENDPOINT_SNAPSHOT (agrupa snapshots de endpoints) 

 

ENDPOINT_SNAPSHOT 

Almacena las métricas específicas de un endpoint individual en un instante dado. Incluye datos de tráfico y de sistema. 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

id 

INTEGER 

PK 

No 

Identificador único autoincremental del snapshot de endpoint. 

device_id 

INTEGER 

FK 

No 

Referencia al dispositivo (DEVICE.id) monitoreado. 

network_snapshot_id 

INTEGER 

FK 

No 

Referencia al snapshot global (NETWORK_SNAPSHOT.id) al que pertenece. 

timestamp 

TIMESTAMP 

— 

No 

Momento exacto de la captura de métricas del endpoint. 

bandwidth_in 

NUMERIC(15,2) 

— 

Sí 

Ancho de banda de entrada en bytes/s, calculado con orig_len. 

bandwidth_out 

NUMERIC(15,2) 

— 

Sí 

Ancho de banda de salida en bytes/s, calculado con orig_len. 

tcp_retransmissions 

INTEGER 

— 

No 

Número de retransmisiones TCP detectadas. Valores altos indican problemas físicos. 

failed_connections 

INTEGER 

— 

No 

Conexiones salientes rechazadas o sin respuesta. 

dns_response_time 

NUMERIC(10,2) 

— 

Sí 

Tiempo de respuesta DNS individual del endpoint en milisegundos. 

jitter 

NUMERIC(10,2) 

— 

Sí 

Varianza de latencia individual del endpoint en milisegundos. 

cpu_pct 

NUMERIC(5,2) 

— 

Sí 

Porcentaje de uso de CPU reportado por el agente vía UDP. 

ram_pct 

NUMERIC(5,2) 

— 

Sí 

Porcentaje de uso de RAM reportado por el agente vía UDP. 

link_speed 

NUMERIC(10,2) 

— 

Sí 

Velocidad del enlace de red del endpoint en Mbps. 

Relaciones: N:1 con DEVICE (pertenece a un dispositivo) | N:1 con NETWORK_SNAPSHOT (forma parte de un snapshot global) 

 

TOP_TALKER 

Ranking de los dispositivos con mayor consumo de ancho de banda en cada ciclo de análisis. 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

id 

INTEGER 

PK 

No 

Identificador único autoincremental del registro. 

network_snapshot_id 

INTEGER 

FK 

No 

Referencia al snapshot global (NETWORK_SNAPSHOT.id). 

device_id 

INTEGER 

FK 

No 

Referencia al dispositivo (DEVICE.id) en el ranking. 

total_consumption 

NUMERIC(15,2) 

— 

No 

Consumo total de ancho de banda (entrada + salida) en bytes. 

rank 

INTEGER 

— 

No 

Posición en el ranking (1 = mayor consumidor). 

is_hog 

BOOLEAN 

— 

No 

Indica si el dispositivo supera el umbral de consumo excesivo. 

Relaciones: N:1 con NETWORK_SNAPSHOT (pertenece a un snapshot global) | N:1 con DEVICE (referencia al dispositivo clasificado) 

 

ALERT 

Registra cada alerta generada por el motor de análisis al detectar patrones de tráfico sospechoso o anomalías. 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

id 

INTEGER 

PK 

No 

Identificador único autoincremental de la alerta. 

device_id 

INTEGER 

FK 

No 

Referencia al dispositivo (DEVICE.id) que originó la alerta. 

network_id 

INTEGER 

FK 

No 

Referencia a la red (NETWORK.id) donde se detectó. 

anomaly_type 

VARCHAR(50) 

— 

No 

Tipo de anomalía: "beaconing", "port_scan", "dga", "bandwidth_spike", etc. 

description 

TEXT 

— 

No 

Descripción detallada del evento anómalo detectado. 

severity 

VARCHAR(20) 

— 

No 

Nivel de severidad: "low", "medium", "high" o "critical". 

seen 

BOOLEAN 

— 

No 

Indica si el administrador ya ha visualizado la alerta. Por defecto: false. 

timestamp 

TIMESTAMP 

— 

No 

Fecha y hora de generación de la alerta. 

Relaciones: N:1 con DEVICE (alerta asociada a un dispositivo) | N:1 con NETWORK (alerta dentro de una red) 

 

USER 

Almacena las credenciales del administrador del sistema. Las contraseñas se persisten con hashing seguro (bcrypt). 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

id 

INTEGER 

PK 

No 

Identificador único autoincremental del usuario. 

username 

VARCHAR(50) 

— 

No 

Nombre de usuario único para la autenticación. 

password_hash 

VARCHAR(255) 

— 

No 

Hash de la contraseña generado con bcrypt. Nunca se almacena en texto plano. 

created_at 

TIMESTAMP 

— 

No 

Fecha y hora de creación de la cuenta. 

Relaciones: 1:N con SESSION (un usuario puede tener múltiples sesiones) | 1:N con PUSH_TOKEN (un usuario puede registrar múltiples dispositivos) 

 

SESSION 

Gestiona las sesiones activas del administrador, almacenando los tokens JWT emitidos y su vigencia. 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

id 

INTEGER 

PK 

No 

Identificador único autoincremental de la sesión. 

user_id 

INTEGER 

FK 

No 

Referencia al usuario (USER.id) propietario de la sesión. 

jwt_token 

TEXT 

— 

No 

Token JWT completo emitido para la sesión. 

mobile_device 

VARCHAR(100) 

— 

Sí 

Identificador del dispositivo móvil desde el que se inició sesión. 

created_at 

TIMESTAMP 

— 

No 

Fecha y hora de creación de la sesión. 

expires_at 

TIMESTAMP 

— 

No 

Fecha y hora de expiración del token JWT. 

Relaciones: N:1 con USER (pertenece a un usuario) 

 

PUSH_TOKEN 

Registra los tokens de notificación push de los dispositivos móviles del administrador para el envío de alertas. 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

id 

INTEGER 

PK 

No 

Identificador único autoincremental del registro. 

user_id 

INTEGER 

FK 

No 

Referencia al usuario (USER.id) propietario del dispositivo. 

token 

VARCHAR(255) 

— 

No 

Token de notificación push. 

platform 

VARCHAR(20) 

— 

No 

Plataforma del dispositivo: "android". 

created_at 

TIMESTAMP 

— 

No 

Fecha y hora de registro del token. 

Relaciones: N:1 con USER (pertenece a un usuario) 

 

NETWORK_CURRENT_METRICS   

Almacena las métricas globales más recientes de cada red. Exactamente una fila por red. Se actualiza mediante UPSERT en cada ciclo del motor de análisis. Tabla nueva — Revisión 1.1. 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

network_id 

INTEGER 

PK / FK 

No 

Referencia a NETWORK.id. Actúa como PK. El UPSERT sobrescribe la fila existente en cada ciclo. 

timestamp 

TIMESTAMP 

— 

No 

Momento de la última actualización por parte del motor de análisis. 

isp_latency_avg 

NUMERIC(10,2) 

— 

Sí 

Latencia promedio actual hacia el exterior en ms. Mismo cálculo que en NETWORK_SNAPSHOT pero sobrescrito en cada ciclo. 

packet_loss_pct 

NUMERIC(5,2) 

— 

Sí 

Porcentaje de pérdida de paquetes global en el último ciclo de análisis. 

jitter 

NUMERIC(10,2) 

— 

Sí 

Varianza de latencia actual en ms. 

dns_response_time_avg 

NUMERIC(10,2) 

— 

Sí 

Tiempo de respuesta DNS promedio actual en ms. 

failed_connections_global 

INTEGER 

— 

No 

Total de conexiones fallidas en la red en el último ciclo de análisis. 

Relaciones: 1:1 con NETWORK (una fila por red). 

 

DEVICE_CURRENT_METRICS  

Almacena las métricas más recientes de cada endpoint individual. Exactamente una fila por dispositivo con agente. Se actualiza mediante UPSERT en cada ciclo del motor. Tabla nueva — Revisión 1.1. 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

device_id 

INTEGER 

PK / FK 

No 

Referencia a DEVICE.id. Actúa como PK. El UPSERT sobrescribe la fila existente en cada ciclo. 

timestamp 

TIMESTAMP 

— 

No 

Momento de la última actualización por parte del motor de análisis. 

bandwidth_in 

NUMERIC(15,2) 

— 

Sí 

Ancho de banda de entrada actual en bytes/s, calculado con orig_len del último lote PCAP procesado. 

bandwidth_out 

NUMERIC(15,2) 

— 

Sí 

Ancho de banda de salida actual en bytes/s, calculado con orig_len. 

tcp_retransmissions 

INTEGER 

— 

No 

Retransmisiones TCP detectadas en el último ciclo de análisis. 

failed_connections 

INTEGER 

— 

No 

Conexiones fallidas en el último ciclo de análisis. 

dns_response_time 

NUMERIC(10,2) 

— 

Sí 

Tiempo de respuesta DNS individual actual en ms. 

jitter 

NUMERIC(10,2) 

— 

Sí 

Varianza de latencia individual actual en ms. 

cpu_pct 

NUMERIC(5,2) 

— 

Sí 

Porcentaje de CPU actual reportado por el agente vía UDP. Se sincroniza con el ciclo del motor. 

ram_pct 

NUMERIC(5,2) 

— 

Sí 

Porcentaje de RAM actual reportado por el agente vía UDP. 

link_speed 

NUMERIC(10,2) 

— 

Sí 

Velocidad del enlace actual en Mbps. 

Relaciones: 1:1 con DEVICE (una fila por dispositivo con agente). 

Nota (Rev. 1.1): Solo los dispositivos con DEVICE.has_agent = true tienen fila en esta tabla. Dispositivos descubiertos únicamente por ARP retornan solo datos de DEVICE al consultar su detalle (RF-046). 

TOP_TALKER_CURRENT   

Almacena el ranking actual de consumidores de ancho de banda. Se reemplaza completamente en cada ciclo con DELETE + INSERT dentro de transacción. Tabla nueva — Revisión 1.1. 

Columna 

Tipo de Dato 

Clave 

Nulo 

Descripción 

id 

INTEGER 

PK 

No 

Identificador autoincremental. Se reasigna en cada ciclo de análisis. 

network_id 

INTEGER 

FK 

No 

Referencia a NETWORK.id. Todas las filas de la red se eliminan y reinsertan en cada ciclo. 

device_id 

INTEGER 

FK 

No 

Referencia al dispositivo (DEVICE.id) en el ranking. 

total_consumption 

NUMERIC(15,2) 

— 

No 

Consumo total de ancho de banda (entrada + salida) en bytes del último ciclo. 

rank 

INTEGER 

— 

No 

Posición en el ranking del ciclo actual (1 = mayor consumidor). 

is_hog 

BOOLEAN 

— 

No 

Indica si el dispositivo supera el umbral de consumo excesivo en este ciclo. 

Relaciones: N:1 con NETWORK | N:1 con DEVICE. 

 

4. Consideraciones Técnicas 

 

Todos los campos de tipo TIMESTAMP almacenan valores en zona horaria UTC para garantizar consistencia entre componentes distribuidos. 

 

Los campos id de cada entidad utilizan secuencias autoincrémentales gestionadas por PostgreSQL (SERIAL o GENERATED ALWAYS AS IDENTITY). 

 

El campo password_hash de la tabla USER almacena hashes generados con bcrypt, cumpliendo el requisito no funcional de seguridad que prohíbe el almacenamiento de contraseñas en texto plano. 

 

Las métricas marcadas como Nullable reflejan datos que dependen de la disponibilidad del agente o de condiciones de red específicas; su ausencia no compromete la integridad del snapshot. 

 

El modelo soporta la administración futura de múltiples redes mediante la entidad NETWORK, aunque el alcance actual se limita a un único segmento LAN, conforme al requisito no funcional de portabilidad. 

 

Las tablas de estado actual (NETWORK_CURRENT_METRICS, DEVICE_CURRENT_METRICS, TOP_TALKER_CURRENT) tienen tamaño fijo en filas y son la fuente de datos exclusiva del dashboard en tiempo real. Reducen la carga de lectura sobre PostgreSQL en aproximadamente un 90 % respecto al esquema anterior de polling REST. 

 

El mecanismo de tiempo real se implementa con PostgreSQL LISTEN/NOTIFY sin infraestructura adicional. El motor ejecuta NOTIFY metrics_updated al terminar cada ciclo; la API (FastAPI) escucha con LISTEN, lee las tablas _current y empuja el payload JSON por WebSocket a la aplicación Flutter. Canal alert_created se usa para alertas. 

 

Índices compuestos recomendados: (1) CREATE INDEX idx_endpoint_snapshot_device_time ON endpoint_snapshot (device_id, timestamp DESC); (2) CREATE INDEX idx_network_snapshot_network_time ON network_snapshot (network_id, timestamp DESC); (3) CREATE INDEX idx_alert_unseen ON alert (seen, timestamp DESC) WHERE seen = false. 

 