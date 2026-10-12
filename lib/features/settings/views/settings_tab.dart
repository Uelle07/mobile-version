import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/theme_provider.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    final isDark = themeState.displayMode == DisplayMode.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Portal Settings & Theme',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Display Mode
            Row(
              children: [
                Icon(
                  isDark ? Icons.brightness_3 : Icons.brightness_high,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Display Mode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose between deep cosmic night or luminous celestial light.',
              style: TextStyle(color: subtitleColor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    title: 'Night Mode',
                    subtitle: 'Deep Space Void',
                    icon: Icons.brightness_3,
                    isSelected: isDark,
                    onTap: () => themeNotifier.setDisplayMode(DisplayMode.dark),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ModeCard(
                    title: 'Light Mode',
                    subtitle: 'Stellar Aerospace',
                    icon: Icons.brightness_high,
                    isSelected: !isDark,
                    onTap: () =>
                        themeNotifier.setDisplayMode(DisplayMode.light),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Accent Color
            Row(
              children: [
                Icon(Icons.palette, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Space Accent Color Scheme',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select complementary nebula and aura glowing accents.',
              style: TextStyle(color: subtitleColor),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: AccentColor.values.map((color) {
                return _ColorCard(
                  color: color,
                  isSelected: themeState.accentColor == color,
                  onTap: () => themeNotifier.setAccentColor(color),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Cursor Flashlight
            Row(
              children: [
                Icon(Icons.highlight, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cursor Flashlight Glow Effect',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
                Switch(
                  value: themeState.cursorFlashlight,
                  onChanged: (val) => themeNotifier.setCursorFlashlight(val),
                  activeColor: primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Dynamic radial ambient flashlight beam that follows mouse movement.',
              style: TextStyle(color: subtitleColor),
            ),
            const SizedBox(height: 48),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings saved successfully.'),
                    ),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor:
                      ThemeData.estimateBrightnessForColor(primaryColor) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final cardBg = isSelected
        ? primary.withOpacity(0.12)
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final borderColor = isSelected
        ? primary
        : (isDark ? Colors.white12 : Colors.grey.withOpacity(0.25));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? primary : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? primary
                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorCard extends StatelessWidget {
  final AccentColor color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCard({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isSelected
        ? color.color.withOpacity(0.12)
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final borderColor = isSelected
        ? color.color
        : (isDark ? Colors.white12 : Colors.grey.withOpacity(0.25));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.color.withOpacity(0.25),
                blurRadius: 8,
                spreadRadius: 1,
              )
            else if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.color.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              color.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
