import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme.dart';
import 'models/device.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
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
  runApp(const GoatGuardApp());
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
        '/main': (_) => const MainShell(),
      },
      onGenerateRoute: (settings) {
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
