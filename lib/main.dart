import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'firebase_options.dart';
import 'models/device.dart';
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

  final apiService = ApiService();
  final wsService = WebSocketService();
  final fcmService = FcmService(apiService);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService, fcmService),
        ),
        ChangeNotifierProvider(create: (_) => DeviceProvider(apiService)),
        ChangeNotifierProvider(create: (_) => AlertProvider(apiService)),
        ChangeNotifierProvider(
          create: (_) => MetricsProvider(apiService, wsService),
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
          final device = settings.arguments as Device;
          return MaterialPageRoute(
            builder: (_) => DeviceDetailScreen(device: device),
          );
        }
        return null;
      },
    );
  }
}
