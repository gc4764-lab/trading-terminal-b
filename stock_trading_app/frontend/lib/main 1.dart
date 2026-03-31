import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:multi_window/multi_window.dart';
import 'package:stock_trading_app/providers/settings_provider.dart';
import 'package:stock_trading_app/screens/home_screen.dart';
import 'package:stock_trading_app/screens/multi_monitor_screen.dart';
import 'package:stock_trading_app/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window manager for multi-monitor support
  await windowManager.ensureInitialized();
  
  // Check if this is a secondary window
  await MultiWindow.ensureInitialized();
  
  final args = await MultiWindow.current.arguments;
  
  WindowOptions windowOptions = WindowOptions(
    size: const Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    minimumSize: const Size(800, 600),
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });
  
  // Handle window close event
  windowManager.onClose = () async {
    if (await MultiWindow.current.id == 'main') {
      await windowManager.hide();
      return;
    }
    await windowManager.destroy();
  };
  
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
    _checkWindowArguments();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkWindowArguments() async {
    final args = await MultiWindow.current.arguments;
    if (args != null && args.containsKey('type')) {
      // Handle secondary window
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      title: 'Stock Trading App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: AppTheme.getThemeMode(settings.theme),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      routes: {
        '/multi-monitor': (context) => const MultiMonitorScreen(),
      },
    );
  }

  @override
  void onWindowClose() async {
    // Save state before closing
    await windowManager.destroy();
  }
}