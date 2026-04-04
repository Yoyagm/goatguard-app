# GOATGuard — Estado de Integración Flutter ↔ Backend

> Última actualización: 2026-03-20

## Diagrama de Flujo de Datos

```
┌──────────────┐    TCP :9999     ┌─────────────────┐    SQLAlchemy    ┌────────────┐
│  goatguard-  │ ──────────────►  │  goatguard-     │ ──────────────►  │ PostgreSQL │
│  agent       │    (PCAP bin)    │  server          │                  │   :5432    │
│  (endpoint)  │                  │  (run.py)        │ ◄──────────────  │            │
│              │    UDP :9998     │  ┌─ TCP Rx       │    read/write    └────────────┘
│              │ ──────────────►  │  ├─ UDP Rx       │                        │
│              │  (metrics JSON)  │  ├─ PCAP Asm     │                        │
└──────────────┘                  │  ├─ Zeek Runner  │                        │
                                  │  ├─ ISP Probe    │                        │
                                  │  ├─ ARP Scanner  │                        │
                                  │  └─ HealthCheck  │                        │
                                  └─────────────────┘                        │
                                                                             │
                                  ┌─────────────────┐    polling 5s          │
                                  │  goatguard-     │ ◄──────────────────────┘
                                  │  server API     │
                                  │  (run_api.py)   │
                                  │  :8000          │
                                  │  ┌─ REST API    │
                                  │  └─ WS /ws      │─── broadcast ───┐
                                  └─────────────────┘                 │
                                         │ REST                       │ WS (JSON)
                                         ▼                            ▼
                                  ┌─────────────────────────────────────┐
                                  │  goatguard_app (Flutter)            │
                                  │  ┌─ ApiService (Dio + JWT)         │
                                  │  ├─ WebSocketService (reconnect)   │
                                  │  ├─ AuthProvider → LoginScreen     │
                                  │  ├─ MetricsProvider → HomeScreen   │
                                  │  ├─ DeviceProvider → Inventory     │
                                  │  └─ AlertProvider → AlertsScreen   │
                                  └─────────────────────────────────────┘
```

## Endpoints — Implementados vs Pendientes

| # | Método | Path | Implementado | Screen Flutter | RF |
|---|--------|------|:---:|---|---|
| 1 | POST | `/auth/login` | ✅ | LoginScreen | RF-13 |
| 2 | POST | `/auth/register` | ✅ | — (sin UI) | RF-13 |
| 3 | POST | `/auth/logout` | ❌ | SettingsScreen | RF-13 |
| 4 | GET | `/devices` | ✅ | InventoryScreen | RF-18 |
| 5 | GET | `/devices/{id}` | ✅ | DeviceDetailScreen | RF-18 |
| 6 | PATCH | `/devices/{id}/alias` | ✅ | DeviceDetailScreen | RF-18 |
| 7 | GET | `/network/metrics` | ✅ | HomeScreen, AnalyticsScreen | RF-17 |
| 8 | GET | `/network/top-talkers` | ✅ | HomeScreen, AnalyticsScreen | RF-09 |
| 9 | GET | `/alerts` | ✅ | AlertsScreen | RF-15 |
| 10 | GET | `/alerts/count` | ✅ | MainShell (badge) | RF-19 |
| 11 | PATCH | `/alerts/{id}/seen` | ✅ | AlertsScreen | RF-19 |
| 12 | WS | `/ws?token=JWT` | ✅ | MetricsProvider (real-time) | RF-17 |
| 13 | GET | `/agents` | ❌ | HomeScreen (workaround via devices) | RF-17 |
| 14 | GET | `/agents/{id}` | ❌ | — | — |
| 15 | GET | `/metrics/history` | ❌ | AnalyticsScreen (usa MockData) | RF-17 |
| 16 | GET | `/metrics/device/{id}` | ❌ | DeviceDetailScreen (usa MockData) | RF-17 |
| 17 | — | Push FCM | ❌ | Notificaciones background | RF-19 |

**Resumen:** 12/17 implementados (70%). Los 5 pendientes se documentan como TODOs en el código.

## Dependencias Flutter Agregadas

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `dio` | 5.9.2 | Cliente HTTP para API REST |
| `web_socket_channel` | 3.0.3 | Conexión WebSocket real-time |
| `firebase_messaging` | 16.1.2 | Push notifications (preparado, sin implementar) |
| `provider` | 6.1.2 | State management (ya existía, ahora con 4 providers) |
| `flutter_secure_storage` | 9.2.4 | Almacenamiento seguro de JWT (ya existía) |

## Archivos Creados/Modificados

### Nuevos
| Archivo | Propósito |
|---------|-----------|
| `lib/config/env.dart` | URL base configurable (dev/prod) |
| `lib/services/api_service.dart` | Cliente Dio + interceptor JWT |
| `lib/services/websocket_service.dart` | WS con backoff exponencial |
| `lib/providers/auth_provider.dart` | Estado de autenticación |
| `lib/providers/device_provider.dart` | Dispositivos + agentes |
| `lib/providers/alert_provider.dart` | Alertas + mark as seen |
| `lib/providers/metrics_provider.dart` | Métricas de red + WS listener |
| `goatguard-server/seed.py` | Datos de prueba (≡ MockData) |
| `docker-compose.yml` | PostgreSQL 15 para desarrollo local |

### Modificados
| Archivo | Cambio |
|---------|--------|
| `lib/main.dart` | MultiProvider wrapping app |
| `lib/models/device.dart` | `Device.fromJson()`, `Device.fromWsJson()` |
| `lib/models/alert.dart` | `NetworkAlert.fromJson()` con mapeo severity |
| `lib/models/network_metrics.dart` | `NetworkMetrics.fromApi()`, `TopConsumer.fromJson()`, health score calc |
| `lib/models/agent.dart` | `Agent.fromDeviceJson()` workaround |
| `lib/screens/main_shell.dart` | Provider-based data loading + WS init |
| `lib/screens/home/home_screen.dart` | MetricsProvider + DeviceProvider |
| `lib/screens/inventory/inventory_screen.dart` | DeviceProvider |
| `lib/screens/analytics/analytics_screen.dart` | MetricsProvider (TimeSeries sigue MockData) |
| `lib/screens/alerts/alerts_screen.dart` | AlertProvider + mark as seen |
| `lib/screens/device_detail/device_detail_screen.dart` | AlertProvider + alias via API |
| `lib/screens/login/login_screen.dart` | AuthProvider real login |
| `lib/screens/splash/splash_screen.dart` | Token check → auto-login |

### Intactos (por diseño)
| Archivo | Razón |
|---------|-------|
| `lib/providers/mock_data.dart` | Fallback para tests de widget y screens sin API |
| `lib/widgets/**` | Sin cambios — reciben datos por props |

## Incompatibilidades de Mapeo Resueltas

| Campo Flutter | Campo API | Transformación |
|---|---|---|
| `Device.name` | `alias` / `hostname` | `alias ?? hostname ?? "Unknown"` |
| `Device.type` | `device_type` | Enum parse con fallback `unknown` |
| `Device.coverage` | `has_agent` | `true → withAgent`, `false → arpOnly` |
| `Device.status` | `status` | `"active" → online`, resto `→ offline` |
| `NetworkAlert.title` | `anomaly_type` | snake_case → Title Case |
| `NetworkAlert.severity` | `severity` | `critical/high→critical`, `medium→warning`, `low→info` |
| `NetworkAlert.isRead` | `seen` | Rename directo |
| `TopConsumer.consumptionMbps` | `total_consumption` | `bytes × 8 / 1_000_000` |
| `NetworkMetrics.healthScore` | — | Calculado client-side (ponderado por latency, loss, jitter, dns) |

## Pasos para Levantar el Stack Local

```bash
# 1. PostgreSQL
cd /Users/johandavidrodriguezcastro/Desktop/pi3
docker compose up -d
# Verificar: docker exec goatguard-db pg_isready -U goatguard

# 2. Python venv para el server
cd goatguard-server
python3 -m venv .venv && source .venv/bin/activate
pip install fastapi uvicorn sqlalchemy psycopg2-binary bcrypt PyJWT pyyaml

# 3. API (crea tablas automáticamente)
python run_api.py &
# Verificar: curl http://localhost:8000/docs

# 4. Seed con datos de prueba
python seed.py
# Output: "Seed completado: 10 devices, 5 agents, 6 alerts..."

# 5. Registrar usuario admin (una sola vez)
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# 6. Flutter app
cd ../goatguard_app
flutter pub get
flutter run
# Login: admin / admin123
```

## Bloqueadores Conocidos

| Bloqueador | Impacto | Workaround actual |
|---|---|---|
| `GET /agents` no implementado | HomeScreen no muestra agentes directamente | Se extraen de `GET /devices/{id}` iterando devices con `has_agent=true` |
| `GET /metrics/history` no implementado | AnalyticsScreen sin gráficas reales | MockData.generateTimeSeries() como fallback |
| `GET /metrics/device/{id}` no implementado | DeviceDetailScreen sin historial | MockData.generateTimeSeries() como fallback |
| `GET /alerts` sin filtro `device_id` | DeviceDetailScreen filtra client-side | Filtra `allAlerts.where(a.deviceIp == device.ip)` |
| Push FCM no implementado | Sin notificaciones background | firebase_messaging instalado, pendiente configurar |
| `healthScore` no en API | Dashboard muestra score calculado | Fórmula ponderada client-side en `NetworkMetrics.fromApi()` |
