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
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Portal Settings & Theme',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Display Mode
            Row(
              children: [
                Icon(
                  isDark ? Icons.brightness_3 : Icons.brightness_high,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Display Mode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose between deep cosmic night or luminous celestial light.',
              style: TextStyle(color: Colors.grey[600]),
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
                Icon(Icons.palette, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Space Accent Color Scheme',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select complementary nebula and aura glowing accents.',
              style: TextStyle(color: Colors.grey[600]),
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
                Icon(Icons.highlight, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Cursor Flashlight Glow Effect',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: themeState.cursorFlashlight,
                  onChanged: (val) => themeNotifier.setCursorFlashlight(val),
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Dynamic radial ambient flashlight beam that follows mouse movement.',
              style: TextStyle(color: Colors.grey[600]),
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
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.color : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              color.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
