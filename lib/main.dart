import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Widget app = const CooperativeApp();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      app = MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Firebase Initialization Error:\n\n$e\n\nYou are missing google-services.json in your android/app folder!',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
        ),
      );
    }
  }
  
  runApp(
    ProviderScope(
      child: app,
    ),
  );
}

class CooperativeApp extends ConsumerWidget {
  const CooperativeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(appRouterProvider);
    final themeState = ref.watch(themeProvider);

    final isDark = themeState.displayMode == DisplayMode.dark;
    final primaryColor = themeState.accentColor.color;

    final themeData = ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E293B) : primaryColor,
        foregroundColor: Colors.white,
      ),
    );

    return MaterialApp.router(
      title: 'Cooperative Member Portal',
      theme: themeData,
      routerConfig: goRouter,
    );
  }
}
