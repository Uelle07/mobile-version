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
    return AppBar(
      backgroundColor:
          backgroundColor ??
          Theme.of(context).appBarTheme.backgroundColor ??
          const Color(0xFF13172E),
      elevation: elevation,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/space_brand_logo.png',
            height: 32,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.rocket, color: Colors.pinkAccent),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SPACE',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary, // Typically pink/primary color
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'COOPERATIVE PORTAL',
                style: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                      Colors.white70,
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
