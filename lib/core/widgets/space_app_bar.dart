import 'package:flutter/material.dart';

class SpaceAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double elevation;
  final Color? backgroundColor;

  const SpaceAppBar({
    Key? key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation = 0,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final barBg =
        backgroundColor ??
        Theme.of(context).appBarTheme.backgroundColor ??
        defaultBg;
    final primaryColor = Theme.of(context).primaryColor;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final iconColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return AppBar(
      backgroundColor: barBg,
      elevation: elevation,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      iconTheme: IconThemeData(color: iconColor),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/space_brand_logo.png',
            height: 32,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.rocket, color: primaryColor),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SPACE',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'COOPERATIVE PORTAL',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
