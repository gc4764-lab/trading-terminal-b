import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class AppTheme {
  static ThemeData lightTheme = FlexThemeData.light(
    scheme: FlexScheme.blue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
      useM2StyleVox: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    fontFamily: 'Roboto',
  );

  static ThemeData darkTheme = FlexThemeData.dark(
    scheme: FlexScheme.blue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 13,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
      useM2StyleVox: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    fontFamily: 'Roboto',
  );

  static ThemeMode getThemeMode(String themeMode) {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}