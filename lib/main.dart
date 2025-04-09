import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/task_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:task_manager_app/screens/settings_screen.dart';
import 'package:task_manager_app/services/notification_service.dart';
import 'package:task_manager_app/services/location_service.dart';
import 'screens/landing_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize shared preferences (if needed elsewhere, keep it)
  // await SharedPreferences.getInstance();

  // Initialize services
  await NotificationService().init();
  await LocationService().init();
  
  // Determine if running in web mode
  final bool isWeb = kIsWeb;

  runApp(TaskManagerApp(isWebMode: isWeb));
}

class TaskManagerApp extends StatelessWidget {
  final bool isWebMode;
  
  const TaskManagerApp({super.key, required this.isWebMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider(isWebMode: isWebMode)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Task Manager Pro',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const LandingScreen(),
            // Define routes if you prefer named routes
            // routes: {
            //   '/': (context) => const LandingScreen(),
            //   '/home': (context) => const HomeScreen(),
            //   // Add other routes if needed
            // },
          );
        },
      ),
    );
  }
}
