import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:stock_trading_app/providers/settings_provider.dart';
import 'package:stock_trading_app/screens/home_screen.dart';
import 'package:stock_trading_app/screens/monitoring_dashboard.dart';
import 'package:stock_trading_app/services/compliance_service.dart';
import 'package:stock_trading_app/services/backup_service.dart';
import 'package:stock_trading_app/services/ml_prediction_service.dart';
import 'package:stock_trading_app/utils/performance_optimizer.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error handling
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://your-dsn@sentry.io/project-id';
      options.tracesSampleRate = 1.0;
      options.environment = const String.fromEnvironment('ENV', defaultValue: 'production');
    },
    appRunner: () async {
      await _initializeApp();
    },
  );
}

Future<void> _initializeApp() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize services
  await ComplianceService.initialize();
  await BackupService.scheduleBackups();
  await MLPredictionService().initialize();
  
  // Initialize window manager
  await windowManager.ensureInitialized();
  
  // Configure window
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1400, 900),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    minimumSize: Size(1024, 768),
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
    await windowManager.setTitle('Stock Trading Platform');
  });
  
  // Apply performance optimizations
  PerformanceOptimizer.optimizeApp();
  
  runApp(const ProviderScope(child: StockTradingApp()));
}

class StockTradingApp extends ConsumerStatefulWidget {
  const StockTradingApp({super.key});

  @override
  ConsumerState<StockTradingApp> createState() => _StockTradingAppState();
}

class _StockTradingAppState extends ConsumerState<StockTradingApp> with WindowListener {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _logAppLaunch();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _logAppLaunch() async {
    await _analytics.logEvent(
      name: 'app_launch',
      parameters: {
        'version': '1.0.0',
        'platform': Platform.operatingSystem,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      title: 'Stock Trading Platform',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: AppTheme.getThemeMode(settings.theme),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      routes: {
        '/monitoring': (context) => const MonitoringDashboard(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/compliance': (context) => const ComplianceScreen(),
      },
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: _analytics),
      ],
    );
  }

  @override
  void onWindowClose() async {
    // Perform cleanup
    await _saveState();
    await _analytics.logEvent(name: 'app_close');
    await windowManager.destroy();
  }
  
  Future<void> _saveState() async {
    // Save all app state
    final settings = ref.read(settingsProvider);
    await ref.read(settingsProvider.notifier).updateSettings(settings);
    
    // Create final backup
    await BackupService.createBackup();
  }
}