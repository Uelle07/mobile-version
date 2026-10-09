import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DisplayMode { light, dark }

enum AccentColor { nebulaCyan, solarFlare, deepPulsar, andromeda }

class ThemeState {
  final DisplayMode displayMode;
  final AccentColor accentColor;
  final bool cursorFlashlight;

  const ThemeState({
    this.displayMode = DisplayMode.dark,
    this.accentColor = AccentColor.nebulaCyan,
    this.cursorFlashlight = true,
  });

  ThemeState copyWith({
    DisplayMode? displayMode,
    AccentColor? accentColor,
    bool? cursorFlashlight,
  }) {
    return ThemeState(
      displayMode: displayMode ?? this.displayMode,
      accentColor: accentColor ?? this.accentColor,
      cursorFlashlight: cursorFlashlight ?? this.cursorFlashlight,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() => const ThemeState();

  void setDisplayMode(DisplayMode mode) {
    state = state.copyWith(displayMode: mode);
  }

  void setAccentColor(AccentColor color) {
    state = state.copyWith(accentColor: color);
  }

  void setCursorFlashlight(bool value) {
    state = state.copyWith(cursorFlashlight: value);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});

extension AccentColorExt on AccentColor {
  Color get color {
    switch (this) {
      case AccentColor.nebulaCyan:
        return const Color(0xFF00E5FF);
      case AccentColor.solarFlare:
        return const Color(0xFFFF9100);
      case AccentColor.deepPulsar:
        return const Color(0xFFD500F9);
      case AccentColor.andromeda:
        return const Color(0xFF00BFA5);
    }
  }

  String get name {
    switch (this) {
      case AccentColor.nebulaCyan:
        return 'Nebula Cyan';
      case AccentColor.solarFlare:
        return 'Solar Flare';
      case AccentColor.deepPulsar:
        return 'Deep Pulsar';
      case AccentColor.andromeda:
        return 'Andromeda';
    }
  }
}
