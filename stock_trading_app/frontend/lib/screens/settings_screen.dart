import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Appearance',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Theme'),
                subtitle: const Text('Choose application theme'),
                trailing: DropdownButton<String>(
                  value: settings.theme,
                  items: const [
                    DropdownMenuItem(value: 'light', child: Text('Light')),
                    DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    DropdownMenuItem(value: 'system', child: Text('System')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).setTheme(value);
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Font Size'),
                subtitle: const Text('Adjust text size'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (settings.fontSize > 10) {
                          ref.read(settingsProvider.notifier).setFontSize(settings.fontSize - 1);
                        }
                      },
                    ),
                    Text('${settings.fontSize}'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (settings.fontSize < 24) {
                          ref.read(settingsProvider.notifier).setFontSize(settings.fontSize + 1);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Data & Sync',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Auto Refresh'),
                subtitle: const Text('Automatically refresh data'),
                value: settings.autoRefresh,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setAutoRefresh(value);
                },
              ),
              if (settings.autoRefresh)
                ListTile(
                  title: const Text('Refresh Rate'),
                  subtitle: const Text('Seconds between refreshes'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (settings.refreshRate > 1) {
                            ref.read(settingsProvider.notifier).setRefreshRate(settings.refreshRate - 1);
                          }
                        },
                      ),
                      Text('${settings.refreshRate}s'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (settings.refreshRate < 60) {
                            ref.read(settingsProvider.notifier).setRefreshRate(settings.refreshRate + 1);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Enable push notifications'),
                value: settings.notifications,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setNotifications(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Data Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Clear Cache'),
                subtitle: const Text('Remove cached data'),
                trailing: const Icon(Icons.delete),
                onTap: () => _showClearCacheDialog(context),
              ),
              ListTile(
                title: const Text('Export Data'),
                subtitle: const Text('Export all trading data'),
                trailing: const Icon(Icons.download),
                onTap: () => _exportData(),
              ),
              ListTile(
                title: const Text('Reset Settings'),
                subtitle: const Text('Reset to default settings'),
                trailing: const Icon(Icons.refresh),
                onTap: () => _resetSettings(ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Clear cache logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // Export data logic
  }

  void _resetSettings(WidgetRef ref) {
    ref.read(settingsProvider.notifier).updateSettings(Settings.defaultSettings());
    ScaffoldMessenger.of(ref.context!).showSnackBar(
      const SnackBar(content: Text('Settings reset to default')),
    );
  }
}