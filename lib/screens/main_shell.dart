import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/metrics_provider.dart';
import 'home/home_screen.dart';
import 'inventory/inventory_screen.dart';
import 'analytics/analytics_screen.dart';
import 'alerts/alerts_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  StreamSubscription<Map<String, dynamic>>? _wsAlertSub;

  final _screens = const [
    HomeScreen(),
    InventoryScreen(),
    AnalyticsScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Cargar datos después del primer frame para evitar notifyListeners durante build
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  /// Carga inicial de datos + conexión WebSocket [RF-17]
  Future<void> _loadData() async {
    final deviceProv = context.read<DeviceProvider>();
    final alertProv = context.read<AlertProvider>();
    final metricsProv = context.read<MetricsProvider>();
    final auth = context.read<AuthProvider>();

    // Cargar datos iniciales en paralelo
    await Future.wait([deviceProv.fetchDevices(), alertProv.fetchAlerts()]);

    // Métricas dependen de los agentes cargados
    await metricsProv.fetchMetrics(
      activeAgents: deviceProv.activeAgentCount,
      totalAgents: deviceProv.totalAgentCount,
      unseenAlerts: alertProv.unseenCount,
    );

    // Conectar WebSocket para real-time
    final token = await auth.getToken();
    if (token != null) {
      metricsProv.startWebSocket(token);

      // Suscribirse al stream de alertas push vía WS
      _wsAlertSub = metricsProv.wsAlerts.listen((data) {
        alertProv.addAlertFromWs(data);

        // SnackBar para alertas críticas
        final severity =
            (data['alert'] as Map<String, dynamic>?)?['severity'] as String? ??
                data['severity'] as String? ??
                '';
        if (severity == 'critical' || severity == 'high') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.critical,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                content: Text(
                  'New alert: ${(data['alert'] as Map<String, dynamic>?)?['description'] ?? 'Critical alert detected'}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () => setState(() => _currentIndex = 3),
                ),
              ),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _wsAlertSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertCount = context.watch<AlertProvider>().unseenCount;

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.navBar,
        toolbarHeight: 64,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: AppColors.brand,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOATGuard',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Juan Monsalve's Network",
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _currentIndex = 3),
              ),
              if (alertCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.critical,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.navBar, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$alertCount',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF30363D), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.devices_rounded),
              label: 'Inventory',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: alertCount > 0,
                label: Text('$alertCount', style: const TextStyle(fontSize: 9)),
                child: const Icon(Icons.notifications_rounded),
              ),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
