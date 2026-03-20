# Diagramas de Casos de Uso - GOATGuard

## Proyecto: Sistema de Monitoreo de Trafico de Red Local
## Fecha: 2026-03-03
## Autor: Arquitectura de Software - GOATGuard

---

## Tabla de Contenidos

1. [Identificacion de Actores](#1-identificacion-de-actores)
2. [Identificacion de Casos de Uso Principales](#2-identificacion-de-casos-de-uso-principales)
3. [Diagrama General del Sistema](#3-diagrama-general-del-sistema)
4. [Modulo de Agentes de Captura](#4-modulo-de-agentes-de-captura)
5. [Modulo del Servidor Colector](#5-modulo-del-servidor-colector)
6. [Modulo del Motor de Analisis](#6-modulo-del-motor-de-analisis)
7. [Modulo de la API REST](#7-modulo-de-la-api-rest)
8. [Modulo de la Aplicacion Movil](#8-modulo-de-la-aplicacion-movil)
9. [Subsistema de Autenticacion y Sesion](#9-subsistema-de-autenticacion-y-sesion)
10. [Subsistema de Notificaciones Push](#10-subsistema-de-notificaciones-push)
11. [Matriz de Trazabilidad Actores vs Casos de Uso](#11-matriz-de-trazabilidad-actores-vs-casos-de-uso)

---

## 1. Identificacion de Actores

| Actor | Tipo | Descripcion |
|-------|------|-------------|
| **Administrador de Red** | Primario (Humano) | Usuario principal del sistema. Accede a la aplicacion movil mediante credenciales autenticadas. Posee conocimientos tecnicos en administracion de redes. Consulta metricas, inventario, alertas y gestiona alias de dispositivos. |
| **Agente de Captura** | Sistema (Software) | Componente de software desplegado en cada endpoint. Opera de forma autonoma capturando trafico, recolectando metricas del sistema operativo, descubriendo dispositivos por ARP y transmitiendo datos al colector. |
| **Servidor Colector** | Sistema (Software) | Componente backend que recibe y almacena los flujos de trafico TCP y metricas UDP provenientes de los agentes. Gestiona el registro de agentes, rotacion de buffers PCAP y control de estado de conexiones. |
| **Motor de Analisis** | Sistema (Software) | Componente backend que procesa los archivos PCAP rotados, genera metricas contextualizadas (ancho de banda, Top Talkers, latencia, jitter, retransmisiones TCP, DNS, packet loss), construye el inventario dinamico y detecta patrones de trafico sospechoso. |
| **API REST** | Sistema (Software) | Capa de exposicion que autentica usuarios via JWT, expone endpoints protegidos para consulta de inventario, metricas, alertas y estado de agentes, y gestiona el envio de notificaciones push. |
| **Servicio de Notificaciones Push (FCM/APNs)** | Externo | Servicio de terceros (Firebase Cloud Messaging o APNs) utilizado para entregar notificaciones push al dispositivo movil del administrador cuando se generan alertas de trafico sospechoso. |
| **Sistema Operativo del Endpoint** | Externo | Proveedor de metricas de CPU, RAM y velocidad de enlace de red. Tambien gestiona permisos de captura de paquetes a nivel de red en el endpoint donde opera el agente. |
| **Sistema Operativo Movil (Android)** | Externo | Gestiona los permisos de notificacion push en el dispositivo del administrador y entrega las notificaciones a nivel del OS incluso con la app en segundo plano o cerrada. |

### Diagrama de Actores y sus Relaciones

```plantuml
@startuml actores_sistema
skinparam actorStyle awesome
skinparam packageStyle rectangle
left to right direction

actor "Administrador\nde Red" as Admin #LightBlue
actor "Agente de\nCaptura" as Agente #LightGreen
actor "Servidor\nColector" as Colector #Orange
actor "Motor de\nAnalisis" as Motor #Gold
actor "API REST" as API #Salmon
actor "Servicio Push\n(FCM/APNs)" as Push #LightCoral
actor "SO Endpoint" as SOEndpoint #LightGray
actor "SO Movil\n(Android)" as SOMovil #LightGray

note right of Admin
  Actor primario (humano).
  Interactua con el sistema
  exclusivamente a traves
  de la aplicacion movil.
end note

note right of Agente
  Actor de sistema.
  Opera autonomamente
  en cada endpoint
  monitoreado.
end note

Admin -[hidden]right- API
Agente -[hidden]right- Colector
Colector -[hidden]right- Motor
Motor -[hidden]right- API
API -[hidden]right- Push

@enduml
```

---

## 2. Identificacion de Casos de Uso Principales

Los casos de uso se organizan por modulo del sistema, alineados directamente con los requerimientos funcionales (RF-001 a RF-054).

### Modulo de Agentes de Captura
| ID CU | Nombre | RF Asociados | Prioridad |
|--------|--------|-------------|-----------|
| CU-01 | Capturar trafico de red | RF-001 | Alta |
| CU-02 | Sanitizar paquetes en origen | RF-002 | Alta |
| CU-03 | Transmitir trafico al colector (TCP) | RF-003 | Alta |
| CU-04 | Recolectar metricas de sistema (CPU/RAM) | RF-004, RF-005 | Alta |
| CU-05 | Transmitir metricas de sistema (UDP) | RF-006, RF-007 | Alta |
| CU-06 | Descubrir dispositivos por ARP | RF-008 | Alta |
| CU-07 | Autoregistrarse en el colector | RF-009 | Alta |
| CU-08 | Enviar senal de vida (heartbeat) | RF-010 | Media |

### Modulo del Servidor Colector
| ID CU | Nombre | RF Asociados | Prioridad |
|--------|--------|-------------|-----------|
| CU-09 | Recibir trafico TCP de agentes | RF-011 | Alta |
| CU-10 | Recibir metricas UDP de agentes | RF-012 | Alta |
| CU-11 | Gestionar ingesta en buffer PCAP | RF-013 | Alta |
| CU-12 | Rotar archivos PCAP | RF-014 | Alta |
| CU-13 | Registrar y controlar agentes | RF-015 | Alta |

### Modulo del Motor de Analisis
| ID CU | Nombre | RF Asociados | Prioridad |
|--------|--------|-------------|-----------|
| CU-14 | Procesar archivos PCAP rotados | RF-016 | Alta |
| CU-15 | Condensar y estructurar datos | RF-017 | Alta |
| CU-16 | Persistir metricas en base de datos | RF-018 | Alta |
| CU-17 | Limpiar archivos PCAP procesados | RF-019 | Media |
| CU-18 | Calcular ancho de banda por endpoint | RF-020 | Alta |
| CU-19 | Calcular Top Talkers | RF-021 | Alta |
| CU-20 | Calcular latencia ISP (ISP Health) | RF-022 | Alta |
| CU-21 | Calcular perdida de paquetes global | RF-023 | Alta |
| CU-22 | Calcular retransmisiones TCP | RF-024 | Alta |
| CU-23 | Calcular conexiones fallidas | RF-025 | Alta |
| CU-24 | Calcular DNS Response Time | RF-026 | Media |
| CU-25 | Calcular estabilidad de conexion (Jitter) | RF-027 | Media |
| CU-26 | Construir inventario dinamico de activos | RF-028 | Alta |
| CU-27 | Detectar patrones de trafico sospechoso | RF-029 | Media |

### Modulo de la API REST
| ID CU | Nombre | RF Asociados | Prioridad |
|--------|--------|-------------|-----------|
| CU-28 | Autenticar usuario (Login) | RF-030 | Alta |
| CU-29 | Validar token JWT | RF-031 | Alta |
| CU-30 | Consultar inventario de dispositivos | RF-032 | Alta |
| CU-31 | Consultar detalle de dispositivo | RF-033 | Alta |
| CU-32 | Consultar metricas generales de red | RF-034 | Alta |
| CU-33 | Consultar metricas por endpoint | RF-035 | Alta |
| CU-34 | Consultar alertas | RF-036 | Alta |
| CU-35 | Consultar estado de agentes | RF-037 | Alta |
| CU-36 | Editar alias de dispositivo | RF-038 | Media |
| CU-37 | Enviar notificaciones push | RF-039 | Alta |
| CU-38 | Consultar metricas historicas | RF-040 | Media |

### Modulo de la Aplicacion Movil
| ID CU | Nombre | RF Asociados | Prioridad |
|--------|--------|-------------|-----------|
| CU-39 | Iniciar sesion | RF-041 | Alta |
| CU-40 | Persistir sesion | RF-042 | Media |
| CU-41 | Cerrar sesion | RF-043 | Media |
| CU-42 | Visualizar dashboard general | RF-044 | Alta |
| CU-43 | Visualizar listado de dispositivos | RF-045 | Alta |
| CU-44 | Visualizar detalle de dispositivo | RF-046 | Alta |
| CU-45 | Editar alias de dispositivo | RF-047 | Media |
| CU-46 | Contextualizar dispositivos en segmento | RF-048 | Media |
| CU-47 | Recibir notificaciones push | RF-049 | Alta |
| CU-48 | Visualizar listado de alertas | RF-050 | Alta |
| CU-49 | Visualizar estado de agentes | RF-051 | Alta |
| CU-50 | Visualizar metricas historicas | RF-052 | Media |
| CU-51 | Solicitar permisos de notificacion | RF-053 | Alta |
| CU-52 | Registrar dispositivo para notificaciones | RF-054 | Alta |

---

## 3. Diagrama General del Sistema

Este diagrama presenta una vision de alto nivel de GOATGuard, mostrando los cuatro modulos principales y como los actores interactuan con cada uno. Permite entender el alcance completo del sistema y la separacion de responsabilidades entre componentes.

```plantuml
@startuml diagrama_general
skinparam actorStyle awesome
skinparam packageStyle rectangle
skinparam usecase {
  BackgroundColor<<alta>> #FFDAB9
  BackgroundColor<<media>> #E0E0FF
}
left to right direction

actor "Administrador\nde Red" as Admin #LightBlue
actor "SO Endpoint" as SOE #LightGray
actor "Servicio Push\n(FCM/APNs)" as FCM #LightCoral
actor "SO Movil\n(Android)" as SOA #LightGray

rectangle "GOATGuard - Sistema de Monitoreo de Trafico de Red" {

  package "Agentes de Captura\n(Endpoints)" as PKG_AGENT #PaleGreen {
    usecase "Capturar y sanitizar\ntrafico de red" as UC_CAP <<alta>>
    usecase "Recolectar y transmitir\nmetricas de sistema" as UC_MET <<alta>>
    usecase "Descubrir dispositivos\npor ARP" as UC_ARP <<alta>>
    usecase "Autoregistro y\nheartbeat" as UC_REG <<alta>>
  }

  package "Backend Centralizado" as PKG_BACK #Wheat {

    package "Servidor Colector" as PKG_COL #NavajoWhite {
      usecase "Recibir y almacenar\ndatos de trafico y metricas" as UC_RECV <<alta>>
      usecase "Gestionar buffer PCAP\ny rotacion" as UC_BUF <<alta>>
      usecase "Controlar registro\nde agentes" as UC_CTRL <<alta>>
    }

    package "Motor de Analisis" as PKG_MOT #Khaki {
      usecase "Procesar PCAP y\ngenerar metricas" as UC_PROC <<alta>>
      usecase "Construir inventario\ndinamico" as UC_INV <<alta>>
      usecase "Detectar trafico\nsospechoso" as UC_DET <<media>>
    }

    package "API REST" as PKG_API #LightSalmon {
      usecase "Autenticar y\nautorizar acceso" as UC_AUTH <<alta>>
      usecase "Exponer datos de\nmonitoreo" as UC_EXP <<alta>>
      usecase "Gestionar\nnotificaciones push" as UC_PUSH <<alta>>
    }
  }

  package "Aplicacion Movil\n(Android)" as PKG_APP #LightSkyBlue {
    usecase "Gestionar sesion\nde usuario" as UC_SES <<alta>>
    usecase "Consultar dashboard\ny metricas" as UC_DASH <<alta>>
    usecase "Gestionar inventario\ny dispositivos" as UC_GINV <<alta>>
    usecase "Recibir alertas y\nnotificaciones" as UC_ALERT <<alta>>
  }
}

' --- Relaciones del Administrador ---
Admin --> UC_SES
Admin --> UC_DASH
Admin --> UC_GINV
Admin --> UC_ALERT

' --- Relaciones del SO Endpoint ---
SOE --> UC_CAP
SOE --> UC_MET

' --- Relaciones del Servicio Push ---
UC_PUSH --> FCM
FCM --> UC_ALERT

' --- Relaciones del SO Movil ---
SOA --> UC_ALERT

' --- Relaciones internas entre modulos ---
UC_CAP ..> UC_RECV : <<transmite>>
UC_MET ..> UC_RECV : <<transmite>>
UC_ARP ..> UC_RECV : <<transmite>>
UC_REG ..> UC_CTRL : <<registra>>

UC_BUF ..> UC_PROC : <<alimenta>>
UC_CTRL ..> UC_INV : <<informa>>

UC_PROC ..> UC_EXP : <<persiste>>
UC_INV ..> UC_EXP : <<persiste>>
UC_DET ..> UC_PUSH : <<dispara>>

UC_SES ..> UC_AUTH : <<consume>>
UC_DASH ..> UC_EXP : <<consume>>
UC_GINV ..> UC_EXP : <<consume>>

@enduml
```

---

## 4. Modulo de Agentes de Captura

Este diagrama detalla los casos de uso del software agente que se instala en cada endpoint de la red. Muestra el ciclo completo desde la captura de paquetes, su sanitizacion, la recoleccion de metricas del sistema operativo, el descubrimiento de dispositivos vecinos por ARP, y los mecanismos de comunicacion con el colector (TCP para trafico, UDP para metricas). Las relaciones `<<include>>` representan dependencias obligatorias entre pasos del flujo.

```plantuml
@startuml modulo_agentes
skinparam actorStyle awesome
skinparam packageStyle rectangle
skinparam usecase {
  BackgroundColor<<alta>> #FFDAB9
  BackgroundColor<<media>> #E0E0FF
}
left to right direction

actor "SO Endpoint\n(CPU/RAM/NIC)" as SOE #LightGray
actor "Servidor\nColector" as Colector #Orange
actor "Red Local\n(Segmento LAN)" as LAN #LightGray

rectangle "Modulo de Agentes de Captura (Endpoints)" #PaleGreen {

  usecase "CU-01: Capturar trafico\nde red del endpoint" as CU01 <<alta>>
  usecase "CU-02: Sanitizar paquetes\nen origen (slicing dinamico)" as CU02 <<alta>>
  usecase "CU-03: Transmitir trafico\nal colector via TCP" as CU03 <<alta>>
  usecase "CU-04: Recolectar metricas\nde CPU y RAM" as CU04 <<alta>>
  usecase "CU-05: Transmitir metricas\nde sistema via UDP" as CU05 <<alta>>
  usecase "CU-06: Descubrir dispositivos\npor ARP" as CU06 <<alta>>
  usecase "CU-07: Autoregistrarse\nen el colector" as CU07 <<alta>>
  usecase "CU-08: Enviar senal\nde vida (heartbeat)" as CU08 <<media>>

  usecase "Calcular y enviar\nvelocidad de enlace" as CU05b <<media>>
  usecase "Preservar campo\norig_len" as CU02b <<alta>>
  usecase "Reintentar conexion\nante perdida" as CU03b <<alta>>
}

' --- Actores externos ---
SOE --> CU01 : proporciona\ninterfaz de red
SOE --> CU04 : proporciona\nmetricas
SOE --> CU05b : proporciona\nvelocidad NIC

LAN --> CU06 : respuestas\nARP

' --- Actor Colector como receptor ---
CU03 --> Colector : flujo TCP\ncontinuo
CU05 --> Colector : paquetes UDP\ncada 5s
CU06 --> Colector : lista de\ndispositivos
CU07 --> Colector : handshake\ninicial
CU08 --> Colector : heartbeat\nperiodico

' --- Relaciones include (dependencias obligatorias) ---
CU01 ..> CU02 : <<include>>
CU02 ..> CU03 : <<include>>
CU04 ..> CU05 : <<include>>
CU07 ..> CU08 : <<include>>

' --- Relaciones extend (comportamientos opcionales/condicionales) ---
CU05 <.. CU05b : <<extend>>
CU02 <.. CU02b : <<extend>>
CU03 <.. CU03b : <<extend>>\n[conexion perdida]

note bottom of CU01
  **RF-001**: Captura continua
  de todos los paquetes
  (entrantes y salientes)
  en formato PCAP.
end note

note bottom of CU02
  **RF-002**: Slicing dinamico
  segun puerto de destino.
  Preserva headers + orig_len.
end note

note bottom of CU07
  **RF-009**: Identificador unico
  = hostname + MAC.
  Handshake en primera ejecucion.
end note

@enduml
```

### Descripcion de Flujos del Modulo de Agentes

- **CU-01 a CU-03 (Pipeline de Trafico):** El agente captura paquetes de la interfaz de red, los sanitiza aplicando slicing dinamico segun puerto de destino (preservando `orig_len` para calculo real de ancho de banda), y los transmite al colector mediante conexion TCP persistente. Si la conexion se pierde, reintenta automaticamente.

- **CU-04 a CU-05 (Pipeline de Metricas):** Recolecta periodicamente CPU y RAM del SO, empaqueta con timestamp e identificador, e incluye opcionalmente la velocidad de enlace. Transmite por canal UDP separado cada 5 segundos.

- **CU-06 (Descubrimiento ARP):** Ejecuta escaneos ARP periodicos al segmento de red para detectar dispositivos (con o sin agente) y reporta IP+MAC al colector.

- **CU-07 y CU-08 (Ciclo de Vida):** Al primera ejecucion, el agente se autoregistra con un handshake (hostname+MAC). Posteriormente, envia heartbeats periodicos para que el colector conozca su estado.

---

## 5. Modulo del Servidor Colector

Este diagrama modela los casos de uso del servidor colector, el componente que actua como punto central de recepcion de todos los datos generados por los agentes. Gestiona dos canales de comunicacion diferenciados (TCP para trafico pesado, UDP para metricas ligeras), mantiene un buffer PCAP con rotacion automatica, y lleva el control del ciclo de vida de los agentes conectados.

```plantuml
@startuml modulo_colector
skinparam actorStyle awesome
skinparam packageStyle rectangle
skinparam usecase {
  BackgroundColor<<alta>> #FFDAB9
  BackgroundColor<<media>> #E0E0FF
}
left to right direction

actor "Agente de\nCaptura" as Agente #LightGreen
actor "Motor de\nAnalisis" as Motor #Gold

rectangle "Modulo del Servidor Colector" #NavajoWhite {

  usecase "CU-09: Recibir trafico\nTCP de agentes" as CU09 <<alta>>
  usecase "CU-10: Recibir metricas\nUDP de agentes" as CU10 <<alta>>
  usecase "CU-11: Gestionar ingesta\ncontinua en buffer PCAP" as CU11 <<alta>>
  usecase "CU-12: Rotar archivos PCAP\n(tiempo o tamano)" as CU12 <<alta>>
  usecase "CU-13: Registrar y controlar\nestado de agentes" as CU13 <<alta>>

  usecase "Validar identificador\ndel agente" as CU_VAL <<alta>>
  usecase "Marcar agente\ncomo inactivo" as CU_INACT <<media>>
  usecase "Emitir alerta de\ncapacidad de disco" as CU_DISK <<media>>
}

' --- Agente como emisor ---
Agente --> CU09 : flujo TCP\n(PCAP sanitizado)
Agente --> CU10 : paquetes UDP\n(CPU, RAM, enlace)
Agente --> CU13 : handshake +\nheartbeat

' --- Motor como consumidor ---
CU12 --> Motor : archivos PCAP\nrotados
CU10 --> Motor : metricas de\nsistema

' --- Relaciones include ---
CU09 ..> CU11 : <<include>>
CU11 ..> CU12 : <<include>>
CU10 ..> CU_VAL : <<include>>
CU13 ..> CU_VAL : <<include>>

' --- Relaciones extend ---
CU13 <.. CU_INACT : <<extend>>\n[sin heartbeat]
CU11 <.. CU_DISK : <<extend>>\n[disco > umbral]

note bottom of CU12
  **RF-014**: Rotacion cada 60s
  o al alcanzar 100MB.
  Renombra a lote_YYYYMMDD_HHMMSS.pcap
  y crea nuevo buffer vacio.
end note

note right of CU13
  **RF-015**: Mantiene registro
  con estado (activo/inactivo)
  y timestamp de ultima conexion.
end note

note bottom of CU09
  **RF-011**: Acepta conexiones
  simultaneas de multiples
  agentes y escribe en
  buffer_actual.pcap.
end note

@enduml
```

### Descripcion de Flujos del Modulo Colector

- **CU-09 y CU-11 (Ingesta de Trafico):** El colector escucha conexiones TCP simultaneas de todos los agentes activos y escribe los datos PCAP recibidos en `buffer_actual.pcap` de forma continua e ininterrumpida.

- **CU-12 (Rotacion PCAP):** Cada 60 segundos o al alcanzar 100MB, el colector cierra el buffer activo, lo renombra con timestamp (`lote_YYYYMMDD_HHMMSS.pcap`) y abre un nuevo buffer vacio. El archivo rotado queda disponible para el motor de analisis.

- **CU-10 (Recepcion de Metricas):** Recibe paquetes UDP con CPU, RAM y velocidad de enlace, valida el identificador del agente emisor y almacena las metricas asociadas al endpoint correspondiente.

- **CU-13 (Control de Agentes):** Procesa handshakes de registro inicial y heartbeats periodicos. Actualiza el estado de cada agente y marca como inactivos aquellos que dejan de reportar.

---

## 6. Modulo del Motor de Analisis

Este diagrama representa el nucleo analitico del sistema. El motor procesa los archivos PCAP rotados utilizando herramientas especializadas, condensa y correlaciona la informacion de multiples fuentes (trafico, metricas de endpoint, inventario ARP), calcula las metricas contextualizadas de red y persiste los resultados. Incluye la construccion del inventario dinamico y la deteccion de anomalias.

```plantuml
@startuml modulo_motor_analisis
skinparam actorStyle awesome
skinparam packageStyle rectangle
skinparam usecase {
  BackgroundColor<<alta>> #FFDAB9
  BackgroundColor<<media>> #E0E0FF
}
top to bottom direction

actor "Servidor\nColector" as Colector #Orange
actor "Base de\nDatos SQL" as BD #SkyBlue
actor "API REST" as API #Salmon

rectangle "Modulo del Motor de Analisis" #Khaki {

  package "Pipeline de Procesamiento" {
    usecase "CU-14: Procesar archivos\nPCAP rotados" as CU14 <<alta>>
    usecase "CU-15: Condensar y estructurar\ndatos de multiples fuentes" as CU15 <<alta>>
    usecase "CU-16: Persistir metricas\nen base de datos" as CU16 <<alta>>
    usecase "CU-17: Limpiar archivos\nPCAP procesados" as CU17 <<media>>
  }

  package "Calculo de Metricas de Red" {
    usecase "CU-18: Calcular ancho de banda\npor endpoint (orig_len)" as CU18 <<alta>>
    usecase "CU-19: Calcular Top Talkers\n(ranking de consumo)" as CU19 <<alta>>
    usecase "CU-20: Calcular ISP Health\n(latencia promedio)" as CU20 <<alta>>
    usecase "CU-21: Calcular perdida\nde paquetes global" as CU21 <<alta>>
    usecase "CU-22: Calcular retransmisiones\nTCP por endpoint" as CU22 <<alta>>
    usecase "CU-23: Calcular conexiones\nfallidas por endpoint" as CU23 <<alta>>
    usecase "CU-24: Calcular DNS\nResponse Time" as CU24 <<media>>
    usecase "CU-25: Calcular estabilidad\nde conexion (Jitter)" as CU25 <<media>>
  }

  package "Inventario y Deteccion" {
    usecase "CU-26: Construir inventario\ndinamico de activos" as CU26 <<alta>>
    usecase "CU-27: Detectar patrones\nde trafico sospechoso" as CU27 <<media>>
  }
}

' --- Colector alimenta al motor ---
Colector --> CU14 : archivos PCAP\nrotados
Colector --> CU26 : datos ARP +\nregistro agentes

' --- Pipeline de procesamiento ---
CU14 ..> CU15 : <<include>>
CU15 ..> CU16 : <<include>>
CU16 ..> CU17 : <<include>>

' --- Condensacion incluye calculo de metricas ---
CU15 ..> CU18 : <<include>>
CU15 ..> CU19 : <<include>>
CU15 ..> CU20 : <<include>>
CU15 ..> CU21 : <<include>>
CU15 ..> CU22 : <<include>>
CU15 ..> CU23 : <<include>>
CU15 ..> CU24 : <<include>>
CU15 ..> CU25 : <<include>>

' --- Dependencias entre metricas ---
CU18 ..> CU19 : <<include>>

' --- Persistencia y exposicion ---
CU16 --> BD : inserciones\ntransaccionales
CU26 --> BD : inventario\nunificado
CU27 --> BD : alertas\ngeneradas

BD --> API : datos\ndisponibles

' --- Deteccion de anomalias ---
CU15 ..> CU27 : <<include>>

note right of CU18
  **RF-020**: Usa orig_len
  para calcular ancho de
  banda real aunque el
  paquete fue recortado.
end note

note right of CU20
  **RF-022**: Ping a 8.8.8.8
  cada 30s. Si todos >200ms
  indica problema con ISP.
end note

note left of CU27
  **RF-029**: Detecta volumenes
  inusuales, destinos atipicos
  y comportamientos repetitivos.
  Genera alertas con endpoint,
  tipo y timestamp.
end note

note left of CU26
  **RF-028**: Cruza datos ARP
  con agentes registrados.
  Clasifica: "con agente"
  o "sin agente".
end note

@enduml
```

### Descripcion de Flujos del Motor de Analisis

- **CU-14 a CU-17 (Pipeline Principal):** El motor detecta archivos PCAP rotados, los procesa con herramientas de analisis, condensa los outputs heterogeneos correlacionandolos con datos de inventario y metricas, los persiste en SQL transaccionalmente, y finalmente limpia los archivos ya procesados para liberar disco.

- **CU-18 a CU-25 (Metricas Contextualizadas):** Durante la condensacion se calculan 8 metricas clave: ancho de banda real por endpoint (usando `orig_len`), ranking de Top Talkers, latencia ISP (ping a 8.8.8.8 cada 30s), packet loss global (umbral >1%), retransmisiones TCP, conexiones fallidas, DNS Response Time (umbral >100ms) y Jitter (varianza de latencia).

- **CU-26 (Inventario Dinamico):** Unifica dispositivos descubiertos por ARP con agentes registrados, clasificandolos por cobertura de monitoreo. Dispositivos que desaparecen en multiples ciclos se marcan como desconectados.

- **CU-27 (Deteccion de Anomalias):** Analiza datos de trafico procesados en busca de patrones sospechosos y genera alertas persistidas para notificacion posterior.

---

## 7. Modulo de la API REST

Este diagrama modela la capa de exposicion de datos del sistema. La API actua como intermediario entre el motor de analisis/base de datos y la aplicacion movil, protegiendo todos los endpoints mediante autenticacion JWT. Tambien gestiona el envio de notificaciones push a traves de servicios externos.

```plantuml
@startuml modulo_api
skinparam actorStyle awesome
skinparam packageStyle rectangle
skinparam usecase {
  BackgroundColor<<alta>> #FFDAB9
  BackgroundColor<<media>> #E0E0FF
}
left to right direction

actor "Aplicacion\nMovil" as App #LightSkyBlue
actor "Base de\nDatos SQL" as BD #SkyBlue
actor "Servicio Push\n(FCM/APNs)" as FCM #LightCoral

rectangle "Modulo de la API REST" #LightSalmon {

  package "Autenticacion y Autorizacion" {
    usecase "CU-28: Autenticar usuario\n(Login con JWT)" as CU28 <<alta>>
    usecase "CU-29: Validar token JWT\nen cada peticion" as CU29 <<alta>>
  }

  package "Endpoints de Consulta" {
    usecase "CU-30: Consultar inventario\nde dispositivos" as CU30 <<alta>>
    usecase "CU-31: Consultar detalle\nde un dispositivo" as CU31 <<alta>>
    usecase "CU-32: Consultar metricas\ngenerales de la red" as CU32 <<alta>>
    usecase "CU-33: Consultar metricas\npor endpoint" as CU33 <<alta>>
    usecase "CU-34: Consultar alertas\ngeneradas" as CU34 <<alta>>
    usecase "CU-35: Consultar estado\nde agentes" as CU35 <<alta>>
    usecase "CU-38: Consultar metricas\nhistoricas (rango)" as CU38 <<media>>
  }

  package "Endpoints de Escritura" {
    usecase "CU-36: Editar alias\nde dispositivo" as CU36 <<media>>
  }

  package "Notificaciones" {
    usecase "CU-37: Enviar notificaciones\npush ante alertas" as CU37 <<alta>>
  }
}

' --- App como consumidor ---
App --> CU28
App --> CU30
App --> CU31
App --> CU32
App --> CU33
App --> CU34
App --> CU35
App --> CU36
App --> CU38

' --- Validacion JWT en cada endpoint protegido ---
CU30 ..> CU29 : <<include>>
CU31 ..> CU29 : <<include>>
CU32 ..> CU29 : <<include>>
CU33 ..> CU29 : <<include>>
CU34 ..> CU29 : <<include>>
CU35 ..> CU29 : <<include>>
CU36 ..> CU29 : <<include>>
CU38 ..> CU29 : <<include>>

' --- BD como fuente de datos ---
CU28 --> BD : valida\ncredenciales
CU30 --> BD
CU31 --> BD
CU32 --> BD
CU33 --> BD
CU34 --> BD
CU35 --> BD
CU36 --> BD
CU38 --> BD

' --- Servicio Push externo ---
CU37 --> FCM : envio de\nnotificacion

note bottom of CU28
  **RF-030**: Recibe usuario/contrasena,
  valida con hash seguro,
  retorna JWT o error generico.
  Contrasenas NUNCA en texto plano.
end note

note right of CU29
  **RF-031**: Middleware que verifica
  firma, integridad y vigencia
  del token en cada peticion.
  Retorna 401 si invalido.
end note

note bottom of CU37
  **RF-039**: Dispara push al
  dispositivo del admin cuando
  se genera una alerta, incluso
  con app cerrada o en background.
end note

@enduml
```

### Descripcion de Flujos de la API REST

- **CU-28 y CU-29 (Autenticacion):** El endpoint de login valida credenciales contra hashes seguros en BD y genera un JWT con tiempo de expiracion definido. Un middleware intercepta todas las peticiones a endpoints protegidos para verificar firma, integridad y vigencia del token.

- **CU-30 a CU-35, CU-38 (Consultas):** Endpoints GET protegidos que retornan inventario de dispositivos, detalle individual, metricas generales de red (ISP Health, packet loss, Top Talkers, jitter, DNS RT), metricas por endpoint, alertas cronologicas, estado de agentes y metricas historicas filtradas por rango temporal.

- **CU-36 (Escritura):** Endpoint PUT/PATCH protegido que permite asignar o modificar un alias descriptivo a un dispositivo del inventario.

- **CU-37 (Notificaciones Push):** Al detectarse una nueva alerta en BD, la API construye el payload y lo envia al servicio externo (FCM/APNs) para su entrega al dispositivo del administrador.

---

## 8. Modulo de la Aplicacion Movil

Este diagrama detalla todas las interacciones del administrador de red con la aplicacion movil Android. Cubre el ciclo completo de sesion, la consulta de informacion de monitoreo, la gestion de dispositivos y la recepcion de alertas. Es el unico punto de contacto del actor humano con el sistema.

```plantuml
@startuml modulo_app_movil
skinparam actorStyle awesome
skinparam packageStyle rectangle
skinparam usecase {
  BackgroundColor<<alta>> #FFDAB9
  BackgroundColor<<media>> #E0E0FF
}
left to right direction

actor "Administrador\nde Red" as Admin #LightBlue
actor "API REST" as API #Salmon
actor "SO Movil\n(Android)" as SOA #LightGray

rectangle "Modulo de la Aplicacion Movil (Android)" #LightSkyBlue {

  package "Gestion de Sesion" {
    usecase "CU-39: Iniciar sesion\n(pantalla de login)" as CU39 <<alta>>
    usecase "CU-40: Persistir sesion\n(token JWT local)" as CU40 <<media>>
    usecase "CU-41: Cerrar sesion\n(eliminar token)" as CU41 <<media>>
  }

  package "Dashboard y Metricas" {
    usecase "CU-42: Visualizar dashboard\ngeneral de la red" as CU42 <<alta>>
    usecase "CU-49: Visualizar estado\nde agentes (activo/inactivo)" as CU49 <<alta>>
    usecase "CU-50: Visualizar metricas\nhistoricas (graficas)" as CU50 <<media>>
  }

  package "Inventario de Dispositivos" {
    usecase "CU-43: Visualizar listado\nde dispositivos" as CU43 <<alta>>
    usecase "CU-44: Visualizar detalle\nde dispositivo individual" as CU44 <<alta>>
    usecase "CU-45: Editar alias de\ndispositivo" as CU45 <<media>>
    usecase "CU-46: Contextualizar\ndispositivos en segmento" as CU46 <<media>>
  }

  package "Alertas y Notificaciones" {
    usecase "CU-47: Recibir notificaciones\npush del OS" as CU47 <<alta>>
    usecase "CU-48: Visualizar listado\nde alertas" as CU48 <<alta>>
    usecase "CU-51: Solicitar permisos\nde notificacion" as CU51 <<alta>>
    usecase "CU-52: Registrar dispositivo\npara notificaciones" as CU52 <<alta>>
  }
}

' --- Administrador interactua con la app ---
Admin --> CU39
Admin --> CU41
Admin --> CU42
Admin --> CU43
Admin --> CU44
Admin --> CU45
Admin --> CU48
Admin --> CU49
Admin --> CU50

' --- Relaciones include ---
CU39 ..> CU40 : <<include>>
CU43 ..> CU44 : <<extend>>\n[selecciona dispositivo]
CU44 ..> CU45 : <<extend>>\n[modifica alias]
CU43 ..> CU46 : <<extend>>\n[vista por segmento]
CU51 ..> CU52 : <<include>>

' --- API como backend ---
CU39 --> API : POST /auth/login
CU42 --> API : GET /metrics/general
CU43 --> API : GET /devices
CU44 --> API : GET /devices/{id}
CU45 --> API : PATCH /devices/{id}/alias
CU48 --> API : GET /alerts
CU49 --> API : GET /agents/status
CU50 --> API : GET /metrics/history
CU52 --> API : POST /notifications/register

' --- SO Movil ---
SOA --> CU47 : entrega\nnotificacion
CU51 --> SOA : solicita\npermisos

' --- Notificaciones activas despues del registro ---
CU47 ..> CU48 : <<extend>>\n[abre detalle de alerta]

note bottom of CU42
  **RF-044**: Muestra ISP Health,
  Packet Loss, Top Talkers,
  Jitter, DNS RT.
  Actualiza periodicamente.
end note

note right of CU47
  **RF-049**: Funciona con app
  en segundo plano o cerrada.
  Muestra resumen de la alerta
  a nivel del sistema operativo.
end note

note bottom of CU44
  **RF-046**: Dispositivos con agente
  muestran metricas completas.
  Sin agente solo muestra
  IP, MAC y estado ARP.
end note

@enduml
```

### Descripcion de Flujos de la Aplicacion Movil

- **CU-39 a CU-41 (Gestion de Sesion):** El administrador ingresa credenciales en la pantalla de login, la app las envia a la API, almacena el JWT localmente si son validas, y permite cerrar sesion eliminando el token. Al reabrir la app, verifica el token almacenado para evitar re-autenticacion.

- **CU-42, CU-49, CU-50 (Dashboard):** Presenta indicadores de salud de la red (ISP Health, packet loss, Top Talkers, jitter, DNS Response Time), estado visual de agentes (verde/rojo) y graficas historicas con selector de rango temporal.

- **CU-43 a CU-46 (Inventario):** Lista todos los dispositivos diferenciando visualmente con/sin agente, permite ver detalle completo de cada dispositivo, editar su alias, y contextualizar dentro del segmento de red.

- **CU-47, CU-48, CU-51, CU-52 (Alertas):** Solicita permisos de notificacion al SO, registra el token push en el backend, recibe notificaciones a nivel del OS y permite consultar el historial completo de alertas.

---

## 9. Subsistema de Autenticacion y Sesion

Este diagrama transversal modela el flujo completo de autenticacion desde que el administrador ingresa credenciales hasta la validacion del token en cada peticion. Cruza los limites entre la aplicacion movil y la API, mostrando como ambos modulos colaboran para garantizar el acceso seguro.

```plantuml
@startuml subsistema_autenticacion
skinparam actorStyle awesome
skinparam packageStyle rectangle
skinparam usecase {
  BackgroundColor<<alta>> #FFDAB9
  BackgroundColor<<media>> #E0E0FF
}
left to right direction

actor "Administrador\nde Red" as Admin #LightBlue

rectangle "Subsistema de Autenticacion y Sesion" {

  package "Aplicacion Movil" #LightSkyBlue {
    usecase "Ingresar credenciales\nen pantalla de login" as UC_LOGIN <<alta>>
    usecase "Almacenar token JWT\nen storage local" as UC_STORE <<media>>
    usecase "Verificar vigencia\ndel token al abrir app" as UC_CHECK <<media>>
    usecase "Eliminar token\n(cerrar sesion)" as UC_LOGOUT <<media>>
    usecase "Redirigir a login\nsi token expirado" as UC_REDIR <<media>>
  }

  package "API REST" #LightSalmon {
    usecase "Validar credenciales\ncontra hash en BD" as UC_VALID <<alta>>
    usecase "Generar token JWT\ncon expiracion" as UC_GEN <<alta>>
    usecase "Verificar firma,\nintegridad y vigencia" as UC_VERIFY <<alta>>
    usecase "Rechazar peticion\n(HTTP 401)" as UC_REJECT <<alta>>
  }
}

Admin --> UC_LOGIN
Admin --> UC_LOGOUT

UC_LOGIN ..> UC_VALID : <<include>>
UC_VALID ..> UC_GEN : <<include>>\n[credenciales validas]
UC_VALID ..> UC_REJECT : <<extend>>\n[credenciales invalidas]
UC_GEN ..> UC_STORE : <<include>>

UC_CHECK ..> UC_VERIFY : <<include>>
UC_VERIFY ..> UC_REDIR : <<extend>>\n[token expirado/invalido]

UC_LOGOUT ..> UC_REDIR : <<include>>

note bottom of UC_VALID
  Contrasenas almacenadas
  con hashing seguro.
  Error generico ante
  credenciales invalidas
  (no revela si es user
  o password incorrecto).
end note

note right of UC_GEN
  JWT con tiempo de
  expiracion definido.
  Comunicacion sobre HTTPS.
end note

@enduml
```

---

## 10. Subsistema de Notificaciones Push

Este diagrama transversal detalla el flujo de notificaciones push de extremo a extremo. Desde la deteccion de una anomalia por el motor de analisis, pasando por la generacion de la alerta, el envio a traves del servicio externo (FCM/APNs), hasta su recepcion y visualizacion en el dispositivo del administrador. Es un flujo critico para la propuesta de valor del sistema.

```plantuml
@startuml subsistema_notificaciones
skinparam actorStyle awesome
skinparam packageStyle rectangle
skinparam usecase {
  BackgroundColor<<alta>> #FFDAB9
  BackgroundColor<<media>> #E0E0FF
}
left to right direction

actor "Administrador\nde Red" as Admin #LightBlue
actor "SO Movil\n(Android)" as SOA #LightGray
actor "Servicio Push\n(FCM/APNs)" as FCM #LightCoral

rectangle "Subsistema de Notificaciones Push" {

  package "Motor de Analisis" #Khaki {
    usecase "Detectar patron\nde trafico sospechoso" as UC_DETECT <<media>>
    usecase "Generar registro\nde alerta en BD" as UC_ALERT <<alta>>
  }

  package "API REST" #LightSalmon {
    usecase "Construir payload\nde notificacion" as UC_PAYLOAD <<alta>>
    usecase "Enviar notificacion\nal servicio push" as UC_SEND <<alta>>
    usecase "Reintentar envio\nante fallo" as UC_RETRY <<media>>
  }

  package "Aplicacion Movil" #LightSkyBlue {
    usecase "Solicitar permisos\nde notificacion al OS" as UC_PERM <<alta>>
    usecase "Obtener y registrar\ntoken push en backend" as UC_REGTOKEN <<alta>>
    usecase "Recibir y mostrar\nnotificacion del OS" as UC_RECV <<alta>>
    usecase "Navegar al detalle\nde la alerta" as UC_NAV <<media>>
  }
}

' --- Flujo de deteccion a envio ---
UC_DETECT ..> UC_ALERT : <<include>>
UC_ALERT ..> UC_PAYLOAD : <<include>>
UC_PAYLOAD ..> UC_SEND : <<include>>
UC_SEND --> FCM : push\nnotification
UC_SEND <.. UC_RETRY : <<extend>>\n[fallo de envio]

' --- Flujo de registro de dispositivo ---
Admin --> UC_PERM
UC_PERM --> SOA : solicita\npermisos
UC_PERM ..> UC_REGTOKEN : <<include>>\n[permisos concedidos]

' --- Flujo de recepcion ---
FCM --> UC_RECV : entrega\nnotificacion
SOA --> UC_RECV : muestra en\nbandeja del OS
UC_RECV ..> UC_NAV : <<extend>>\n[admin toca notificacion]
UC_NAV --> Admin : visualiza\ndetalle

note bottom of UC_DETECT
  Analiza volumenes inusuales,
  destinos atipicos y patrones
  repetitivos en el trafico
  procesado.
end note

note right of UC_RECV
  Funciona con la app en
  segundo plano o cerrada.
  Muestra tipo de alerta,
  dispositivo y timestamp.
end note

note bottom of UC_PERM
  Si el usuario deniega permisos,
  la app funciona normalmente
  pero sin notificaciones push.
  Las alertas quedan visibles
  dentro de la app.
end note

@enduml
```

---

## 11. Matriz de Trazabilidad Actores vs Casos de Uso

Esta matriz permite verificar que cada actor tiene asignados sus casos de uso correspondientes y que ningun caso de uso queda huerfano sin interaccion.

| Actor | Casos de Uso en los que Participa |
|-------|-----------------------------------|
| **Administrador de Red** | CU-39, CU-40, CU-41, CU-42, CU-43, CU-44, CU-45, CU-46, CU-47, CU-48, CU-49, CU-50, CU-51, CU-52 |
| **Agente de Captura** | CU-01, CU-02, CU-03, CU-04, CU-05, CU-06, CU-07, CU-08 |
| **Servidor Colector** | CU-09, CU-10, CU-11, CU-12, CU-13 |
| **Motor de Analisis** | CU-14, CU-15, CU-16, CU-17, CU-18, CU-19, CU-20, CU-21, CU-22, CU-23, CU-24, CU-25, CU-26, CU-27 |
| **API REST** | CU-28, CU-29, CU-30, CU-31, CU-32, CU-33, CU-34, CU-35, CU-36, CU-37, CU-38 |
| **Servicio Push (FCM/APNs)** | CU-37, CU-47, CU-52 |
| **SO Endpoint** | CU-01, CU-04, CU-05 |
| **SO Movil (Android)** | CU-47, CU-51 |

---

## Notas Arquitectonicas Adicionales

### Separacion de Canales de Comunicacion

El sistema implementa una separacion explicita de canales entre agentes y colector:

- **Canal TCP (pesado):** Transmision de datos PCAP sanitizados. Conexion persistente, entrega ordenada, tolerante a reconexion.
- **Canal UDP (ligero):** Transmision de metricas de sistema (CPU, RAM, velocidad de enlace). Best-effort, intervalos de 5 segundos.

Esta decision arquitectonica evita que el flujo pesado de paquetes interfiera con el reporte periodico de metricas del endpoint.

### Modelo de Seguridad

- Autenticacion JWT con expiracion obligatoria
- Hashing seguro de contrasenas (nunca texto plano)
- HTTPS obligatorio entre app movil y API
- Errores genericos de autenticacion (no revelan existencia de usuario)
- Validacion de token en cada peticion a endpoints protegidos
- Logs de auditoria en colector y motor

### Consideraciones de Escalabilidad

- El modelo de datos soporta multiples redes a futuro (RF portabilidad)
- Soporte para al menos 10 agentes simultaneos sin degradacion
- Agente limitado a <5% CPU y <100MB RAM en el endpoint
- API: <2s para consultas simples, <5s para historicas
- Motor: procesamiento de lote PCAP < intervalo de rotacion

---

> **Nota:** Los diagramas utilizan sintaxis PlantUML. Para renderizarlos, se puede usar [PlantUML Online Server](https://www.plantuml.com/plantuml), la extension de PlantUML en VS Code, o cualquier herramienta compatible con la sintaxis `@startuml/@enduml`.
