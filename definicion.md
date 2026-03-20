Sistema de Monitoreo de Infraestructura y Gestión de Seguridad (Móvil) - GOATGuard 

Árbol del problema 

1.1.  Problema Central  

Los responsables de infraestructura tecnológica en redes enfrentan una limitación persistente, que es la incapacidad de mantener una supervisión integral, continua y contextualizada del tráfico que circula por la red y del comportamiento de los dispositivos que la componen. Esta situación responde a un conjunto de factores estructurales que, actuando de manera conjunta, impiden observar, comprender y reaccionar oportunamente ante lo que ocurre dentro de la infraestructura. El resultado es una gestión que opera en gran medida a ciegas, donde las anomalías, los dispositivos no identificados y las degradaciones de rendimiento pasan inadvertidas hasta que sus efectos ya son evidentes. 

1.2. Causas (Raíces del problema) 

1.2.1. C1: Dependencia de modelos de monitoreo centralizados y estáticos vinculados a estaciones de trabajo fijas. 

 

Las herramientas convencionales de monitoreo operan desde un punto fijo dentro de la red, obligando al administrador a permanecer anclado a un entorno de escritorio para supervisar la infraestructura. Si bien existen alternativas de acceso remoto como SSH o VPN, estas presentan información en formatos de texto plano o métricas numéricas crudas que exigen un esfuerzo cognitivo considerable para su interpretación, especialmente en dispositivos móviles o pantallas reducidas, donde la supervisión 	remota se vuelve impráctica y propensa a errores. 

 

1.2.2. C2: Ausencia de mecanismos de captura de tráfico distribuida a nivel de endpoint 

 

Las herramientas tradicionales capturan tráfico desde un único punto de observación como un puerto mirror en un switch o una interfaz en modo promiscuo, lo cual ofrece una visión agregada, pero carece de granularidad por dispositivo individual. Sin agentes distribuidos que capturen tráfico directamente en cada endpoint, el administrador pierde la capacidad de correlacionar el comportamiento de red con dispositivos específicos, de modo que un equipo que genere un volumen inusual de retransmisiones TCP o un consumo anómalo de ancho de banda queda diluido dentro del tráfico general y resulta difícil de identificar como origen del problema. 

 

1.2.3. C3: Insuficiente procesamiento y contextualización de las métricas derivadas del tráfico de red 

 

Aun cuando se capturan volúmenes significativos de tráfico, la presentación de estos datos se limita a registros crudos como archivos PCAP sin procesar, logs en texto plano o contadores de paquetes. Sin un módulo de análisis que transforme estos datos en métricas contextualizadas, como indicadores de salud del enlace ISP, perfiles de consumo de ancho de banda, tasas de retransmisión por flujo TCP o tiempos de respuesta DNS, la información existe, pero permanece inaccesible en un formato que no permite diagnósticos rápidos ni fundamentados. 

 

1.2.4. C4: Carencia de un inventario dinámico y clasificado de los dispositivos conectados a la red 

 

Las técnicas de descubrimiento basadas en escaneo activo detectan la presencia de dispositivos, pero se limitan a identificar direcciones IP y MAC sin ofrecer una clasificación real del tipo de dispositivo ni su rol dentro de la red. El administrador no sabe con certeza cuántos dispositivos están conectados, cuáles son legítimos y cuáles podrían ser no autorizados, ni puede distinguir automáticamente entre un computador de trabajo, una impresora, un dispositivo IoT o un equipo personal no autorizado. Sin este inventario dinámico, se vigila una red cuya composición exacta se desconoce. 

1.3. Efectos (Consecuencias del problema) 

 

1.3.1. E1: Tiempos de detección prolongados ante anomalías y amenazas dentro de la red 

 

Sin monitoreo continuo que analice el comportamiento del tráfico y genere alertas automáticas, los eventos inusuales pasan inadvertidos, ya sean degradaciones de rendimiento, consumos de ancho de banda anómalos o patrones de comunicación irregulares. El administrador solo toma conocimiento cuando los efectos ya se materializaron en un servicio caído, lentitud reportada por los usuarios o una saturación del enlace que ya afectó la operatividad. Cada minuto entre la aparición de una anomalía y su detección amplía el impacto sobre el funcionamiento de la red. 

1.3.2. E2: Interrupciones en la capacidad de supervisión durante los períodos de movilidad del administrador 

Dado que las herramientas están atadas a entornos de escritorio, cada vez que el administrador se desplaza, la supervisión se interrumpe de facto. La gestión se convierte en un proceso intermitente y reactivo: las decisiones se basan en instantáneas capturadas en los momentos frente a la consola, no en una imagen en tiempo real. Cuando un incidente ocurre durante estos intervalos sin supervisión, la respuesta llega tarde y sin información de contexto sobre lo ocurrido. 

1.3.3. E3: Diagnósticos imprecisos y decisiones operativas fundamentadas en información incompleta 

Cuando la información disponible consiste en logs fragmentados, métricas sin contexto y un inventario incompleto, los diagnósticos son imprecisos, el administrador puede identificar que existe un problema de rendimiento, pero no determinar con rapidez si la causa es saturación del enlace, un dispositivo generando tráfico excesivo, una falla de configuración o actividad maliciosa. Esto conduce a ciclos de prueba y error que consumen tiempo y recursos, y en ocasiones agravan el problema original. 

1.3.4. E4: Presencia no detectada de dispositivos no autorizados y exposición a riesgos de seguridad internos 

Sin un inventario dinámico, dispositivos no autorizados pueden conectarse y operar sin ser detectados: un equipo personal infectado, un dispositivo IoT con firmware desactualizado o un atacante con acceso físico a un puerto de red. Esto compromete la confidencialidad (interceptación de tráfico sensible) , la integridad (introducción de datos maliciosos) y la disponibilidad (consumo descontrolado de recursos o ataques internos de denegación de servicio). 

 

 

Figura 1. Árbol del problema del proyecto (Elaboración propia). 

 

Situación Problema 

 

En la gestión actual de infraestructuras tecnológicas, existe una dependencia estructural de consolas de administración estáticas y complejas, lo que obliga a los responsables de TI a permanecer anclados a sus estaciones de trabajo para supervisar la red. Esta limitación operativa genera una brecha de visibilidad y control, ocasionando que, durante los periodos de desplazamiento o ausencia física del administrador, se pierda la capacidad de monitorear el estado de los activos en el momento. Dicha desconexión deriva en la imposibilidad de identificar dispositivos desconocidos o detectar anomalías de seguridad de manera oportuna, incrementando la exposición de la infraestructura a vulnerabilidades no gestionadas y comprometiendo la integridad de los endpoints frente a intentos de intrusión. 

Pregunta problematizadora 

¿Cómo abordar la visibilidad y control sobre el comportamiento del tráfico de red y el estado de los activos conectados en una infraestructura, considerando la necesidad de detectar anomalías, métricas y dispositivos de forma independiente de la ubicación física del administrador? 

Justificación 

Las infraestructuras de red de área local constituyen el soporte operativo sobre el cual las organizaciones sostienen sus procesos de comunicación, almacenamiento y acceso a la información, por lo que mantener la visibilidad sobre lo que ocurre dentro de estas redes no es un aspecto opcional de la administración sino una condición necesaria para preservar la disponibilidad de los servicios y el funcionamiento adecuado de los activos de información; cuando esta visibilidad se pierde o se ve limitada, las consecuencias afectan tanto la operatividad de la infraestructura como la capacidad de respuesta del equipo responsable de su gestión. 

Una de las consecuencias más directas de esta deficiencia es la prolongación de los tiempos de detección frente a anomalías en el tráfico de red, dado que eventos como incrementos inusuales en retransmisiones TCP, consumos anómalos de ancho de banda o degradaciones de rendimiento pueden transcurrir durante horas o días sin ser identificados, lo que amplía el impacto de estas situaciones sobre la operatividad de la red e incrementa la probabilidad de que un problema menor escale hacia una afectación con consecuencias mayores sobre los servicios de la organización. A esta situación se suma la interrupción recurrente de la supervisión durante los períodos en que el administrador no se encuentra frente a su estación de trabajo, ya que cualquier desplazamiento genera un intervalo sin vigilancia donde la infraestructura sigue operando pero nadie observa su comportamiento, convirtiendo la gestión en un proceso intermitente donde los incidentes solo se conocen una vez que sus efectos ya son visibles para los usuarios finales en forma de caídas de servicio, lentitud o pérdida de conectividad. 

Por otra parte, cuando el administrador sí logra acceder a la información de red, la calidad de los diagnósticos que puede realizar se ve comprometida por la falta de contexto y procesamiento de los datos disponibles, puesto que los registros crudos de tráfico y los logs en texto plano no ofrecen por sí solos una lectura clara de lo que está sucediendo, lo que obliga a una interpretación manual que consume tiempo, resulta propensa a conclusiones erróneas y conduce a ciclos de prueba y error que retrasan la resolución e incluso pueden agravar la situación original. 

En conjunto, estas consecuencias evidencian que la problemática identificada no se limita a una incomodidad operativa sino que representa una debilidad estructural en la forma en que se supervisan y protegen las redes de área local, lo cual hace pertinente su abordaje desde la ingeniería en la medida en que requiere la integración de conocimientos en redes de datos, seguridad informática, desarrollo de software y diseño de infraestructura tecnológica para plantear una solución que responda de forma articulada a las causas que originan el problema. 

Definición de objetivos 

 

Objetivo general  

Desarrollar un sistema de monitoreo de tráfico de red local mediante el diseño, implementación e integración de agentes de captura distribuida, un backend de análisis centralizado y una aplicación móvil, con el fin de proporcionar visibilidad continua sobre el comportamiento del tráfico y el estado de los activos conectados a la red de forma independiente de la ubicación física del administrador. 

 

Objetivos específicos: 

 

Diseñar la arquitectura del sistema de monitoreo, compuesta por agentes de captura en endpoints, un servidor colector, un motor de análisis y una aplicación móvil, mediante la definición de los flujos de datos, protocolos de comunicación y estructuras de almacenamiento, con el fin de establecer la base técnica sobre la cual se construirán los componentes del sistema. 

Implementar los agentes de captura, el motor de análisis con su inventario dinámico de activos y la aplicación móvil, mediante la construcción e integración de cada componente según la arquitectura diseñada, con el fin de recolectar el tráfico de los endpoints, transformarlo en métricas contextualizadas y presentarlas al administrador junto con notificaciones ante comportamientos de tráfico inusuales. 

 

Validar el funcionamiento del sistema mediante la ejecución de pruebas sobre los módulos de captura, análisis y visualización, con el fin de verificar que los datos fluyan correctamente desde los agentes hasta la aplicación móvil y que la información presentada sea consistente con el tráfico real de la red. 

 

Desplegar el sistema mediante pipelines de integración y entrega continua, con el fin de facilitar la publicación de la aplicación móvil y la puesta en operación del backend en un entorno funcional. 

 

 

Marco teórico 

 

Figura. Mapa conceptual del marco teórico del proyecto GOATGuard (Elaboración propia). 

 

 

 

 

Estado del arte 

7.1. Fundamentos de comunicación y monitoreo en redes LAN 

 

El estudio del monitoreo de infraestructuras tecnológicas se fundamenta en los principios de comunicación en redes de datos, particularmente en el modelo OSI , el cual divide el proceso de comunicación en siete capas funcionales. Este modelo permite abstraer la complejidad de las comunicaciones y establecer una estructura conceptual para el diseño, análisis y diagnóstico de sistemas de red. 

 

Las capas inferiores del modelo OSI, como la capa física y de enlace de datos, permiten la identificación de dispositivos mediante direcciones MAC y el análisis de tramas dentro del segmento local. Por su parte, las capas de red y transporte permiten examinar direcciones IP, protocolos como TCP y UDP, puertos de comunicación y establecimiento de sesiones. Estos elementos constituyen la base técnica sobre la cual se desarrollan las primeras herramientas de administración de redes, orientadas principalmente a verificar conectividad, disponibilidad y estado de servicios. 

 

En los primeros enfoques de monitoreo, la supervisión se realizaba desde estaciones de trabajo fijas mediante herramientas que generaban tráfico de prueba (monitoreo activo) o analizaban paquetes capturados desde un único punto de observación (monitoreo pasivo). Aunque estas soluciones permitieron un avance significativo en la administración de redes LAN, su alcance estaba limitado por su naturaleza centralizada y estática. 

 

Estos fundamentos técnicos constituyen la base conceptual sobre la cual se desarrollan posteriormente soluciones más avanzadas orientadas al descubrimiento dinámico de activos, captura distribuida de tráfico y análisis contextualizado de métricas, aspectos centrales en la propuesta de GOATGuard. 

 

7.2. Descubrimiento y clasificación de activos en redes 

 

A partir de los fundamentos del modelo OSI y la arquitectura TCP/IP, surgieron herramientas orientadas al descubrimiento de activos en redes locales mediante técnicas de escaneo activo. Estas técnicas emplean solicitudes ARP, ICMP o sondeos TCP/UDP para identificar dispositivos conectados, detectar puertos abiertos y determinar servicios disponibles. 

 

Herramientas especializadas como los escáneres de red permiten construir inventarios básicos de dispositivos, registrando direcciones IP y MAC detectadas en la infraestructura. Este enfoque representa un avance frente a la supervisión manual, ya que automatiza la identificación de nodos presentes en la red. 

 

Sin embargo, estos mecanismos presentan limitaciones relevantes. En muchos casos, la información obtenida se restringe a la presencia del dispositivo y a datos técnicos básicos, sin proporcionar una clasificación detallada del tipo de equipo ni su rol dentro de la red. Además, el descubrimiento suele realizarse de manera periódica y no necesariamente en tiempo real, lo que puede dejar intervalos donde dispositivos no autorizados operan sin ser detectados. 

 

Para superar estas limitaciones, surgieron técnicas de network fingerprinting, que combinan información de múltiples capas del modelo OSI para inferir características del dispositivo. El análisis del prefijo OUI de la dirección MAC permite identificar el fabricante; el estudio de servicios expuestos, patrones de comunicación y comportamiento del tráfico permite inferir si se trata de una estación de trabajo, impresora, servidor, dispositivo IoT o equipo móvil. 

 

Este enfoque evoluciona desde un simple listado de direcciones IP hacia un inventario dinámico y clasificado de activos, capaz de proporcionar contexto operativo. En el marco del proyecto GOATGuard, esta evolución es fundamental, ya que el sistema no solo debe detectar dispositivos, sino clasificarlos y correlacionar su comportamiento de tráfico con métricas específicas que permitan identificar anomalías. 

 

7.3. Soluciones avanzadas de monitoreo, análisis y detección de anomalías 

 

En el ámbito de la seguridad informática y la gestión de infraestructura, el monitoreo ha evolucionado hacia soluciones más sofisticadas que integran captura de tráfico, análisis de métricas y mecanismos de detección de anomalías. Estas herramientas no se limitan a verificar conectividad, sino que analizan el comportamiento del tráfico para identificar patrones inusuales como incrementos anómalos en el consumo de ancho de banda, tasas elevadas de retransmisión TCP, conexiones hacia destinos atípicos o posibles escaneos de puertos. 

 

Tradicionalmente, estas soluciones se implementan en consolas de escritorio o servidores centralizados que concentran la captura, procesamiento y visualización de la información. Ejemplos representativos de este enfoque incluyen herramientas como Wireshark, ampliamente utilizada para el análisis profundo de paquetes en tiempo real; Nmap, empleada para el descubrimiento de hosts y escaneo de puertos; y sistemas de detección de intrusos como Snort, orientado a la identificación de patrones de ataque mediante reglas predefinidas. Asimismo, plataformas empresariales como Zabbix o PRTG Network Monitor permiten supervisar dispositivos, servicios y métricas de red desde dashboards centralizados. 

 

Aunque estas herramientas ofrecen un alto nivel de profundidad técnica y capacidades avanzadas de análisis, mantienen una dependencia estructural de entornos fijos de administración o configuraciones complejas, lo que restringe la movilidad del responsable de infraestructura y puede generar interrupciones en la supervisión continua. 

 

En respuesta a estas limitaciones, han surgido enfoques basados en arquitecturas distribuidas, donde agentes ligeros instalados en los endpoints capturan información localmente y la envían a un servidor central para su procesamiento. Este modelo mejora la granularidad del monitoreo, permitiendo correlacionar métricas específicas con dispositivos individuales y detectar comportamientos anómalos con mayor precisión. 

 

Paralelamente, la integración de aplicaciones móviles como interfaz de supervisión representa una tendencia creciente en la administración de sistemas, permitiendo el acceso remoto a dashboards, métricas y alertas en tiempo real. No obstante, muchas soluciones comerciales están orientadas a infraestructuras de gran escala o requieren licenciamiento empresarial, lo que limita su accesibilidad en entornos académicos o redes de tamaño medio. 

 

En este escenario, se identifica una brecha entre los mecanismos tradicionales de descubrimiento y análisis de tráfico, y la necesidad de soluciones que integren captura distribuida, inventario dinámico clasificado, procesamiento contextualizado de métricas y acceso móvil en tiempo real dentro de una arquitectura unificada. Esta brecha justifica el desarrollo de GOATGuard como una propuesta que articula estos componentes para proporcionar visibilidad continua, detección temprana de anomalías y control independiente de la ubicación física del administrador. 

 