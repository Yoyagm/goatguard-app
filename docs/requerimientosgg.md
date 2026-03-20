Contenido 

 

 

Introducción 

El presente documento constituye la Especificación de Requerimientos del Software (ERS) para el proyecto GOATGuard, elaborada en el marco del Proyecto Integrador III de la Facultad de Ingeniería de Sistemas e Informática de la Universidad Pontificia Bolivariana, seccional Bucaramanga. Su objetivo es definir de manera precisa los requerimientos necesarios para el desarrollo del sistema de monitoreo de tráfico de red local, el cual se compone de tres módulos principales: los agentes de captura desplegados en endpoints, el backend de análisis centralizado (que incluye el servidor colector, el motor de análisis y  API) y la aplicación móvil de consulta y notificaciones. En esta especificación se identifican los factores que orientan el diseño e implementación de cada módulo, tales como la prioridad de cada requerimiento, su clasificación funcional o no funcional, los criterios de aceptación correspondientes y las dependencias entre componentes. Esta documentación busca establecer una base común de entendimiento entre los integrantes del equipo de desarrollo y los interesados del proyecto, facilitando la trazabilidad y el seguimiento de los requerimientos durante el ciclo de vida del software. 

Propósito 

El propósito de esta especificación es documentar de manera estructurada los requerimientos funcionales y no funcionales que deberán ser implementados para el correcto funcionamiento del sistema GOATGuard en sus tres componentes, además, este documento proporciona una visión clara de los criterios de aceptación de cada funcionalidad, permitiendo su validación y posterior trazabilidad durante las fases de diseño, desarrollo, pruebas y despliegue. 

Alcance 

Este documento delimita y describe los requerimientos funcionales y no funcionales del sistema organizados por sus cuatro módulos: el módulo de agentes de captura, que abarca la recolección de tráfico y métricas en cada endpoint, su transmisión al colector y el descubrimiento de dispositivos en la red; el módulo de backend centralizado, que comprende la recepción, procesamiento y persistencia de los datos para generar métricas contextualizadas, un inventario dinámico de activos y alertas ante tráfico sospechoso expuestos a través de una API; el módulo de aplicación móvil, que cubre la autenticación, consulta de dispositivos y métricas, edición de alias, visualización del estado de la red y recepción de notificaciones push; y el módulo transversal de despliegue, que contempla la infraestructura de integración y entrega continua. 

 

Esta especificación no contempla la implementación de la infraestructura de red sobre la cual opera el sistema, ni mecanismos de respuesta automática ante incidentes, ni la administración activa de la red o los dispositivos conectados a ella. 

Descripción general 

Perspectiva del producto 

GOATGuard es un sistema autónomo que no depende de plataformas de monitoreo existentes ni se integra con herramientas de terceros para su funcionamiento base; opera como una solución independiente diseñada para redes de área local de pequeña y mediana escala. Su arquitectura contempla dos canales de comunicación diferenciados entre los agentes y el colector, en uno para la transmisión de datos de tráfico capturado y otro para el envío de métricas ligeras del estado del endpoint, lo que permite separar el flujo pesado de paquetes del reporte periódico de indicadores del sistema operativo. El sistema hace uso de herramientas especializadas de análisis de tráfico para procesar los datos capturados, pero estas operan de forma interna y transparente para el usuario final. 

Funcionalidad del producto 

El sistema opera bajo un flujo continuo donde los agentes recolectan datos en cada endpoint y los transmiten al colector, el motor de análisis los transforma en métricas contextualizadas y construye un inventario dinámico de activos, y la aplicación móvil presenta esta información al administrador junto con alertas ante comportamientos de tráfico inusuales. Los agentes se instalan manualmente en cada endpoint y se registran en el colector al ejecutarse por primera vez, a partir de lo cual comienzan a operar de forma autónoma sin intervención adicional del administrador. 

Características de los usuarios 

 

Tipo de usuario 

Descripción 

Administrador de red / Usuario Base 

Usuario principal del sistema. Accede a la aplicación móvil mediante credenciales autenticadas y tiene acceso completo a todas las funcionalidades. Se asume que posee conocimientos técnicos en administración de redes. 

 

Requisitos específicos 

Requisitos funcionales 

Requisito funcional 1 

IDENTIFICADOR: RF-01 

NOMBRE: Captura, sanitización y transmisión de tráfico de red 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO:  

ENTRADA: Interfaz de red activa del endpoint con tráfico entrante y saliente. 

SALIDA: Flujo TCP continuo de paquetes sanitizados (PCAP) enviados al colector, con metadata orig_len preservada. 

DESCRIPCIÓN: El agente debe capturar de forma continua todos los paquetes de red que circulen por la interfaz del endpoint, aplicar un recorte dinámico (slicing) al payload según el puerto de destino (DNS/HTTPS: 300 bytes, resto: 96 bytes) preservando el campo orig_len para cálculo real de ancho de banda, y transmitir los paquetes sanitizados al colector mediante una conexión TCP persistente que garantice la entrega ordenada. 

PRECONDICIONES: El agente debe estar ejecutándose con permisos de captura de red y el colector debe ser accesible en la LAN. 

POSTCONDICIONES: Los paquetes sanitizados han sido transmitidos al colector con headers completos y metadata de tamaño original preservada. 

FLUJO BÁSICO: 1. El agente inicia captura sobre la interfaz principal. 
2. Cada paquete es interceptado y almacenado en buffer local. 
3. Se identifica el puerto de destino y se aplica la regla de slicing, preservando orig_len. 
4. Se establece conexión TCP con el colector y se transmiten los paquetes continuamente. 

FLUJO ALTERNATIVO: 1. Si la interfaz no está disponible, registra error y reintenta. 
2. Si el paquete es menor al umbral de recorte, se transmite sin modificación. 
3. Si la conexión TCP se pierde, reintenta; paquetes durante desconexión se descartan. 

 

Requisito funcional 2 

IDENTIFICADOR: RF-02 

NOMBRE: Recolección y transmisión de métricas de sistema del endpoint 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-01 

ENTRADA: Estado actual del procesador, memoria y enlace de red del endpoint. 

SALIDA: Paquete UDP periódico (cada 5s) con CPU (%), RAM (%) y velocidad de enlace (Mbps) enviado al colector. 

DESCRIPCIÓN: El agente debe recolectar periódicamente las métricas de uso de CPU, memoria RAM y velocidad del enlace de red, empaquetarlas en un paquete UDP personalizado con timestamp e identificador del agente, y enviarlas al colector cada 5 segundos por un canal paralelo e independiente del flujo TCP de tráfico. 

PRECONDICIONES: El agente debe estar ejecutándose con permisos de lectura sobre los recursos del sistema. 

POSTCONDICIONES: El colector ha recibido las métricas del endpoint y las tiene disponibles para persistencia. 

FLUJO BÁSICO: 1. El agente consulta CPU, RAM y velocidad de enlace. 
2. Empaqueta los valores con timestamp e identificador en paquete UDP. 
3. Envía al colector por el puerto UDP designado. 
4. Repite cada 5 segundos. 

FLUJO ALTERNATIVO: 1. Si la lectura de alguna métrica falla, se envía valor nulo. 
2. Si el envío UDP falla, descarta y reintenta en el siguiente ciclo. 

 

Requisito funcional 3 

IDENTIFICADOR: RF-03 

NOMBRE: Descubrimiento de dispositivos en la red por ARP 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO:  

ENTRADA: Segmento de red al que está conectado el endpoint. 

SALIDA: Lista de dispositivos detectados con dirección IP y MAC transmitida al colector. 

DESCRIPCIÓN: El agente debe ejecutar periódicamente un escaneo ARP sobre el segmento de red para descubrir todos los dispositivos conectados, incluyendo aquellos sin agente instalado, y transmitir la lista al colector para la construcción del inventario de activos. 

PRECONDICIONES: El agente está conectado a la red local y tiene permisos para enviar solicitudes ARP. 

POSTCONDICIONES: El colector cuenta con un listado actualizado de dispositivos detectados en el segmento. 

FLUJO BÁSICO: 1. El agente envía solicitudes ARP al rango de direcciones del segmento. 
2. Recopila respuestas con IP y MAC. 
3. Transmite la lista al colector. 

FLUJO ALTERNATIVO: 1. Si un dispositivo no responde al ARP, no se incluye en ese ciclo. 

 

Requisito funcional 4 

IDENTIFICADOR: RF-04 

NOMBRE: Autoregistro y señal de vida del agente 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO:  

ENTRADA: Primera ejecución del agente o agente en ejecución continua. 

SALIDA: Agente registrado en el colector con identificador único (hostname + MAC) y heartbeats periódicos. 

DESCRIPCIÓN: El agente debe autoregistrarse en el colector al ejecutarse por primera vez mediante un handshake con su identificador único (hostname + MAC), y posteriormente enviar señales de vida (heartbeat) periódicas con timestamp para que el colector determine qué agentes están activos y cuáles dejaron de reportar. 

PRECONDICIONES: Es la primera ejecución del agente o el agente está registrado y en operación continua. 

POSTCONDICIONES: El colector tiene registrado al agente con su estado actualizado y marca de última actividad. 

FLUJO BÁSICO: 1. El agente genera su identificador (hostname + MAC). 
2. Envía handshake al colector y espera confirmación. 
3. Inicia operaciones normales. 
4. Envía heartbeat periódico con identificador y timestamp. 

FLUJO ALTERNATIVO: 1. Si ya está registrado, el colector actualiza el timestamp. 
2. Si el colector no responde, reintenta periódicamente. 
3. Si el heartbeat falla, continúa operando y reintenta. 

 

Requisito funcional 5 

IDENTIFICADOR: RF-05 

NOMBRE: Recepción simultánea de tráfico TCP y métricas UDP de agentes 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-01, RF-02 

ENTRADA: Flujos TCP con datos PCAP y paquetes UDP con métricas de sistema de los agentes. 

SALIDA: Datos de tráfico escritos en buffer PCAP local y métricas de endpoint almacenadas por agente. 

DESCRIPCIÓN: El colector debe recibir simultáneamente los flujos TCP de tráfico de todos los agentes activos escribiéndolos en un buffer PCAP local, y en paralelo recibir paquetes UDP con métricas de sistema (CPU, RAM, velocidad de enlace), asociándolos al endpoint correspondiente mediante su identificador único. 

PRECONDICIONES: Al menos un agente está conectado, transmitiendo datos y registrado en el colector. 

POSTCONDICIONES: Los datos de tráfico están en el buffer PCAP activo y las métricas de cada endpoint disponibles para persistencia. 

FLUJO BÁSICO: 1. El colector escucha conexiones TCP y paquetes UDP en los puertos designados. 
2. Acepta conexiones TCP y escribe datos en buffer_actual.pcap. 
3. Recibe paquetes UDP, extrae identificador y asocia métricas al endpoint. 

FLUJO ALTERNATIVO: 1. Si un agente TCP se desconecta, cierra esa conexión y sigue con los demás. 
2. Si un paquete UDP tiene identificador no registrado, se descarta. 

 

Requisito funcional 6 

IDENTIFICADOR: RF-06 

NOMBRE: Ingesta continua y rotación de archivos PCAP 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-05 

ENTRADA: Datos de tráfico recibidos por TCP en flujo continuo. 

SALIDA: Archivos PCAP rotados con timestamp (lote_YYYYMMDD_HHMMSS.pcap) y nuevo buffer vacío activo. 

DESCRIPCIÓN: El colector debe escribir de forma continua los datos de tráfico en buffer_actual.pcap y rotarlo automáticamente cada minuto o al alcanzar 100MB, renombrándolo con timestamp, cerrándolo para análisis e inmediatamente creando un nuevo buffer vacío sin interrupción. 

PRECONDICIONES: El servicio de recepción TCP está activo y hay agentes transmitiendo. 

POSTCONDICIONES: El archivo rotado está disponible para el motor de análisis y la ingesta continúa en un nuevo buffer. 

FLUJO BÁSICO: 1. Los datos TCP se escriben secuencialmente en buffer_actual.pcap. 
2. Al cumplirse rotación (1 min o 100MB), cierra y renombra a lote_YYYYMMDD_HHMMSS.pcap. 
3. Abre nuevo buffer_actual.pcap inmediatamente. 
4. El rotado queda disponible para el motor. 

FLUJO ALTERNATIVO: 1. Si el disco alcanza umbral de capacidad, emite alerta interna. 
2. Si el renombramiento falla, reintenta antes de abrir nuevo buffer. 

 

Requisito funcional 7 

IDENTIFICADOR: RF-07 

NOMBRE: Registro, control y estado de agentes conectados 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-04 

ENTRADA: Paquetes de handshake y heartbeats de los agentes. 

SALIDA: Registro actualizado de agentes con estado (activo/inactivo) y marca de última conexión. 

DESCRIPCIÓN: El colector debe mantener un registro de todos los agentes, procesando handshakes y heartbeats, actualizando su estado según la última actividad y marcando como inactivos los que superen el umbral de inactividad. 

PRECONDICIONES: Al menos un agente se ha registrado en el colector. 

POSTCONDICIONES: El inventario de agentes refleja el estado real de conectividad de cada uno. 

FLUJO BÁSICO: 1. Al recibir handshake, registra agente o actualiza timestamp. 
2. Al recibir heartbeat, actualiza marca de última actividad. 
3. Periódicamente verifica inactividad y marca agentes inactivos. 

FLUJO ALTERNATIVO: 1. Si un agente inactivo vuelve a reportar, se marca activo nuevamente. 

 

Requisito funcional 8 

IDENTIFICADOR: RF-08 

NOMBRE: Pipeline de procesamiento, condensación y persistencia de datos PCAP 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-06 

ENTRADA: Archivos PCAP rotados disponibles para lectura. 

SALIDA: Datos procesados, normalizados, correlacionados e insertados en SQL; archivos PCAP eliminados. 

DESCRIPCIÓN: El motor debe tomar cada archivo PCAP rotado, procesarlo con herramientas de análisis generando outputs estructurados, condensar y correlacionar la información entre fuentes (tráfico, métricas de endpoint, inventario ARP), estructurar según el modelo relacional, insertar en SQL con retención permanente, y eliminar los PCAP procesados exitosamente. 

PRECONDICIONES: Existe al menos un archivo PCAP rotado pendiente y la base de datos está accesible. 

POSTCONDICIONES: Las métricas están persistidas en SQL, disponibles para la API, y el espacio en disco liberado. 

FLUJO BÁSICO: 1. Detecta nuevo archivo PCAP rotado. 
2. Lo procesa con herramientas de análisis. 
3. Condensa y correlaciona datos con dispositivos del inventario. 
4. Estructura según modelo relacional e inserta en SQL. 
5. Confirma transacción y elimina el archivo PCAP. 

FLUJO ALTERNATIVO: 1. Si falla, marca como error y registra en log; no se elimina. 
2. Si un dato no puede correlacionarse, se registra con identificador genérico. 
3. Si la BD no está accesible, encola para inserción posterior. 

 

Requisito funcional 9 

IDENTIFICADOR: RF-09 

NOMBRE: Cálculo de métricas de tráfico por endpoint 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-08 

ENTRADA: Datos de tráfico procesados con orig_len preservado y conexiones TCP/IP por endpoint. 

SALIDA: Métricas por endpoint: ancho de banda real, ranking Top Talkers, retransmisiones TCP y conexiones fallidas. 

DESCRIPCIÓN: El motor debe calcular para cada endpoint: consumo real de ancho de banda usando orig_len, ranking de Top Talkers, retransmisiones TCP que indiquen problemas físicos de conexión, y conexiones salientes rechazadas o sin respuesta que indiquen configuraciones rotas o comportamiento anómalo. 

PRECONDICIONES: Los datos de tráfico han sido procesados y contienen orig_len y datos de conexiones TCP. 

POSTCONDICIONES: Las métricas de tráfico por endpoint están persistidas y disponibles para consulta por la API. 

FLUJO BÁSICO: 1. Agrupa paquetes por endpoint y suma orig_len para ancho de banda real. 
2. Ordena por consumo descendente para ranking Top Talkers. 
3. Analiza conexiones TCP e identifica retransmisiones. 
4. Filtra conexiones con rechazo o timeout por dispositivo. 
5. Persiste resultados. 

FLUJO ALTERNATIVO: 1. Si orig_len no disponible, usa tamaño del paquete recortado. 
2. Si todos tienen consumo cero, genera ranking vacío. 
3. Si no hay conexiones TCP o fallidas, registra valor cero. 

 

 Requisito funcional 10 

IDENTIFICADOR: RF-10 

NOMBRE: Cálculo de métricas de salud de la red 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-08 

ENTRADA: Pings periódicos a 8.8.8.8, datos de tráfico procesados y consultas DNS. 

SALIDA: Indicadores: ISP Health (latencia promedio), packet loss (%), DNS Response Time (ms) y jitter (varianza). 

DESCRIPCIÓN: El motor debe calcular indicadores globales: latencia promedio hacia servidor externo cada 30s para salud del ISP (>200ms indica problema), pérdida de paquetes global (>1% indica problemas), tiempo de respuesta DNS (>100ms indica DNS lento), y varianza de latencia (jitter) para estabilidad de la señal. 

PRECONDICIONES: Al menos un agente activo, datos de tráfico procesados y mediciones de latencia disponibles. 

POSTCONDICIONES: Los indicadores de salud de red están persistidos y disponibles para consulta. 

FLUJO BÁSICO: 1. Pings a 8.8.8.8 cada 30s y promedia para ISP Health. 
2. Contabiliza paquetes perdidos vs enviados para packet loss. 
3. Extrae consultas DNS y calcula tiempo de respuesta promedio. 
4. Calcula varianza de latencia para jitter. 
5. Persiste indicadores. 

FLUJO ALTERNATIVO: 1. Si ping falla completamente, registra pérdida total de conectividad. 
2. Si no hay datos suficientes, registra como indeterminado. 

 

 Requisito funcional 11 

IDENTIFICADOR: RF-11 

NOMBRE: Construcción de inventario dinámico de activos 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-03, RF-07 

ENTRADA: Lista de dispositivos descubiertos por ARP y registro de agentes. 

SALIDA: Inventario unificado con clasificación (con agente / sin agente) y estado de conexión. 

DESCRIPCIÓN: El motor debe construir y mantener un inventario dinámico que unifique dispositivos descubiertos por ARP con agentes registrados, clasificando cada activo según su cobertura de monitoreo y estado de conexión. 

PRECONDICIONES: Existen datos de descubrimiento ARP y/o agentes registrados. 

POSTCONDICIONES: El inventario está actualizado en la base de datos con clasificación de cobertura. 

FLUJO BÁSICO: 1. Cruza lista de dispositivos ARP con agentes registrados. 
2. Clasifica como 'con agente' o 'sin agente'. 
3. Actualiza inventario en la base de datos. 

FLUJO ALTERNATIVO: 1. Si un dispositivo desaparece en múltiples ciclos, se marca como desconectado. 

 

 Requisito funcional 12 

IDENTIFICADOR: RF-12 

NOMBRE: Detección de patrones de tráfico sospechoso y generación de alertas 

PRIORIDAD DE DESARROLLO: Media 

REQUERIMIENTO ASOCIADO: RF-08 

ENTRADA: Datos de tráfico procesados. 

SALIDA: Alertas generadas con tipo de anomalía, endpoint, descripción y timestamp. 

DESCRIPCIÓN: El motor debe analizar datos de tráfico en busca de patrones sospechosos (volúmenes inusuales, destinos atípicos, comportamientos repetitivos anómalos) y generar alertas registradas en la base de datos para notificación al administrador. 

PRECONDICIONES: Los datos de tráfico han sido procesados. 

POSTCONDICIONES: Las alertas quedan registradas para notificación vía push y consulta desde la app. 

FLUJO BÁSICO: 1. Evalúa datos contra criterios de detección definidos. 
2. Si detecta anomalía, genera registro de alerta con endpoint, tipo y timestamp. 
3. Persiste la alerta. 

FLUJO ALTERNATIVO: 1. Si no se detectan patrones sospechosos, no se genera alerta. 

 

 Requisito funcional 13 

IDENTIFICADOR: RF-13 

NOMBRE: Autenticación, autorización y gestión de tokens JWT 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO:  

ENTRADA: Credenciales (usuario y contraseña) o token JWT en cabecera de petición. 

SALIDA: Token JWT válido emitido o acceso concedido/denegado a endpoints protegidos. 

DESCRIPCIÓN: La API debe exponer un endpoint de autenticación que valide credenciales y retorne un token JWT con expiración definida. Todos los endpoints protegidos deben validar el token en cada petición, verificando firma, integridad y vigencia. Las contraseñas deben almacenarse con hashing seguro. 

PRECONDICIONES: El administrador tiene credenciales registradas o incluye token JWT en la petición. 

POSTCONDICIONES: El administrador posee un token JWT válido y los endpoints protegidos verifican su validez. 

FLUJO BÁSICO: 1. Recibe credenciales, valida contra BD y genera token JWT. 
2. En cada petición protegida, extrae token de cabecera. 
3. Verifica firma, integridad y vigencia. 
4. Si válido, permite acceso; si no, retorna 401. 

FLUJO ALTERNATIVO: 1. Credenciales incorrectas o usuario inexistente: retorna error genérico. 
2. Token inválido o expirado: retorna 401. 

 

 Requisito funcional 14 

IDENTIFICADOR: RF-14 

NOMBRE: Endpoints de consulta de inventario, métricas, estado y edición 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-08 a RF-11 

ENTRADA: Peticiones autenticadas con parámetros opcionales (identificador, rango de tiempo, nuevo alias). 

SALIDA: Respuestas JSON: inventario, detalle, métricas generales, métricas por endpoint, estado de agentes, histórico y confirmación de alias. 

DESCRIPCIÓN: La API debe exponer endpoints protegidos para: consultar inventario completo (IP, MAC, estado, clasificación, alias), detalle de un dispositivo con métricas, métricas generales de red (ISP Health, packet loss, Top Talkers, jitter, DNS RT), métricas por endpoint, estado de agentes, editar alias, y consultar métricas históricas por rango de tiempo. 

PRECONDICIONES: Token JWT válido y datos existentes en la base de datos. 

POSTCONDICIONES: El cliente recibe la información solicitada en formato JSON. 

FLUJO BÁSICO: 1. Recibe petición autenticada con parámetros. 
2. Consulta datos correspondientes en la BD. 
3. Retorna respuesta JSON. 

FLUJO ALTERNATIVO: 1. Sin datos: retorna lista vacía o valores por defecto. 
2. Dispositivo no existe: retorna 404. 
3. Alias excede largo: retorna error de validación. 

 

 Requisito funcional 15 

IDENTIFICADOR: RF-15 

NOMBRE: Consulta de alertas y envío de notificaciones push 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-12 

ENTRADA: Petición autenticada de consulta o nueva alerta generada por el motor. 

SALIDA: Lista cronológica de alertas y notificaciones push al dispositivo móvil. 

DESCRIPCIÓN: La API debe exponer un endpoint que retorne alertas ordenadas cronológicamente, y enviar notificaciones push al dispositivo móvil del administrador cuando se genere una nueva alerta, incluso con la app en segundo plano o cerrada. 

PRECONDICIONES: Token JWT válido y dispositivo registrado para notificaciones. 

POSTCONDICIONES: El cliente recibe alertas y el administrador es notificado vía push ante nuevas alertas. 

FLUJO BÁSICO: 1. Consulta: recibe petición, consulta alertas en BD, retorna lista cronológica. 
2. Push: detecta nueva alerta, construye payload, envía notificación. 

FLUJO ALTERNATIVO: 1. Sin alertas: retorna lista vacía. 
2. Si push falla, reintenta. 
3. Sin dispositivo registrado: alerta queda solo en BD. 

 

 Requisito funcional 16 

IDENTIFICADOR: RF-16 

NOMBRE: Gestión de sesión: login, persistencia y cierre 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-13 

ENTRADA: Credenciales ingresadas por el administrador o token JWT almacenado localmente. 

SALIDA: Acceso al dashboard, sesión persistente entre aperturas, o cierre de sesión con token eliminado. 

DESCRIPCIÓN: La app debe presentar pantalla de login para autenticarse contra la API, mantener la sesión activa mientras el token JWT sea válido (sin requerir login al reabrir), y permitir cerrar sesión eliminando el token y redirigiendo a login. 

PRECONDICIONES: La app está instalada y el administrador tiene credenciales válidas. 

POSTCONDICIONES: El administrador accede al dashboard tras autenticarse o al reabrir con token válido, y puede cerrar sesión. 

FLUJO BÁSICO: 1. Login: ingresa credenciales, envía a API, almacena JWT y navega al dashboard. 
2. Persistencia: al abrir, verifica token; si válido, navega al dashboard. 
3. Cierre: elimina token y redirige a login. 

FLUJO ALTERNATIVO: 1. Credenciales incorrectas: muestra error. 
2. Sin conexión: muestra mensaje de conectividad. 
3. Token expirado: redirige a login. 

 

 Requisito funcional 17 

IDENTIFICADOR: RF-17 

NOMBRE: Dashboard general, indicadores de red y métricas históricas 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-14 

ENTRADA: Métricas generales de red, estado de agentes y rango de tiempo seleccionado. 

SALIDA: Dashboard con ISP Health, packet loss, Top Talkers, jitter, DNS RT, indicadores de agentes y gráficas históricas. 

DESCRIPCIÓN: La app debe mostrar dashboard con métricas generales actualizadas periódicamente, indicadores visuales de estado de cada agente (activo/inactivo), y permitir consultar métricas históricas seleccionando rango de tiempo con visualización gráfica. 

PRECONDICIONES: El administrador está autenticado y la API retorna métricas y estado de agentes. 

POSTCONDICIONES: El administrador visualiza estado general, identifica agentes activos/inactivos y explora el histórico. 

FLUJO BÁSICO: 1. Consulta métricas generales y presenta indicadores. 
2. Consulta estado de agentes y muestra indicador visual (verde/rojo). 
3. Actualiza periódicamente. 
4. Permite seleccionar rango y presentar métricas históricas en gráficas. 

FLUJO ALTERNATIVO: 1. Si API no responde, muestra últimos datos con indicación de desactualización. 
2. Sin agentes: no muestra la sección. 
3. Sin datos en rango: muestra mensaje. 

 

 Requisito funcional 18 

IDENTIFICADOR: RF-18 

NOMBRE: Inventario de dispositivos, detalle, edición de alias y contextualización 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-14 

ENTRADA: Inventario obtenido de la API y acciones del administrador (selección, edición). 

SALIDA: Lista diferenciada (con/sin agente), detalle con métricas, alias editables y vista por segmento de red. 

DESCRIPCIÓN: La app debe mostrar el listado completo diferenciando visualmente dispositivos con agente de los descubiertos por ARP, permitir detalle individual con métricas (tráfico, CPU, RAM, retransmisiones, conexiones), editar alias, y contextualizar dispositivos dentro de su segmento de red. 

PRECONDICIONES: El administrador está autenticado y el inventario existe. 

POSTCONDICIONES: El administrador visualiza, consulta y edita los dispositivos con toda su información. 

FLUJO BÁSICO: 1. Consulta inventario y muestra lista diferenciada con/sin agente. 
2. Al tocar dispositivo, consulta detalle y presenta métricas. 
3. Permite modificar alias y enviar actualización. 
4. Organiza dispositivos por segmento de red. 

FLUJO ALTERNATIVO: 1. Sin dispositivos: inventario vacío. 
2. Sin agente: solo info básica (IP, MAC, estado ARP). 
3. Falla alias: muestra error y conserva anterior. 
4. Un segmento: todos en un grupo. 

 

 Requisito funcional 19 

IDENTIFICADOR: RF-19 

NOMBRE: Notificaciones push: permisos, registro, recepción y listado de alertas 

PRIORIDAD DE DESARROLLO: Alta 

REQUERIMIENTO ASOCIADO: RF-15 

ENTRADA: Permisos del OS, token de notificación del dispositivo y alertas del backend. 

SALIDA: Permisos configurados, token registrado, notificaciones push recibidas e historial de alertas consultable. 

DESCRIPCIÓN: La app debe solicitar permisos de notificación al OS, registrar el token en el backend, mostrar notificaciones a nivel del sistema operativo cuando el backend detecte tráfico inusual (incluso con app cerrada), y presentar listado cronológico con el historial de alertas. 

PRECONDICIONES: La app está instalada, el administrador autenticado y permisos de notificación solicitados. 

POSTCONDICIONES: El administrador recibe notificaciones push ante alertas y consulta el historial dentro de la app. 

FLUJO BÁSICO: 1. Detecta ausencia de permisos y los solicita al OS. 
2. Si concedidos, obtiene token y lo registra en el backend. 
3. Recibe notificaciones push a nivel del OS. 
4. Muestra listado de alertas ordenado cronológicamente. 

FLUJO ALTERNATIVO: 1. Si deniega permisos: funciona sin push, alertas solo en la app. 
2. Falla registro token: reintenta en siguiente inicio. 
3. Sin alertas: muestra mensaje. 

 

Requisitos no funcionales 

Rendimiento 

El sistema deberá estar preparado para operar con al menos 10 agentes transmitiendo tráfico y métricas de forma simultánea hacia el colector sin degradación del servicio, con la arquitectura diseñada para escalar a un mayor número de endpoints a futuro. El agente instalado en cada endpoint no deberá consumir más del 5% de CPU ni 100MB de RAM de forma sostenida, para no degradar el rendimiento del equipo monitoreado. 

 

Se establecen los siguientes requisitos mesurables: 

 

Los endpoints de la API deben responder en un tiempo máximo de 2 segundos para consultas simples (inventario, métricas actuales) y 5 segundos para consultas históricas con rango de tiempo, verificado mediante herramientas de medición y pruebas de carga. 

 

El motor de análisis debe procesar cada lote PCAP rotado en un tiempo menor al intervalo de rotación, evitando la acumulación de archivos sin procesar en el servidor. 

 

La transmisión de paquetes desde el agente hacia el colector no debe introducir una latencia adicional superior a 50ms dentro de la red local. 

Seguridad 

La arquitectura del sistema deberá incorporar medidas de seguridad que protejan tanto el acceso autorizado a la información de monitoreo como la integridad de los datos en tránsito y en reposo. Se establecen los siguientes requerimientos: 

 

El acceso a la aplicación móvil se realizará mediante autenticación basada en credenciales con generación de tokens JWT, y las contraseñas deberán almacenarse mediante algoritmos de hashing seguro, nunca en texto plano. 

 

Toda la comunicación entre la aplicación móvil y la API deberá realizarse sobre HTTPS para proteger los datos en tránsito. 

 

Los tokens JWT deberán contar con un tiempo de expiración definido, tras el cual el administrador debe autenticarse nuevamente, y todos los endpoints de la API (excepto login) deberán rechazar peticiones sin token válido. 

El colector y el motor de análisis deberán generar registros detallados (logs) de conexiones de agentes, procesamientos, errores y alertas generadas, con almacenamiento para trazabilidad y auditoría. 

 

Fiabilidad 

El sistema deberá ser diseñado para mantener un comportamiento estable y predecible tanto en condiciones normales como bajo carga sostenida de múltiples agentes. Para ello se establece: 

 

El agente debe ser capaz de reconectarse automáticamente al colector tras una pérdida de conexión en menos de 60 segundos, sin requerir intervención manual ni reinicio del servicio. 

 

Las inserciones de métricas en la base de datos deben ser transaccionales: si una inserción falla parcialmente, debe revertirse completa para evitar datos inconsistentes. 

 

La sanitización de paquetes en el agente debe preservar siempre el campo orig_len y los headers de red completos, independientemente del nivel de recorte aplicado al payload, asegurando la integridad de los datos desde el origen. 

 

Disponibilidad 

Se requiere una operación continua del sistema, especialmente en los componentes de colección y análisis de tráfico que constituyen el núcleo del monitoreo. Por tanto: 

 

El servidor colector deberá operar de forma continua 24/7 manteniendo activa la recepción de datos de los agentes, con un objetivo de al menos 7 días consecutivos de operación sin caídas no planificadas. 

 

La API deberá responder correctamente al 99% de las peticiones durante períodos de operación continua, y la aplicación móvil deberá indicar visualmente cuando los datos mostrados no estén actualizados debido a problemas de conexión con el backend. 

 

Mantenibilidad 

La solución deberá facilitar tareas de mantenimiento, actualización y despliegue de manera ágil durante el ciclo de desarrollo del proyecto: 

 

Toda modificación o despliegue deberá ser posible mediante pipelines de integración y entrega continua (CI/CD) tanto para el backend como para la aplicación móvil. 

 

Todos los endpoints de la API deberán estar documentados con su método, ruta, parámetros, respuestas posibles y códigos de error. 

 

Los parámetros de configuración del agente (IP del colector, puertos, intervalos de envío) deberán ser configurables mediante un archivo externo, sin necesidad de modificar el código fuente. 

 

Portabilidad 

El sistema será diseñado considerando la heterogeneidad de los entornos en los que operarán sus componentes. Para ello: 

 

El agente de captura debe ser compatible al menos con sistemas operativos Windows 10/11 y distribuciones Linux basadas en Debian/Ubuntu. 

 

La aplicación móvil debe ser compatible con dispositivos Android versión 10 o superior. 

 

El modelo de datos deberá estar diseñado para soportar la administración de múltiples redes a futuro, aunque el alcance actual se limite a una sola red local. 
