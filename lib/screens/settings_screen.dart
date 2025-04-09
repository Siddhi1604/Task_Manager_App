import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationService = NotificationService();
    final locationService = LocationService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: ListView(
            children: [
              // Appearance settings
              const _SectionHeader(title: 'Appearance'),
              
              SwitchListTile(
                title: const Text('Dark mode'),
                subtitle: const Text('Use dark theme'),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              
              SwitchListTile(
                title: const Text('System theme'),
                subtitle: const Text('Follow system theme settings'),
                value: themeProvider.themeMode == ThemeMode.system,
                onChanged: (value) {
                  themeProvider.setThemeMode(value ? ThemeMode.system : 
                    themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              
              SwitchListTile(
                title: const Text('Material 3'),
                subtitle: const Text('Use Material 3 design system'),
                value: themeProvider.useMaterial3,
                onChanged: (value) {
                  themeProvider.toggleMaterial3();
                },
              ),
              
              // Notification settings
              const _SectionHeader(title: 'Notifications'),
              
              ListTile(
                title: const Text('Notification permissions'),
                subtitle: const Text('Request notification permissions'),
                trailing: IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () async {
                    await notificationService.requestPermissions();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification permissions requested')),
                      );
                    }
                  },
                ),
              ),
              
              ListTile(
                title: const Text('Test notification'),
                subtitle: const Text('Send a test notification'),
                trailing: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    await notificationService.showNotification(
                      id: 0,
                      title: 'Test Notification',
                      body: 'This is a test notification from Task Manager',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test notification sent')),
                      );
                    }
                  },
                ),
              ),
              
              // Location settings
              const _SectionHeader(title: 'Location'),
              
              ListTile(
                title: const Text('Location permissions'),
                subtitle: const Text('Request location permissions'),
                trailing: IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: () async {
                    final result = await locationService.init();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result
                              ? 'Location permissions granted'
                              : 'Location permissions denied',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              
              // About section
              const _SectionHeader(title: 'About'),
              
              ListTile(
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
              ),
              
              ListTile(
                title: const Text('Developer'),
                subtitle: const Text('Comprehensive Task Manager'),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('About'),
                        content: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Task Manager with Reminders'),
                              SizedBox(height: 8),
                              Text('Version: 1.0.0'),
                              SizedBox(height: 8),
                              Text('A comprehensive task management app with advanced features.'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CLOSE'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Actions
              const _SectionHeader(title: 'Actions'),
              
              ListTile(
                title: const Text('Reset All Settings'),
                subtitle: const Text('Reset all settings to default values'),
                trailing: IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset Settings'),
                        content: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: const Text('Are you sure you want to reset all settings to default values?'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Reset theme settings
                              themeProvider.setThemeMode(ThemeMode.system);
                              
                              Navigator.pop(context);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Settings reset to defaults')),
                              );
                            },
                            child: const Text('RESET'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 