# GOATGuard App

Aplicacion movil Android del sistema **GOATGuard** — monitoreo de infraestructura de red local.

> Proyecto Integrador III — Universidad Pontificia Bolivariana, Bucaramanga.

## Arquitectura del Sistema

GOATGuard se compone de tres modulos independientes:

| Modulo | Repositorio | Descripcion |
|--------|------------|-------------|
| **Agente de captura** | [goatguard-agent](https://github.com/JPabloCarvajal/goatguard-agent) | Captura PCAP, metricas de sistema y descubrimiento ARP en endpoints |
| **Backend centralizado** | [goatguard-server](https://github.com/JPabloCarvajal/goatguard-server) | Colector + motor de analisis + API REST (FastAPI + PostgreSQL) |
| **App movil** | **Este repositorio** | Dashboard Android con metricas en tiempo real, inventario y alertas |

```
┌──────────┐    TCP/UDP     ┌──────────────────┐    HTTP/WS/JWT   ┌──────────────┐
│  Agentes  │ ────────────► │  Backend Server   │ ◄────────────► │  App Movil   │
│ (Python)  │               │  (FastAPI + PG)   │    Tailscale   │  (Flutter)   │
└──────────┘               └──────────────────┘                └──────────────┘
```

## Stack Tecnologico

| Capa | Tecnologia |
|------|-----------|
| Framework | Flutter 3.11+ (Dart, null-safe) |
| Arquitectura | Clean Architecture (entities, use cases, repositories, DTOs, mappers) |
| UI/Theming | Material 3 + Google Fonts (Inter / JetBrains Mono) |
| Graficos | fl_chart 0.70.2 |
| Estado | Provider 6.1 |
| HTTP | Dio (interceptor JWT, timeout, error handling) |
| WebSocket | websocket_channel (real-time state_update + alert_created) |
| Storage seguro | flutter_secure_storage 9.2.4 |
| Push notifications | firebase_messaging 16.1.2 + firebase_core 4.5.0 |
| Utilidades | intl 0.19.0 (formateo fechas/numeros) |
| Target | Android 10+ (API 29+) |

## Estructura del Proyecto

```
lib/
├── config/
│   ├── constants.dart        # Umbrales de metricas y salud de red
│   ├── env.dart              # URL del server configurable (FlutterSecureStorage)
│   ├── helpers.dart          # Funciones de color y formateo
│   └── theme.dart            # Tema oscuro: colores, tipografia, estilos
├── core/
│   ├── entities/             # Entidades de dominio (Device, Agent, Alert, etc.)
│   ├── ports/                # Interfaces de repositorios
│   ├── use_cases/            # Casos de uso por feature (auth, devices, alerts, metrics)
│   └── failure.dart          # Result<T> monad (Success/Err)
├── infrastructure/
│   ├── dtos/                 # Data Transfer Objects (fromJson parsing)
│   ├── mappers/              # DTO -> Entity transformation
│   ├── adapters/             # Port implementations (token storage, FCM, WebSocket)
│   └── repositories/        # Repository implementations (API calls)
├── models/
│   ├── device.dart           # Re-export + DeviceEntityIcon extension
│   ├── agent.dart            # Re-export + AgentEntity aliases
│   ├── alert.dart            # NetworkAlert, AlertSeverity
│   └── network_metrics.dart  # NetworkMetrics, TimeSeriesPoint, TopConsumer, etc.
├── providers/
│   ├── auth_provider.dart    # Login, logout, JWT lifecycle, FCM token registration
│   ├── device_provider.dart  # Devices + agents + history + connections
│   ├── alert_provider.dart   # Alerts + unseen count + WebSocket push
│   └── metrics_provider.dart # Network metrics + WebSocket real-time + history
├── services/
│   ├── api_service.dart      # Dio HTTP client with JWT interceptor
│   ├── websocket_service.dart # WebSocket connection + auto-reconnect
│   └── fcm_service.dart      # Firebase Cloud Messaging lifecycle
├── screens/
│   ├── splash/               # Splash animado (fade + scale)
│   ├── login/                # Autenticacion JWT
│   ├── auth/                 # Registro, TOTP enrollment, TOTP verify
│   ├── home/                 # Dashboard: health, metricas, agentes, top consumers
│   ├── inventory/            # Inventario filtrable con/sin agente
│   ├── analytics/            # Graficos historicos por rango de tiempo
│   ├── alerts/               # Listado de alertas por severidad
│   ├── settings/             # Perfil, backend server configurable, invitaciones, logout
│   ├── device_detail/        # Detalle individual de dispositivo
│   └── main_shell.dart       # Navegacion inferior + badge de alertas
├── widgets/
│   ├── cards/                # AgentTile, AlertTile, DeviceTile
│   ├── charts/               # LineMetricChart, BarMetricChart, IspHealthCard, TopTalkersHistoryChart
│   └── common/               # HealthBar, MetricCard, ResourceBar, StatusChip
└── main.dart                 # Punto de entrada, DI, rutas
```

## Requerimientos Funcionales Cubiertos

| RF | Nombre | Estado |
|----|--------|--------|
| RF-13 | Autenticacion JWT + 2FA TOTP + rate limiting | Implementado |
| RF-15 | Notificaciones push FCM + listado de alertas | Implementado |
| RF-16 | Gestion de sesion (login, persistencia, cierre) | Implementado |
| RF-17 | Dashboard, indicadores de red y metricas historicas | Implementado |
| RF-18 | Inventario, detalle, alias y contextualizacion | Implementado |
| RF-19 | Alertas con filtros por severidad + mark as seen | Implementado |

## Pantallas

- **Splash** — Animacion de entrada con logo GOATGuard
- **Login** — Formulario usuario/password con autenticacion JWT real
- **Register** — Registro con token de invitacion
- **TOTP Enrollment** — Escaneo QR para activar 2FA
- **TOTP Verify** — Verificacion de codigo TOTP en login
- **Home** — Health score, 4 metric cards (latencia ISP, packet loss, jitter, DNS RT), lista de agentes con CPU/RAM en tiempo real, top consumers
- **Inventory** — Busqueda + filtros (All / With Agent / ARP Only / With Alerts), tiles con metricas reales
- **Analytics** — Selector de rango (1h/6h/24h/7d), graficos de latencia, packet loss, jitter, ISP health card, top talkers history. Muestra "No historical data yet" cuando no hay datos
- **Alerts** — Filtros por severidad (critical/warning/info), badge de no leidas, mark as seen
- **Settings** — Perfil, backend server editable (para Tailscale/LAN), generar invitaciones, toggles de notificaciones, logout
- **Device Detail** — CPU, RAM, network metrics, TCP retransmissions chart, bandwidth chart, CPU/RAM history, external connections, alertas del dispositivo

## Integracion con Backend

La app consume la API REST del backend con autenticacion JWT. La URL del server es configurable desde Settings (persiste en FlutterSecureStorage).

### Endpoints consumidos

| Metodo | Ruta | Descripcion |
|--------|------|-------------|
| POST | `/auth/login` | Autenticacion, retorna JWT |
| POST | `/auth/register` | Registro con token de invitacion |
| POST | `/auth/totp/verify` | Verificacion 2FA |
| POST | `/auth/totp/enroll/complete` | Completar enrollment TOTP |
| GET | `/health` | Verificar conectividad del server |
| GET | `/devices/` | Inventario con metricas actuales |
| GET | `/devices/{id}` | Detalle de dispositivo con metricas y agent info |
| GET | `/devices/{id}/history?hours=4` | Historial para graficos |
| GET | `/devices/{id}/connections` | Conexiones externas |
| GET | `/devices/comparison?metric=X` | Comparacion entre dispositivos |
| PATCH | `/devices/{id}/alias` | Editar alias |
| GET | `/agents/` | Agentes con CPU, RAM, link speed |
| GET | `/network/metrics` | Metricas de red + ISP |
| GET | `/network/history?hours=4` | Historial de red |
| GET | `/network/top-talkers/` | Ranking de consumo |
| GET | `/network/top-talkers/history?hours=4` | Historial de ranking |
| GET | `/network/isp-health` | Detalle ISP health |
| GET | `/alerts/` | Listado de alertas (filtros: severity, seen) |
| GET | `/alerts/count` | Conteo de alertas |
| PATCH | `/alerts/{id}/seen` | Marcar como leida |
| POST | `/auth/invitations` | Generar token de invitacion |
| POST | `/notifications/token` | Registrar token FCM |
| DELETE | `/notifications/token` | Desregistrar token FCM |
| WS | `/ws?token=JWT` | WebSocket real-time (state_update + alert_created) |

## Configuracion del Server URL

La app permite cambiar la URL del backend desde **Settings -> Backend Server**. Esto es necesario para:

- **Emulador Android**: `http://10.0.2.2:8000` (default para desarrollo)
- **Dispositivo fisico en la misma LAN**: `http://192.168.X.X:8000`
- **Acceso remoto via Tailscale**: `http://100.X.Y.Z:8000`

La URL se persiste en FlutterSecureStorage y se carga al iniciar la app.

## Push Notifications (FCM)

La app registra automaticamente un token FCM al hacer login y lo desregistra al hacer logout. Las notificaciones llegan en todos los estados (app abierta, segundo plano, cerrada).

Flujo:
1. Login exitoso -> `FcmService.registerToken()` -> `POST /notifications/token`
2. Alerta detectada en el server -> `FCMNotifier.send_alert()` -> push al dispositivo
3. Tap en la notificacion -> navega a la pantalla de Alerts
4. Logout -> `FcmService.unregisterToken()` -> `DELETE /notifications/token`

## Setup del Proyecto

### Prerrequisitos

- Flutter SDK >= 3.11.0 ([instalacion](https://docs.flutter.dev/get-started/install))
- Android SDK con API 29+ configurado
- Dispositivo/emulador Android 10+
- Firebase project configurado (google-services.json en android/app/)

### Instalacion

```bash
# Clonar el repositorio
git clone https://github.com/Yoyagm/goatguard-app.git
cd goatguard-app

# Instalar dependencias
flutter pub get

# Verificar entorno
flutter doctor

# Ejecutar en emulador
flutter run

# Ejecutar en dispositivo fisico
flutter run -d <device_id>

# Build APK de release
flutter build apk --release

# Ejecutar tests
flutter test
```

### Acceso Remoto (Tailscale)

Para acceder al server desde fuera de la LAN:

1. Instalar Tailscale en el PC del server y en el celular (misma cuenta)
2. Obtener la IP de Tailscale del server: `tailscale ip -4`
3. En la app: Settings -> Backend Server -> `http://100.X.Y.Z:8000`
4. Funciona desde cualquier red (WiFi, datos moviles, otra LAN)

## Equipo

Proyecto Integrador III — Ingenieria de Sistemas, UPB Bucaramanga.

## Licencia

Proyecto academico — Universidad Pontificia Bolivariana, Bucaramanga.
