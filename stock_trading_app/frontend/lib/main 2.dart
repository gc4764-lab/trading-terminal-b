import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:stock_trading_app/providers/settings_provider.dart';
import 'package:stock_trading_app/screens/home_screen.dart';
import 'package:stock_trading_app/utils/theme.dart';
import 'package:stock_trading_app/utils/error_boundary.dart';
import 'package:stock_trading_app/services/ai_service.dart';
import 'package:stock_trading_app/services/market_data_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error handling
  setupErrorHandling();
  
  // Initialize Sentry for error tracking
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://your-sentry-dsn@sentry.io/project-id';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () async {
      await _initializeApp();
    },
  );
}

Future<void> _initializeApp() async {
  // Initialize window manager
  await windowManager.ensureInitialized();
  
  // Initialize services
  await CacheManager.init();
  await AIService().initialize();
  await MarketDataService().connect();
  
  // Window configuration
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    minimumSize: Size(800, 600),
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    
    return ErrorBoundary(
      child: MaterialApp(
        title: 'Stock Trading App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: AppTheme.getThemeMode(settings.theme),
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
        routes: {
          '/dashboard': (context) => const CustomizableDashboard(),
          '/multi-monitor': (context) => const MultiMonitorScreen(),
        },
      ),
    );
  }

  @override
  void onWindowClose() async {
    // Save all data before closing
    await _saveAppState();
    await windowManager.destroy();
  }
  
  Future<void> _saveAppState() async {
    // Save settings, layouts, etc.
    final settings = ref.read(settingsProvider);
    await ref.read(settingsProvider.notifier).updateSettings(settings);
  }
}