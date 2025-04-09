import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class AppTheme {
  // App's primary branding color
  static const Color primaryColor = Color(0xFF5E35B1); // Deep purple
  static const Color accentColor = Color(0xFF00BCD4); // Cyan
  static const Color errorColor = Color(0xFFE53935); // Red

  // Task Priority Colors
  static const Color lowPriorityColor = Color(0xFF4CAF50); // Green
  static const Color mediumPriorityColor = Color(0xFFFFC107); // Amber
  static const Color highPriorityColor = Color(0xFFE53935); // Red

  // Task status colors
  static const Color pendingStatusColor = Color(0xFF9E9E9E); // Grey
  static const Color inProgressStatusColor = Color(0xFF2196F3); // Blue
  static const Color completedStatusColor = Color(0xFF4CAF50); // Green
  static const Color overdueStatusColor = Color(0xFFE53935); // Red

  // Get color for task priority
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 0: // low
        return lowPriorityColor;
      case 1: // medium
        return mediumPriorityColor;
      case 2: // high
        return highPriorityColor;
      default:
        return mediumPriorityColor;
    }
  }

  // Get color for task status
  static Color getStatusColor(int status) {
    switch (status) {
      case 0: // pending
        return pendingStatusColor;
      case 1: // in progress
        return inProgressStatusColor;
      case 2: // completed
        return completedStatusColor;
      case 3: // overdue
        return overdueStatusColor;
      default:
        return pendingStatusColor;
    }
  }

  // Light Theme
  static ThemeData lightTheme() {
    return FlexThemeData.light(
      scheme: FlexScheme.deepPurple,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 9,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        inputDecoratorRadius: 8.0,
        inputDecoratorBorderType: FlexInputBorderType.underline,
        cardRadius: 12.0,
        popupMenuRadius: 8.0,
        bottomSheetRadius: 20.0,
        dialogRadius: 16.0,
        timePickerElementRadius: 10.0,
        chipRadius: 12.0,
        fabRadius: 16.0,
        fabUseShape: true,
        fabAlwaysCircular: true,
        bottomNavigationBarOpacity: 0.95,
        bottomNavigationBarElevation: 3.0,
        navigationBarIndicatorSchemeColor: SchemeColor.secondary,
        navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        navigationRailLabelType: NavigationRailLabelType.selected,
        navigationRailIndicatorSchemeColor: SchemeColor.secondary,
      ),
      keyColors: const FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    );
  }

  // Dark Theme
  static ThemeData darkTheme() {
    return FlexThemeData.dark(
      scheme: FlexScheme.deepPurple,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 15,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        blendOnColors: false,
        inputDecoratorRadius: 8.0,
        inputDecoratorBorderType: FlexInputBorderType.underline,
        cardRadius: 12.0,
        popupMenuRadius: 8.0,
        bottomSheetRadius: 20.0,
        dialogRadius: 16.0,
        timePickerElementRadius: 10.0,
        chipRadius: 12.0,
        fabRadius: 16.0,
        fabUseShape: true,
        fabAlwaysCircular: true,
        bottomNavigationBarOpacity: 0.95,
        bottomNavigationBarElevation: 3.0,
        navigationBarIndicatorSchemeColor: SchemeColor.secondary,
        navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        navigationRailLabelType: NavigationRailLabelType.selected,
        navigationRailIndicatorSchemeColor: SchemeColor.secondary,
      ),
      keyColors: const FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    ).copyWith(
      // Set additional dark theme customizations here
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }
} 