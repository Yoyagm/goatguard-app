import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'core/entities/device.dart';
import 'core/use_cases/auth/login_use_case.dart';
import 'core/use_cases/auth/check_auth_use_case.dart';
import 'core/use_cases/auth/complete_totp_use_case.dart';
import 'core/use_cases/auth/complete_enrollment_use_case.dart';
import 'core/use_cases/auth/logout_use_case.dart';
import 'core/use_cases/auth/register_use_case.dart';
import 'core/use_cases/devices/get_devices_use_case.dart';
import 'core/use_cases/devices/get_device_detail_use_case.dart';
import 'core/use_cases/devices/update_device_alias_use_case.dart';
import 'core/use_cases/devices/get_device_history_use_case.dart';
import 'core/use_cases/devices/get_device_connections_use_case.dart';
import 'core/use_cases/devices/get_device_comparison_use_case.dart';
import 'core/use_cases/agents/get_agents_use_case.dart';
import 'core/use_cases/alerts/get_alerts_use_case.dart';
import 'core/use_cases/alerts/get_unseen_count_use_case.dart';
import 'core/use_cases/alerts/mark_alert_seen_use_case.dart';
import 'core/use_cases/metrics/get_dashboard_metrics_use_case.dart';
import 'core/use_cases/metrics/get_network_history_use_case.dart';
import 'core/use_cases/metrics/get_isp_health_use_case.dart';
import 'core/use_cases/metrics/get_traffic_distribution_use_case.dart';
import 'core/use_cases/metrics/get_top_talkers_history_use_case.dart';
import 'core/use_cases/metrics/get_dashboard_summary_use_case.dart';
import 'core/use_cases/calculate_health_score.dart';
import 'firebase_options.dart';
import 'infrastructure/adapters/push_notification_adapter.dart';
import 'infrastructure/adapters/real_time_adapter.dart';
import 'infrastructure/adapters/token_storage_adapter.dart';
import 'infrastructure/repositories/auth_repository_impl.dart';
import 'infrastructure/repositories/device_repository_impl.dart';
import 'infrastructure/repositories/agent_repository_impl.dart';
import 'infrastructure/repositories/alert_repository_impl.dart';
import 'infrastructure/repositories/network_repository_impl.dart';
import 'config/env.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'services/websocket_service.dart';
import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/metrics_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/totp_verify_screen.dart';
import 'screens/auth/totp_enroll_screen.dart';
import 'screens/main_shell.dart';
import 'screens/device_detail/device_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.navBar,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Cargar URL del server guardada (o usar default)
  await Env.load();

  // --- Infrastructure (services + adapters) ---------------------------------
  final apiService = ApiService();
  final wsService = WebSocketService();
  final fcmService = FcmService(apiService);
  final tokenStorage = TokenStorageAdapter();
  final pushNotificationPort = PushNotificationAdapter(fcmService);
  final realTimePort = RealTimeAdapter(wsService);

  // --- Repositories ----------------------------------------------------------
  final authRepository = AuthRepositoryImpl(apiService, tokenStorage);
  final deviceRepository = DeviceRepositoryImpl(apiService);
  final agentRepository = AgentRepositoryImpl(apiService);
  final alertRepository = AlertRepositoryImpl(apiService);
  final networkRepository = NetworkRepositoryImpl(apiService);

  // --- Use Cases -------------------------------------------------------------
  final loginUseCase = LoginUseCase(authRepository);
  final checkAuthUseCase = CheckAuthUseCase(tokenStorage);
  final completeTotpUseCase = CompleteTotpUseCase(authRepository, tokenStorage);
  final completeEnrollmentUseCase = CompleteEnrollmentUseCase(
    authRepository,
    tokenStorage,
  );
  final logoutUseCase = LogoutUseCase(tokenStorage, pushNotificationPort);
  final registerUseCase = RegisterUseCase(authRepository);

  final getDevicesUseCase = GetDevicesUseCase(deviceRepository);
  final getDeviceDetailUseCase = GetDeviceDetailUseCase(deviceRepository);
  final updateDeviceAliasUseCase = UpdateDeviceAliasUseCase(deviceRepository);
  final getDeviceHistoryUseCase = GetDeviceHistoryUseCase(deviceRepository);
  final getDeviceConnectionsUseCase = GetDeviceConnectionsUseCase(
    deviceRepository,
  );
  final getDeviceComparisonUseCase = GetDeviceComparisonUseCase(
    deviceRepository,
  );
  final getAgentsUseCase = GetAgentsUseCase(agentRepository);

  final getAlertsUseCase = GetAlertsUseCase(alertRepository);
  final getUnseenCountUseCase = GetUnseenCountUseCase(alertRepository);
  final markAlertSeenUseCase = MarkAlertSeenUseCase(alertRepository);

  final calculateHealthScore = CalculateHealthScore();
  final getDashboardMetricsUseCase = GetDashboardMetricsUseCase(
    networkRepository,
    alertRepository,
    calculateHealthScore,
  );
  final getNetworkHistoryUseCase = GetNetworkHistoryUseCase(networkRepository);
  final getIspHealthUseCase = GetIspHealthUseCase(networkRepository);
  final getTrafficDistributionUseCase = GetTrafficDistributionUseCase(
    networkRepository,
  );
  final getTopTalkersHistoryUseCase = GetTopTalkersHistoryUseCase(
    networkRepository,
  );
  final getDashboardSummaryUseCase = GetDashboardSummaryUseCase(
    networkRepository,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            loginUseCase: loginUseCase,
            checkAuthUseCase: checkAuthUseCase,
            completeTotpUseCase: completeTotpUseCase,
            completeEnrollmentUseCase: completeEnrollmentUseCase,
            logoutUseCase: logoutUseCase,
            registerUseCase: registerUseCase,
            authRepository: authRepository,
            pushNotificationPort: pushNotificationPort,
            tokenStorage: tokenStorage,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DeviceProvider(
            getDevicesUseCase: getDevicesUseCase,
            getAgentsUseCase: getAgentsUseCase,
            getDeviceDetailUseCase: getDeviceDetailUseCase,
            updateDeviceAliasUseCase: updateDeviceAliasUseCase,
            getDeviceHistoryUseCase: getDeviceHistoryUseCase,
            getDeviceConnectionsUseCase: getDeviceConnectionsUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertProvider(
            getAlertsUseCase: getAlertsUseCase,
            getUnseenCountUseCase: getUnseenCountUseCase,
            markAlertSeenUseCase: markAlertSeenUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MetricsProvider(
            getDashboardMetricsUseCase: getDashboardMetricsUseCase,
            getNetworkHistoryUseCase: getNetworkHistoryUseCase,
            getIspHealthUseCase: getIspHealthUseCase,
            getTrafficDistributionUseCase: getTrafficDistributionUseCase,
            getTopTalkersHistoryUseCase: getTopTalkersHistoryUseCase,
            getDashboardSummaryUseCase: getDashboardSummaryUseCase,
            getDeviceComparisonUseCase: getDeviceComparisonUseCase,
            networkRepository: networkRepository,
            realTimePort: realTimePort,
            apiService: apiService,
          ),
        ),
      ],
      child: const GoatGuardApp(),
    ),
  );
}

class GoatGuardApp extends StatelessWidget {
  const GoatGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GOATGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/totp-verify': (_) => const TotpVerifyScreen(),
        '/main': (_) => const MainShell(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/totp-enroll') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => TotpEnrollScreen(
              totpUri: args['totp_uri'] as String? ?? '',
              qrBase64: args['qr_base64'] as String? ?? '',
            ),
          );
        }
        if (settings.name == '/device') {
          final device = settings.arguments as DeviceEntity;
          return MaterialPageRoute(
            builder: (_) => DeviceDetailScreen(device: device),
          );
        }
        return null;
      },
    );
  }
}
