# DOCUMENTO DE DISEÑO ARQUITECTÓNICO

**Sistema de Monitoreo de Infraestructura y Gestión de Seguridad (Móvil)**

**GOATGuard**

---

**Revisión 1.0**
Marzo de 2026

---

Juan Pablo Carvajal Giraldo — 000525717
Juan David Monsalve Niño — 000525559
Johan David Rodríguez Castro — 000525537

**Docente:** Omar Pinzón Ardila

**Facultad de Ingeniería de Sistemas e Informática**
Universidad Pontificia Bolivariana — Seccional Bucaramanga

---

## 1. Introducción

### 1.1 Propósito

El presente documento describe la arquitectura de software del sistema GOATGuard, un sistema de monitoreo de infraestructura de red local e inventario de activos con acceso móvil. Su propósito es establecer las decisiones estructurales del sistema, definir los componentes que lo conforman, sus responsabilidades, sus interacciones y los fundamentos técnicos que justifican las elecciones de diseño adoptadas. El documento constituye la referencia arquitectónica durante las fases de implementación, pruebas y despliegue del proyecto.

### 1.2 Alcance

El sistema GOATGuard está compuesto por cuatro componentes principales: (1) agentes de captura desplegados en endpoints de la red, (2) un servidor colector que recibe y almacena los datos capturados, (3) un motor de análisis que procesa el tráfico crudo y genera métricas contextualizadas, y (4) una aplicación móvil que presenta la información al administrador y emite notificaciones ante eventos inusuales.

Este documento describe la arquitectura de los cuatro componentes, sus relaciones, los modelos de datos que los soportan y las decisiones de diseño que rigen su construcción. Quedan fuera del alcance la implementación de la infraestructura de red subyacente, los mecanismos de respuesta automática ante incidentes y la administración activa de los dispositivos conectados.

### 1.3 Definiciones y Acrónimos

| Término / Acrónimo | Definición |
|--------------------|------------|
| API | Application Programming Interface. Interfaz de programación que expone funcionalidades del backend al cliente móvil. |
| ARP | Address Resolution Protocol. Protocolo de capa 2 (OSI) para resolución de direcciones IP a MAC en redes LAN. |
| CI/CD | Continuous Integration / Continuous Delivery. Prácticas de automatización del ciclo de construcción, prueba y despliegue. |
| CIA | Tríada de seguridad: Confidencialidad, Integridad, Disponibilidad (por sus siglas en inglés). |
| C4 | Modelo de documentación arquitectónica en cuatro niveles: Contexto, Contenedores, Componentes y Código. |
| DDA | Documento de Diseño Arquitectónico. El presente documento. |
| ERS | Especificación de Requisitos de Software (IEEE 830). |
| FastAPI | Framework Python para construcción de APIs REST asíncronas con soporte nativo de WebSockets. |
| Flutter | Framework de desarrollo móvil multiplataforma de Google basado en el lenguaje Dart. |
| JWT | JSON Web Token. Estándar para transmisión segura de información de autenticación. |
| LAN | Local Area Network. Red de área local. |
| LISTEN/NOTIFY | Mecanismo de mensajería asíncrona nativo de PostgreSQL para notificaciones entre procesos. |
| PCAP | Packet Capture. Formato estándar de almacenamiento de tráfico de red capturado. |
| PostgreSQL | Sistema gestor de bases de datos relacional de código abierto utilizado como único motor de persistencia del sistema. |
| RF | Requisito Funcional, según la nomenclatura de la ERS asociada. |
| RNF | Requisito No Funcional. |
| Scapy | Librería Python para manipulación y captura de paquetes de red. Utilizada en los agentes de captura de GOATGuard. |
| TLS | Transport Layer Security. Protocolo criptográfico para comunicaciones seguras. |
| Zeek | Motor de análisis de tráfico de red de código abierto que procesa archivos PCAP y genera registros estructurados. |

---

## 2. Stakeholders y Preocupaciones Arquitectónicas

### 2.1 Stakeholders

| Stakeholder | Rol | Interés arquitectónico principal |
|-------------|-----|----------------------------------|
| Administrador de red | Usuario final del sistema | Disponibilidad continua, tiempo de respuesta del dashboard, confiabilidad de alertas. |
| Equipo de desarrollo | Diseño, construcción y despliegue | Claridad de interfaces entre componentes, mantenibilidad, testabilidad y automatización CI/CD. |
| Docente evaluador | Supervisión académica | Cumplimiento del ciclo de vida, trazabilidad entre requisitos y arquitectura, aplicación de buenas prácticas. |
| Endpoints monitoreados | Nodos con agente instalado | Consumo mínimo de recursos (CPU ≤ 5 %, RAM ≤ 100 MB). No degradación del rendimiento del equipo. |

### 2.2 Preocupaciones Arquitectónicas

| Preocupación | Descripción |
|--------------|-------------|
| Seguridad (CIA) | Las comunicaciones entre agentes y colector, y entre la API y la app móvil, deben proteger la confidencialidad e integridad de los datos. El acceso al sistema requiere autenticación JWT con expiración. Las contraseñas se almacenan con hashing bcrypt. |
| Disponibilidad | El colector debe operar 24/7. El agente debe reconectarse automáticamente en menos de 60 segundos ante pérdida de conexión. La API debe responder al 99 % de las peticiones en condiciones normales. |
| Rendimiento | La API debe responder en menos de 2 segundos para consultas simples y 5 segundos para consultas históricas. El motor debe procesar cada lote PCAP antes del siguiente ciclo de rotación. |
| Escalabilidad | La arquitectura soporta al menos 10 agentes simultáneos en el alcance actual, con estructura de datos diseñada para extenderse a múltiples redes en el futuro. |
| Mantenibilidad | Los componentes siguen separación de responsabilidades estricta. El despliegue es reproducible mediante pipelines CI/CD. La configuración del agente es externalizable sin modificar código fuente. |
| Portabilidad | El agente es compatible con Windows 10/11 y distribuciones Linux basadas en Debian/Ubuntu. La app móvil es compatible con Android 10 o superior. |

---

## 3. Drivers Arquitectónicos

### 3.1 Requerimientos Funcionales Clave

Los requisitos funcionales que tienen mayor impacto sobre las decisiones arquitectónicas son los siguientes:

| ID | Nombre | Relevancia arquitectónica |
|----|--------|---------------------------|
| RF-01 | Captura y transmisión de tráfico | Define el canal TCP persistente agente → colector y el formato PCAP con slicing dinámico de payload. |
| RF-02 | Métricas de sistema del endpoint | Establece el canal UDP paralelo independiente para CPU, RAM y velocidad de enlace cada 5 segundos. |
| RF-03 | Descubrimiento ARP | Requiere que el agente ejecute escaneo ARP periódico y transmita el inventario al colector. |
| RF-05 | Recepción dual TCP/UDP | El colector debe gestionar simultáneamente flujos TCP (PCAP) y datagramas UDP (métricas) de múltiples agentes. |
| RF-06 | Rotación de archivos PCAP | El colector rota buffer_actual.pcap cada minuto o 100 MB, garantizando ingesta continua sin interrupciones. |
| RF-07/08 | Análisis PCAP con Zeek | El motor ejecuta Zeek sobre cada lote rotado y extrae métricas de red y de endpoint hacia PostgreSQL. |
| RF-20 | Inventario dinámico de activos | El motor construye y actualiza el inventario combinando ARP, datos de agente y fingerprinting pasivo. |
| RF-30 | Dashboard | La API empuja datos vía WebSocket usando PostgreSQL LISTEN/NOTIFY desde las tablas _current. |
| RF-40 | Alertas y notificaciones push | El motor persiste alertas y la API las entrega a la app móvil vía WebSocket y notificación push. |
| RF-50 | Autenticación JWT | Todos los endpoints de la API (excepto login) requieren token JWT válido. |

### 3.2 Requerimientos No Funcionales

| Atributo | Métrica / Umbral | Impacto en la arquitectura |
|----------|------------------|----------------------------|
| Rendimiento | API < 2 s (simple), < 5 s (histórica) | Justifica la separación entre tablas de estado actual (_current) e históricas, y el uso de índices compuestos en PostgreSQL. |
| Rendimiento — agente | CPU ≤ 5 %, RAM ≤ 100 MB | Motiva el slicing de payload en origen para minimizar el volumen de datos procesados por Scapy y transmitidos al colector. |
| Rendimiento — latencia | Latencia adicional ≤ 50 ms en LAN | Exige que el canal de transmisión TCP opere dentro de la misma red local sin salir a Internet. |
| Disponibilidad | Colector 24/7, API 99 % | Requiere reconexión automática en el agente y gestión de errores robusta en el colector. |
| Seguridad | HTTPS, JWT, bcrypt | La comunicación app con la API usa TLS. Las credenciales se gestionan con hashing. Los tokens tienen expiración definida. |
| Mantenibilidad | CI/CD obligatorio | Pipeline GitHub Actions para backend y app móvil. Configuración del agente externalizable. |
| Portabilidad | Windows 10/11 + Debian/Ubuntu; Android 10+ | El agente usa Scapy (compatible con Windows y Linux). La app usa Flutter (compilación multiplataforma). |

### 3.3 Restricciones

- El sistema opera exclusivamente sobre redes de área local (LAN). No contempla monitoreo de tráfico externo.
- El motor de persistencia es exclusivamente PostgreSQL. No se utiliza InfluxDB ni ningún otro motor de base de datos.
- El agente de captura usa Scapy como librería de captura de paquetes.
- El mecanismo entre el motor y la API se implementa mediante PostgreSQL LISTEN/NOTIFY. No se incorpora infraestructura adicional (Redis, MQTT, Kafka).
- La aplicación móvil está dirigida exclusivamente a Android 10 o superior en el alcance actual del proyecto.
- El despliegue del backend se realiza en infraestructura local o servidor de la red. No se asume disponibilidad de servicios cloud.
- Los agentes se instalan manualmente en cada endpoint. No existe mecanismo de despliegue remoto automatizado de agentes.

---

## 4. Diagrama de Contexto — C4 Nivel 1

> [ Diagrama de Contexto C4 — Nivel 1 — Autoría Propia del equipo ]

---

## 5. Arquitectura de Contenedores / Despliegue — C4 Nivel 2

El sistema GOATGuard se descompone en los siguientes contenedores ejecutables:

| Contenedor | Tecnología | Responsabilidad |
|------------|------------|-----------------|
| Agente de Captura | Python | Captura tráfico del endpoint, lo sanitiza (slicing), lo transmite por TCP al colector, reporta métricas de sistema por UDP. |
| Servidor Colector | Python | Recibe flujos TCP con datos PCAP y datagramas UDP con métricas. Gestiona la rotación de archivos PCAP y persiste métricas de endpoint en PostgreSQL. |
| Motor de Análisis | Python, Zeek | Procesa los lotes PCAP rotados mediante Zeek, extrae métricas de red y de dispositivo, actualiza el inventario de activos, detecta anomalías y genera alertas. |
| API Backend | Python, FastAPI | Expone endpoints REST para consultas desde la app móvil. Gestiona autenticación JWT. Mantiene conexiones WebSocket para push de datos usando PostgreSQL LISTEN/NOTIFY. |
| Base de Datos | PostgreSQL | Motor único de persistencia. Almacena inventario de activos, snapshots históricos de métricas, tablas de estado actual (_current) y registro de alertas. |
| Aplicación Móvil | Flutter / Dart | Presenta el dashboard al administrador. Consume la API REST y el canal WebSocket. Recibe notificaciones push. Permite gestionar alias de dispositivos. |

> [ Diagrama de Contenedores C4 — Nivel 2 — Autoría propia del equipo ]

---

## 6. Componentes del Sistema — C4 Nivel 3

Esta sección descompone internamente cada contenedor en sus módulos o componentes principales.

### 6.1 Agente de Captura

- **Capture Manager:** captura paquetes de red mediante Scapy sobre la interfaz principal. Aplica slicing de payload según puerto de destino (DNS/HTTPS: 300 bytes; resto: 96 bytes). Preserva orig_len.
- **TCP Sender:** establece y mantiene la conexión TCP persistente con el colector. Gestiona reconexión automática ante desconexión.
- **Metrics Collector:** lee CPU, RAM y velocidad de enlace mediante psutil. Empaqueta y envía datagramas UDP al colector cada 5 segundos.
- **ARP Scanner:** ejecuta escaneo ARP periódico sobre el segmento de red y transmite la lista de dispositivos detectados (IP, MAC) al colector.
- **Registration Module:** realiza el handshake inicial con el colector al primer arranque. Genera identificador único (hostname + MAC). Envía heartbeat periódico.
- **Config Loader:** lee parámetros de operación (IP del colector, puertos, intervalos) desde archivo externo de configuración.

### 6.2 Servidor Colector

- **TCP Receiver:** escucha conexiones entrantes de agentes. Escribe los datos recibidos en buffer_actual.pcap de forma continua.
- **UDP Receiver:** escucha datagramas UDP de métricas de sistema. Asocia cada datagrama al endpoint correspondiente por su identificador.
- **PCAP Rotator:** evalúa condiciones de rotación (tiempo ≥ 1 min o tamaño ≥ 100 MB). Renombra el buffer activo con timestamp, cierra el archivo y abre un nuevo buffer.
- **Agent Registry:** gestiona el registro de agentes, heartbeats y actualización de estado de conexión en PostgreSQL.
- **Metrics Persister:** escribe las métricas de endpoint (CPU, RAM, enlace) recibidas por UDP en las tablas correspondientes de PostgreSQL.

### 6.3 Motor de Análisis

- **PCAP Watcher:** monitorea el directorio de lotes rotados. Detecta nuevos archivos y los encola para procesamiento.
- **Zeek Runner:** ejecuta Zeek sobre cada archivo PCAP encolado. Genera los logs estructurados de conexiones, DNS y HTTP.
- **Metrics Extractor:** parsea los logs de Zeek y extrae métricas de red (throughput, packet loss, retransmisiones TCP, DNS response time, jitter).
- **Asset Manager:** construye y actualiza el inventario de activos combinando datos ARP, identificadores de agente y fingerprinting pasivo. Clasifica dispositivos entre monitoreados y sin agente.
- **Anomaly Detector:** evalúa umbrales configurados sobre las métricas extraídas. Genera registros de alerta en PostgreSQL cuando se detectan comportamientos inusuales.
- **Current State Updater:** actualiza las tablas _current (NETWORK_CURRENT_METRICS, DEVICE_CURRENT_METRICS, TOP_TALKER_CURRENT) mediante UPSERT al finalizar cada ciclo. Emite NOTIFY al completar la actualización.

### 6.4 API Backend

- **Auth Controller:** gestiona el endpoint de login, emite tokens JWT con expiración definida y valida tokens en cada petición.
- **Device Controller:** expone endpoints REST para consulta de inventario de activos, detalle de dispositivo y edición de alias.
- **Metrics Controller:** expone endpoints REST para consulta de métricas históricas por dispositivo o red con filtros de rango temporal.
- **Alert Controller:** expone endpoints REST para listado y marcado de alertas como vistas.
- **WebSocket Manager:** mantiene conexiones WSS activas con la app móvil. Escucha el canal LISTEN de PostgreSQL y empuja el payload JSON a todos los clientes conectados al recibir un NOTIFY.
- **Push Notifier:** envía notificaciones push a Firebase Cloud Messaging cuando el motor persiste una nueva alerta.

> [ Diagrama de Componentes C4 — Nivel 3 — Autoría Propia ]

---

## 7. Modelo de Dominio (C4 Nivel 4: Código)

> [ Diagrama de Modelo de Dominio — Autoría Propia ]

---

## 8. Modelo de Datos

El sistema utiliza PostgreSQL como único motor de persistencia. El modelo se organiza en tres grupos funcionales: (1) tablas de inventario y configuración, (2) tablas de series históricas y (3) tablas de estado actual.

> [ Diagrama Entidad-Relación — Autoría Propia ]

---

## 11. Decisiones Arquitectónicas

Las siguientes decisiones de diseño registran las elecciones arquitectónicas significativas, el contexto que las motivó y sus consecuencias.

---

**ID:** ADR-01
**Título:** PostgreSQL como único motor de persistencia
**Estado:** Aprobada

**Contexto:** El sistema requiere almacenar dos tipos de datos: series temporales de métricas de tráfico (alta frecuencia de escritura) e inventario relacional de activos. La opción natural para series temporales habría sido InfluxDB.

**Decisión:** Se adopta PostgreSQL como motor único, sin InfluxDB. Las series temporales se implementan como tablas relacionales con índices compuestos sobre (device_id, timestamp DESC). El patrón _current/history separa el estado actual del histórico, reduciendo la carga de lectura aproximadamente un 90 % frente a polling directo sobre tablas históricas.

**Consecuencias:** Ventaja: una sola tecnología de base de datos simplifica el despliegue, las copias de seguridad y el mantenimiento. Se aprovecha LISTEN/NOTIFY nativo sin infraestructura adicional. Desventaja: para volúmenes muy superiores a los del alcance actual (10 agentes), las tablas de series temporales requerirán particionado o migración a una base de datos especializada.

---

**ID:** ADR-02
**Título:** Canal dual TCP + UDP para comunicación agente-colector
**Estado:** Aprobada

**Contexto:** El agente debe transmitir dos tipos de datos con perfiles muy distintos: flujos PCAP continuos y voluminosos (requieren entrega ordenada y confiable) y métricas ligeras de sistema cada 5 segundos (toleran pérdida ocasional, la latencia importa más que la confiabilidad).

**Decisión:** Se establecen dos canales independientes: (1) TCP persistente para el flujo PCAP, garantizando entrega ordenada; (2) UDP sin conexión para las métricas de sistema, eliminando el overhead de establecimiento de sesión y permitiendo descarte sin bloqueo en caso de congestión.

**Consecuencias:** Ventaja: cada canal usa el protocolo óptimo para su naturaleza de datos. Simplifica el procesamiento en el colector al separar claramente los flujos. Desventaja: el agente debe gestionar dos sockets simultáneos, y el colector dos listeners. Aumenta ligeramente la complejidad del módulo de registro y reconexión.

---

**ID:** ADR-03
**Título:** Zeek como motor de análisis PCAP en el backend
**Estado:** Aprobada

**Contexto:** El motor de análisis necesita extraer métricas estructuradas (conexiones TCP, registros DNS, throughput por flujo) a partir de archivos PCAP rotados. Las alternativas consideradas fueron: parseo manual con Scapy (Python), uso de tshark (Wireshark CLI) y Zeek.

**Decisión:** Se adopta Zeek como motor de análisis. Zeek procesa archivos PCAP y genera logs estructurados en formato JSON o TSV (conn.log, dns.log, http.log) que el motor de análisis parsea directamente para poblar las tablas de PostgreSQL.

**Consecuencias:** Ventaja: Zeek extrae métricas de alto nivel (RTT, retransmisiones, entropía DNS) sin necesidad de implementar parseo de paquetes a bajo nivel. Sus logs están documentados y son predecibles. Desventaja: Zeek es una dependencia externa que debe estar instalada en el servidor backend. Agrega tiempo de instalación al pipeline de despliegue inicial.

---

**ID:** ADR-04
**Título:** Flutter / Dart para la aplicación móvil
**Estado:** Aprobada

**Contexto:** El proyecto requiere una aplicación móvil para Android con soporte a dashboard, WebSocket y notificaciones push. Las alternativas consideradas fueron Flutter y React Native.

**Decisión:** Se adopta Flutter con Dart. La aplicación se desarrolla como una aplicación nativa Android compilada a código ARM. Los paquetes de Flutter para WebSocket (web_socket_channel) y notificaciones push (firebase_messaging) están disponibles y activamente mantenidos.

**Consecuencias:** Ventaja: una única base de código Dart produce el APK Android. El rendimiento de la UI en Flutter es superior a React Native para pantallas con actualizaciones frecuentes (dashboard). Desventaja: el equipo requiere conocimiento de Dart, que tiene menor adopción que JavaScript.

---

**ID:** ADR-05
**Título:** FastAPI como framework del backend REST y WebSocket
**Estado:** Aprobada

**Contexto:** El backend debe exponer una API REST con autenticación JWT y mantener conexiones WebSocket persistentes para el dashboard. Alternativas consideradas: Flask (síncrono) y FastAPI (asíncrono).

**Decisión:** Se adopta FastAPI. Su modelo asíncrono (asyncio) permite gestionar conexiones WebSocket concurrentes sin bloquear los handlers REST. La generación automática de documentación OpenAPI facilita la validación durante el desarrollo.

**Consecuencias:** Ventaja: un solo proceso maneja tanto REST como WebSocket de forma eficiente. La integración con asyncpg (driver PostgreSQL asíncrono) es directa. Desventaja: el modelo asíncrono exige cuidado en el manejo de código bloqueante (operaciones de disco, llamadas síncronas a Zeek), que deben ejecutarse en thread pools separados.

---

**ID:** ADR-06
**Título:** PostgreSQL LISTEN/NOTIFY sin infraestructura adicional
**Estado:** Aprobada

**Contexto:** El dashboard requiere que la API empuje datos a la app móvil tras cada ciclo de análisis. Las alternativas consideradas fueron: polling REST periódico, Redis Pub/Sub, MQTT broker y PostgreSQL LISTEN/NOTIFY.

**Decisión:** Se adopta PostgreSQL LISTEN/NOTIFY. El motor emite NOTIFY metrics_updated (y alert_created para alertas) al completar cada ciclo. La API (FastAPI) escucha con LISTEN mediante asyncpg, lee las tablas _current y empuja el payload por WebSocket a todos los clientes conectados.

**Consecuencias:** Ventaja: elimina la necesidad de desplegar Redis, MQTT u otro broker adicional. La infraestructura de mensajería queda contenida en el mismo motor de base de datos ya utilizado. Desventaja: LISTEN/NOTIFY no persiste mensajes ni garantiza entrega si la API no está escuchando; si la conexión asyncpg se interrumpe, debe re-suscribirse. Aceptable para el alcance del proyecto.

---

**ID:** ADR-07
**Título:** Scapy como librería de captura de paquetes en el agente
**Estado:** Aprobada

**Contexto:** El agente debe capturar tráfico de red en el endpoint desde Python. Las alternativas consideradas fueron: Scapy (librería Python nativa), pyshark (wrapper de tshark) y subprocess con tcpdump.

**Decisión:** Se adopta Scapy. La captura se realiza directamente desde Python sin invocar procesos externos, utilizando la API de sniffing de Scapy con filtros BPF y callback por paquete. El slicing de payload se aplica en el callback antes de transmitir al colector.

**Consecuencias:** Ventaja: integración nativa con Python sin gestión de subprocesos. El slicing y la preservación de orig_len se implementan directamente en el callback. Compatible con Windows y Linux desde el mismo código fuente. Desventaja: mayor overhead de CPU por paquete respecto a tcpdump, dado que cada paquete pasa por el intérprete Python. Aceptable para el alcance del proyecto.

---

**ID:** ADR-08
**Título:** Reverse Tunnel como mecanismo de conectividad remota app móvil con el servidor
**Estado:** Aprobada

**Contexto:** El servidor GOATGuard debe residir dentro de la red que monitorea, ya que los agentes transmiten tráfico y métricas mediante TCP y UDP dentro del segmento local. Sin embargo, el objetivo del sistema exige que el administrador pueda acceder desde cualquier ubicación física. La mayoría de redes domésticas y de pequeña empresa en Colombia operan bajo NAT o CGNAT, lo que impide conexiones entrantes directas al servidor desde redes externas. Las alternativas consideradas fueron: port forwarding en el router, VPN con WireGuard sobre VPS propio, ngrok y despliegue de la API en la nube.

**Decisión:** Se adopta Cloudflare Tunnel (cloudflared). El daemon cloudflared se ejecuta en el servidor GOATGuard y establece una conexión saliente persistente hacia la red de Cloudflare mediante QUIC/TLS. Cloudflare actúa como intermediario público donde la app móvil se comunica con un subdominio permanente (HTTPS/WSS) y Cloudflare reenvía las peticiones al servidor a través del túnel ya establecido. El móvil nunca se conecta directamente a la IP privada del servidor.

**Consecuencias:** Ventajas: resuelve NAT y CGNAT sin configuración en el router ni puertos abiertos. El servicio es gratuito para dominios gestionados por Cloudflare. Soporta WebSocket nativamente, requerido para el dashboard. Provee TLS automático sin gestión manual de certificados. El código de la app no cambia entre entornos, solo la URL base. Desventajas: introduce una dependencia de disponibilidad del servicio de Cloudflare. Agrega latencia adicional de 10-30 ms por el salto al PoP de Cloudflare. El túnel no reemplaza la autenticación JWT de la API, que sigue siendo obligatoria en todas las peticiones.
