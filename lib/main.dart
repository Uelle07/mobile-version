import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // Force sign out to ensure the app always starts at the login page
    // as requested (clearing any cached admin/member sessions).
    await FirebaseAuth.instance.signOut();
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

  runApp(ProviderScope(child: app));
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
        primary: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      cardColor: isDark ? const Color(0xFF13172E) : Colors.white,
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF13172E) : Colors.white,
        elevation: isDark ? 2 : 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF13172E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF13172E) : Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
        selectedIconTheme: IconThemeData(color: primaryColor),
        unselectedIconTheme: IconThemeData(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor:
              ThemeData.estimateBrightnessForColor(primaryColor) ==
                      Brightness.dark
                  ? Colors.white
                  : const Color(0xFF0F172A),
        ),
      ),
    );

    return MaterialApp.router(
      title: 'Cooperative Member Portal',
      theme: themeData,
      routerConfig: goRouter,
      builder: (context, child) {
        return _CursorFlashlightOverlay(
          enabled: themeState.cursorFlashlight,
          primaryColor: primaryColor,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _CursorFlashlightOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Color primaryColor;

  const _CursorFlashlightOverlay({
    required this.child,
    required this.enabled,
    required this.primaryColor,
  });

  @override
  State<_CursorFlashlightOverlay> createState() =>
      _CursorFlashlightOverlayState();
}

class _CursorFlashlightOverlayState extends State<_CursorFlashlightOverlay> {
  Offset _pointerPos = Offset.zero;
  bool _hasPointer = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return MouseRegion(
      onHover: (event) {
        if (mounted) {
          setState(() {
            _pointerPos = event.position;
            _hasPointer = true;
          });
        }
      },
      onExit: (_) {
        if (mounted) setState(() => _hasPointer = false);
      },
      child: Listener(
        onPointerMove: (event) {
          if (mounted) {
            setState(() {
              _pointerPos = event.position;
              _hasPointer = true;
            });
          }
        },
        onPointerUp: (_) {
          if (mounted) setState(() => _hasPointer = false);
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            widget.child,
            if (_hasPointer)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _FlashlightPainter(
                      position: _pointerPos,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FlashlightPainter extends CustomPainter {
  final Offset position;
  final Color color;

  _FlashlightPainter({required this.position, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (position.dx / size.width) * 2 - 1,
          (position.dy / size.height) * 2 - 1,
        ),
        radius: 0.25,
        colors: [
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_FlashlightPainter oldDelegate) =>
      oldDelegate.position != position || oldDelegate.color != color;
}
