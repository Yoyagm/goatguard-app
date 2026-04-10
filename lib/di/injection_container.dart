import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/fcm_service.dart';

import '../core/ports/auth_repository.dart';
import '../core/ports/device_repository.dart';
import '../core/ports/agent_repository.dart';
import '../core/ports/alert_repository.dart';
import '../core/ports/network_repository.dart';
import '../core/ports/real_time_port.dart';
import '../core/ports/push_notification_port.dart';
import '../core/ports/token_storage_port.dart';

import '../infrastructure/adapters/token_storage_adapter.dart';
import '../infrastructure/adapters/real_time_adapter.dart';
import '../infrastructure/adapters/push_notification_adapter.dart';
import '../infrastructure/repositories/auth_repository_impl.dart';
import '../infrastructure/repositories/device_repository_impl.dart';
import '../infrastructure/repositories/agent_repository_impl.dart';
import '../infrastructure/repositories/alert_repository_impl.dart';
import '../infrastructure/repositories/network_repository_impl.dart';

import '../core/use_cases/calculate_health_score.dart';
import '../core/use_cases/auth/login_use_case.dart';
import '../core/use_cases/auth/check_auth_use_case.dart';
import '../core/use_cases/auth/complete_totp_use_case.dart';
import '../core/use_cases/auth/complete_enrollment_use_case.dart';
import '../core/use_cases/auth/logout_use_case.dart';
import '../core/use_cases/auth/register_use_case.dart';
import '../core/use_cases/devices/get_devices_use_case.dart';
import '../core/use_cases/devices/get_device_detail_use_case.dart';
import '../core/use_cases/devices/update_device_alias_use_case.dart';
import '../core/use_cases/devices/get_device_history_use_case.dart';
import '../core/use_cases/devices/get_device_connections_use_case.dart';
import '../core/use_cases/devices/get_device_comparison_use_case.dart';
import '../core/use_cases/agents/get_agents_use_case.dart';
import '../core/use_cases/alerts/get_alerts_use_case.dart';
import '../core/use_cases/alerts/get_unseen_count_use_case.dart';
import '../core/use_cases/alerts/mark_alert_seen_use_case.dart';
import '../core/use_cases/metrics/get_dashboard_metrics_use_case.dart';
import '../core/use_cases/metrics/get_network_history_use_case.dart';
import '../core/use_cases/metrics/get_isp_health_use_case.dart';
import '../core/use_cases/metrics/get_traffic_distribution_use_case.dart';
import '../core/use_cases/metrics/get_top_talkers_history_use_case.dart';
import '../core/use_cases/metrics/get_dashboard_summary_use_case.dart';

/// Dependency injection container.
///
/// Wires: Services → Adapters → Repositories → Use Cases.
/// Providers are created in main.dart using the use cases from here.
class InjectionContainer {
  // ── External services ──────────────────────────────────────────

  late final ApiService apiService;
  late final WebSocketService webSocketService;

  // ── Ports / Adapters ───────────────────────────────────────────

  late final TokenStoragePort tokenStorage;
  late final RealTimePort realTimePort;
  late final PushNotificationPort pushNotificationPort;

  // ── Repositories ───────────────────────────────────────────────

  late final AuthRepository authRepository;
  late final DeviceRepository deviceRepository;
  late final AgentRepository agentRepository;
  late final AlertRepository alertRepository;
  late final NetworkRepository networkRepository;

  // ── Use Cases ──────────────────────────────────────────────────

  late final CalculateHealthScore calculateHealthScore;

  // Auth
  late final LoginUseCase loginUseCase;
  late final CheckAuthUseCase checkAuthUseCase;
  late final CompleteTotpUseCase completeTotpUseCase;
  late final CompleteEnrollmentUseCase completeEnrollmentUseCase;
  late final LogoutUseCase logoutUseCase;
  late final RegisterUseCase registerUseCase;

  // Devices
  late final GetDevicesUseCase getDevicesUseCase;
  late final GetDeviceDetailUseCase getDeviceDetailUseCase;
  late final UpdateDeviceAliasUseCase updateDeviceAliasUseCase;
  late final GetDeviceHistoryUseCase getDeviceHistoryUseCase;
  late final GetDeviceConnectionsUseCase getDeviceConnectionsUseCase;
  late final GetDeviceComparisonUseCase getDeviceComparisonUseCase;

  // Agents
  late final GetAgentsUseCase getAgentsUseCase;

  // Alerts
  late final GetAlertsUseCase getAlertsUseCase;
  late final GetUnseenCountUseCase getUnseenCountUseCase;
  late final MarkAlertSeenUseCase markAlertSeenUseCase;

  // Metrics
  late final GetDashboardMetricsUseCase getDashboardMetricsUseCase;
  late final GetNetworkHistoryUseCase getNetworkHistoryUseCase;
  late final GetIspHealthUseCase getIspHealthUseCase;
  late final GetTrafficDistributionUseCase getTrafficDistributionUseCase;
  late final GetTopTalkersHistoryUseCase getTopTalkersHistoryUseCase;
  late final GetDashboardSummaryUseCase getDashboardSummaryUseCase;

  void init() {
    // 1. External services
    apiService = ApiService();
    webSocketService = WebSocketService();

    // 2. Adapters
    tokenStorage = TokenStorageAdapter();
    final fcmService = FcmService(apiService);
    pushNotificationPort = PushNotificationAdapter(fcmService);
    realTimePort = RealTimeAdapter(webSocketService);

    // 3. Repositories
    authRepository = AuthRepositoryImpl(apiService, tokenStorage);
    deviceRepository = DeviceRepositoryImpl(apiService);
    agentRepository = AgentRepositoryImpl(apiService);
    alertRepository = AlertRepositoryImpl(apiService);
    networkRepository = NetworkRepositoryImpl(apiService);

    // 4. Use cases
    calculateHealthScore = CalculateHealthScore();

    loginUseCase = LoginUseCase(authRepository);
    checkAuthUseCase = CheckAuthUseCase(tokenStorage);
    completeTotpUseCase = CompleteTotpUseCase(authRepository, tokenStorage);
    completeEnrollmentUseCase = CompleteEnrollmentUseCase(
      authRepository,
      tokenStorage,
    );
    logoutUseCase = LogoutUseCase(tokenStorage, pushNotificationPort);
    registerUseCase = RegisterUseCase(authRepository);

    getDevicesUseCase = GetDevicesUseCase(deviceRepository);
    getDeviceDetailUseCase = GetDeviceDetailUseCase(deviceRepository);
    updateDeviceAliasUseCase = UpdateDeviceAliasUseCase(deviceRepository);
    getDeviceHistoryUseCase = GetDeviceHistoryUseCase(deviceRepository);
    getDeviceConnectionsUseCase = GetDeviceConnectionsUseCase(deviceRepository);
    getDeviceComparisonUseCase = GetDeviceComparisonUseCase(deviceRepository);

    getAgentsUseCase = GetAgentsUseCase(agentRepository);

    getAlertsUseCase = GetAlertsUseCase(alertRepository);
    getUnseenCountUseCase = GetUnseenCountUseCase(alertRepository);
    markAlertSeenUseCase = MarkAlertSeenUseCase(alertRepository);

    getDashboardMetricsUseCase = GetDashboardMetricsUseCase(
      networkRepository,
      alertRepository,
      calculateHealthScore,
    );
    getNetworkHistoryUseCase = GetNetworkHistoryUseCase(networkRepository);
    getIspHealthUseCase = GetIspHealthUseCase(networkRepository);
    getTrafficDistributionUseCase = GetTrafficDistributionUseCase(
      networkRepository,
    );
    getTopTalkersHistoryUseCase = GetTopTalkersHistoryUseCase(
      networkRepository,
    );
    getDashboardSummaryUseCase = GetDashboardSummaryUseCase(networkRepository);
  }
}
