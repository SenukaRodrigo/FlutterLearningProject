import 'package:flutter/material.dart';

/// Holds the app's [ThemeMode] so any screen can flip it.
///
/// Starts on [ThemeMode.system] and only leaves it once the user makes a
/// choice, so the app respects the OS setting until told otherwise. The choice
/// is not persisted yet -- that belongs with the settings work in the backend
/// phase.
class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Whether the app is currently painting dark, resolving
  /// [ThemeMode.system] against the platform's own setting.
  bool isDark(BuildContext context) => switch (_themeMode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system =>
          MediaQuery.platformBrightnessOf(context) == Brightness.dark,
      };

  /// Flips to the opposite of what is on screen right now. Toggling out of
  /// [ThemeMode.system] pins an explicit mode, which is what the user means by
  /// pressing the button.
  void toggle(BuildContext context) {
    _themeMode = isDark(context) ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
