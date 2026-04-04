import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'models/device.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/metrics_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/register_screen.dart';
import 'screens/login/recovery_code_screen.dart';
import 'screens/login/forgot_password_screen.dart';
import 'screens/totp/totp_screen.dart';
import 'screens/totp/totp_enrollment_screen.dart';
import 'screens/totp/backup_codes_screen.dart';
import 'screens/main_shell.dart';
import 'screens/device_detail/device_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
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
        '/totp': (_) => const TotpScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/main': (_) => const MainShell(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/device':
            final device = settings.arguments as Device;
            return MaterialPageRoute(
              builder: (_) => DeviceDetailScreen(device: device),
            );
          case '/recovery-code':
            final code = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => RecoveryCodeScreen(recoveryCode: code),
            );
          case '/totp-enrollment':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => TotpEnrollmentScreen(
                totpUri: args['totp_uri']!,
                qrPngBase64: args['qr_png_base64']!,
              ),
            );
          case '/backup-codes':
            final codes = settings.arguments as List<String>;
            return MaterialPageRoute(
              builder: (_) => BackupCodesScreen(backupCodes: codes),
            );
        }
        return null;
      },
    );
  }
}
