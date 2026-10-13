import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _keyDisplayMode = 'theme_display_mode';
  static const _keyAccentColor = 'theme_accent_color';
  static const _keyFlashlight = 'theme_cursor_flashlight';

  @override
  ThemeState build() {
    _loadPreferences();
    final sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadFromFirestore(user.uid);
      }
    });
    ref.onDispose(sub.cancel);
    return const ThemeState();
  }

  DisplayMode? _parseDisplayMode(String? modeStr) {
    if (modeStr == null) return null;
    for (final m in DisplayMode.values) {
      if (m.name == modeStr) return m;
    }
    return null;
  }

  AccentColor? _parseAccentColor(String? colorStr) {
    if (colorStr == null) return null;
    for (final c in AccentColor.values) {
      if (c.name == colorStr) return c;
    }
    return null;
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_keyDisplayMode);
      final colorStr = prefs.getString(_keyAccentColor);
      final flashlight = prefs.getBool(_keyFlashlight);

      state = state.copyWith(
        displayMode: _parseDisplayMode(modeStr),
        accentColor: _parseAccentColor(colorStr),
        cursorFlashlight: flashlight,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _loadFromFirestore(user.uid);
      }
    } catch (_) {}
  }

  Future<void> _loadFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_settings')
          .doc(uid)
          .get();
      if (!doc.exists || doc.data() == null) return;
      final data = doc.data()!;
      final mode = _parseDisplayMode(data['display_mode']?.toString());
      final color = _parseAccentColor(data['accent_color']?.toString());
      final flashlight = data['cursor_flashlight'] is bool
          ? data['cursor_flashlight'] as bool
          : null;

      state = state.copyWith(
        displayMode: mode,
        accentColor: color,
        cursorFlashlight: flashlight,
      );
    } catch (_) {}
  }

  void setDisplayMode(DisplayMode mode) {
    state = state.copyWith(displayMode: mode);
    _saveString(_keyDisplayMode, mode.name);
    saveToFirestore();
  }

  void setAccentColor(AccentColor color) {
    state = state.copyWith(accentColor: color);
    _saveString(_keyAccentColor, color.name);
    saveToFirestore();
  }

  void setCursorFlashlight(bool value) {
    state = state.copyWith(cursorFlashlight: value);
    _saveBool(_keyFlashlight, value);
    saveToFirestore();
  }

  Future<void> saveToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('user_settings')
          .doc(user.uid)
          .set({
            'user_id': user.uid,
            'display_mode': state.displayMode.name,
            'accent_color': state.accentColor.name,
            'cursor_flashlight': state.cursorFlashlight,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
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
