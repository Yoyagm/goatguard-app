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
┌──────────┐    TCP/UDP     ┌──────────────────┐    HTTPS/JWT    ┌──────────────┐
│  Agentes  │ ────────────► │  Backend Server   │ ◄────────────► │  App Movil   │
│ (Python)  │               │  (FastAPI + PG)   │                │  (Flutter)   │
└──────────┘               └──────────────────┘                └──────────────┘
```

## Stack Tecnologico

| Capa | Tecnologia |
|------|-----------|
| Framework | Flutter 3.11+ (Dart, null-safe) |
| UI/Theming | Material 3 + Google Fonts (Inter / JetBrains Mono) |
| Graficos | fl_chart 0.70.2 |
| Estado | Provider 6.1 |
| Storage seguro | flutter_secure_storage 9.2.4 |
| Utilidades | intl 0.19.0 (formateo fechas/numeros) |
| Target | Android 10+ (API 29+) |

## Estructura del Proyecto

```
lib/
├── config/
│   ├── constants.dart        # Umbrales de metricas y salud de red
│   ├── helpers.dart          # Funciones de color y formateo
│   └── theme.dart            # Tema oscuro: colores, tipografia, estilos
├── models/
│   ├── device.dart           # Device, DeviceType, DeviceCoverage, DeviceStatus
│   ├── agent.dart            # Agent, AgentStatus
│   ├── alert.dart            # NetworkAlert, AlertSeverity
│   └── network_metrics.dart  # NetworkMetrics, TimeSeriesPoint, TopConsumer
├── providers/
│   └── mock_data.dart        # Datos mock (TODO: reemplazar con servicios API)
├── screens/
│   ├── splash/               # Splash animado (fade + scale)
│   ├── login/                # Autenticacion JWT [RF-16]
│   ├── home/                 # Dashboard: health, metricas, agentes [RF-17]
│   ├── inventory/            # Inventario filtrable con/sin agente [RF-18]
│   ├── analytics/            # Graficos historicos por rango de tiempo [RF-17]
│   ├── alerts/               # Listado de alertas por severidad [RF-15, RF-19]
│   ├── settings/             # Perfil, notificaciones, config [RF-19]
│   ├── device_detail/        # Detalle individual de dispositivo [RF-18]
│   └── main_shell.dart       # Navegacion inferior + badge de alertas
├── widgets/
│   ├── cards/                # AgentTile, AlertTile, DeviceTile
│   ├── charts/               # LineMetricChart, BarMetricChart
│   └── common/               # HealthBar, MetricCard, ResourceBar, StatusChip
└── main.dart                 # Punto de entrada y definicion de rutas
```

## Requerimientos Funcionales Cubiertos

| RF | Nombre | Estado |
|----|--------|--------|
| RF-16 | Gestion de sesion (login, persistencia, cierre) | UI completa, auth mock |
| RF-17 | Dashboard, indicadores de red y metricas historicas | UI completa, datos mock |
| RF-18 | Inventario, detalle, alias y contextualizacion | UI completa, datos mock |
| RF-19 | Notificaciones push y listado de alertas | UI completa, sin FCM |

> **Estado actual**: Todas las pantallas estan implementadas con datos mock. Pendiente la integracion con la API REST del backend.

## Pantallas

- **Splash** — Animacion de entrada con logo GOATGuard
- **Login** — Formulario usuario/password con validacion
- **Home** — Health score circular, 4 metric cards (latencia, packet loss, jitter, DNS RT), lista de agentes, top consumers
- **Inventory** — Busqueda + filtros (All / With Agent / ARP Only / With Alerts), tiles clickeables
- **Analytics** — Selector de rango (1h/6h/24h/7d), 4 graficos de linea + barras top consumers
- **Alerts** — Filtros por severidad (critical/warning/info), badge de no leidas
- **Settings** — Perfil, config de red, toggles de notificaciones, info de seguridad, logout
- **Device Detail** — Metricas individuales del dispositivo seleccionado

## Setup del Proyecto

### Prerrequisitos

- Flutter SDK >= 3.11.0 ([instalacion](https://docs.flutter.dev/get-started/install))
- Android SDK con API 29+ configurado
- Dispositivo/emulador Android 10+

### Instalacion

```bash
# Clonar el repositorio
git clone https://github.com/Yoyagm/goatguard-app.git
cd goatguard-app

# Instalar dependencias
flutter pub get

# Verificar entorno
flutter doctor

# Ejecutar en dispositivo/emulador conectado
flutter run

# Ejecutar tests
flutter test

# Build APK de produccion
flutter build apk --release
```

## Integracion con Backend

La app consume la API REST del backend via HTTPS con autenticacion JWT.

**Endpoints principales a conectar:**

| Metodo | Ruta | Descripcion | RF |
|--------|------|-------------|-----|
| POST | `/auth/login` | Autenticacion, retorna JWT | RF-13 |
| GET | `/devices` | Inventario completo | RF-14 |
| GET | `/devices/{id}` | Detalle de dispositivo | RF-14 |
| PATCH | `/devices/{id}/alias` | Editar alias | RF-14 |
| GET | `/metrics/general` | Metricas globales de red | RF-14 |
| GET | `/metrics/endpoint/{id}` | Metricas por endpoint | RF-14 |
| GET | `/agents` | Estado de agentes | RF-14 |
| GET | `/alerts` | Listado de alertas | RF-15 |
| POST | `/notifications/register` | Registrar token FCM | RF-15 |

> Los endpoints exactos deben validarse contra la implementacion real en [goatguard-server](https://github.com/JPabloCarvajal/goatguard-server).

## Pendientes de Integracion

- [ ] Reemplazar `MockData` por servicios HTTP reales (dio/http)
- [ ] Implementar autenticacion JWT real con `flutter_secure_storage`
- [ ] Configurar Firebase Cloud Messaging para push notifications
- [ ] Agregar manejo de errores de red y estados de carga
- [ ] Implementar refresh periodico de metricas en dashboard
- [ ] Tests de integracion con API real

## Equipo

Proyecto Integrador III — Ingenieria de Sistemas, UPB Bucaramanga.

## Licencia

Proyecto academico — Universidad Pontificia Bolivariana, Bucaramanga.
