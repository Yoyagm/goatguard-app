# Perfil de Desarrollo — GOATGuard

## Contexto del Proyecto
GOATGuard es un sistema de monitoreo de infraestructura de red local compuesto
por tres componentes integrados:

- **Agentes de captura** (endpoints): capturan tráfico PCAP con slicing dinámico,
  recolectan métricas de sistema (CPU/RAM/enlace) y realizan descubrimiento ARP.
  Transmiten tráfico por TCP persistente y métricas por UDP cada 5s al colector.
- **Backend centralizado**: servidor colector + motor de análisis + API REST.
  Recibe PCAP en buffer con rotación cada 1min/100MB, procesa lotes con tshark/zeek,
  calcula métricas por endpoint (ancho de banda real via orig_len, Top Talkers,
  retransmisiones TCP), indicadores globales (ISP Health, packet loss, jitter, DNS RT),
  construye inventario dinámico de activos y genera alertas.
- **App móvil Android** (≥v10): dashboard con métricas en tiempo real, inventario
  de dispositivos con/sin agente, edición de alias, historial de alertas y
  notificaciones push incluso con app cerrada.

## Stack Tecnológico

### Agentes
- Python 3.x (compatible Windows 10/11 y Linux Debian/Ubuntu)
- Scapy o pyshark para captura de paquetes con slicing dinámico
- psutil para métricas de sistema (CPU, RAM, velocidad de enlace)
- Sockets TCP/UDP nativos para transmisión al colector
- Configuración externa por archivo (IP colector, puertos, intervalos)

### Backend
- Python + FastAPI para la API REST
- PostgreSQL como base de datos relacional (retención permanente)
- tshark/zeek para procesamiento de archivos PCAP rotados
- JWT para autenticación (bcrypt para hashing de contraseñas)
- Push notifications hacia Android (Firebase FCM)
- CI/CD pipelines para despliegue automatizado

### App Móvil (Flutter + Dart — Android ≥v10)
- Flutter con Dart como lenguaje principal (null safety habilitado siempre)
- Arquitectura: BLoC o Provider para gestión de estado
- dio o http para consumo de la API REST
- firebase_messaging para notificaciones push (incluso con app cerrada)
- flutter_secure_storage para almacenamiento seguro del JWT
- fl_chart o syncfusion_flutter_charts para visualización de métricas históricas

## Arquitectura de Datos Clave
- Agente → Colector: TCP para PCAP sanitizado (preservar orig_len siempre),
  UDP para métricas cada 5s
- Rotación de PCAP: buffer_actual.pcap → lote_YYYYMMDD_HHMMSS.pcap (1min o 100MB)
- Inventario: cruce de dispositivos ARP + agentes registrados →
  clasificación "con agente" / "sin agente"
- Alertas: generadas por el motor, persistidas en BD, enviadas por push

## Reglas de Código

### Generales
- Dart con null safety obligatorio. Nunca usar `dynamic` sin justificación explícita
- Python con type hints siempre. Seguir PEP 8 estrictamente
- Manejo explícito de errores: nunca catch/except vacío, loguear con contexto útil
- Funciones con responsabilidad única, máximo 50 líneas. Dividir si crece
- Nombres descriptivos en inglés para código, comentarios en español si aclaran lógica
- Early returns sobre if/else anidados siempre que sea posible

### Seguridad (crítico en este proyecto)
- NUNCA leer ni exponer archivos .env, secrets/ o credenciales
- Toda contraseña: bcrypt, nunca texto plano
- JWT con tiempo de expiración definido en todos los endpoints (excepto /login)
- Sanitizar inputs en la API antes de cualquier consulta a BD
- HTTPS obligatorio entre app móvil y API
- Los PCAP contienen tráfico real de red: tratarlos como datos sensibles

### Agentes de captura
- Preservar orig_len siempre, incluso al aplicar slicing al payload
- Slicing: DNS/HTTPS → 300 bytes, resto → 96 bytes
- Reconexión automática al colector en <60s sin intervención manual
- CPU del agente: máximo 5% sostenido, RAM: máximo 100MB

### Backend/API
- Respuestas en <2s para consultas simples, <5s para históricas
- Inserciones en BD siempre transaccionales (rollback si falla parcialmente)
- Motor de análisis debe procesar cada lote PCAP antes del próximo ciclo de rotación
- Logs detallados: conexiones de agentes, procesamientos, errores y alertas

## Requisitos Funcionales de Referencia
Los RF del sistema van del RF-01 al RF-19. Cuando trabajes en un módulo,
referencia el RF correspondiente en los comentarios del código y commits.

- RF-01 a RF-04: Módulo de agentes (captura, métricas, ARP, heartbeat)
- RF-05 a RF-12: Backend colector y motor de análisis
- RF-13 a RF-15: API REST (auth, endpoints, alertas/push)
- RF-16 a RF-19: App móvil (sesión, dashboard, inventario, notificaciones)

## Comandos del Proyecto
```bash
# Backend
uvicorn main:app --reload          # Servidor de desarrollo
pytest                             # Ejecutar tests
alembic upgrade head               # Aplicar migraciones de BD
python -m motor.processor          # Ejecutar motor de análisis manualmente

# Agente
python agent.py                    # Ejecutar agente (requiere permisos de red)
python agent.py --config config.ini  # Con configuración externa

# App móvil (Flutter)
flutter run                        # Ejecutar en dispositivo/emulador conectado
flutter test                       # Ejecutar tests unitarios y de widget
flutter build apk --release        # Build APK de producción
flutter pub get                    # Instalar dependencias del pubspec.yaml
dart fix --apply                   # Aplicar correcciones automáticas de Dart
```

## Convenciones de Commits
Formato: `tipo(módulo): descripción imperativa en español`
Tipos: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`
Módulos: `agente`, `colector`, `motor`, `api`, `app`, `ci`

Ejemplos:
- `feat(motor): calcular ranking Top Talkers por orig_len [RF-09]`
- `fix(agente): reconexión TCP automática en menos de 60s [RF-04]`
- `test(api): validar rechazo de tokens JWT expirados [RF-13]`

## Estilo de Comunicación
- Sé conciso: omite explicaciones obvias, ve directo al punto
- Muestra solo diffs relevantes, no archivos completos
- Si algo es ambiguo en los requisitos, pregunta antes de asumir
- Usa español para toda comunicación, inglés para código e identificadores
- Al corregir un bug, explica la causa raíz antes de mostrar el fix
- Referencia siempre el RF correspondiente cuando implementes o corrijas funcionalidad

## Entorno de Desarrollo
- MacBook M4, 16GB RAM, macOS
- Warp terminal
- Flutter SDK instalado en canal stable
- Python gestionado con Poetry por proyecto
- pnpm si se requiere Node.js en tooling auxiliar
