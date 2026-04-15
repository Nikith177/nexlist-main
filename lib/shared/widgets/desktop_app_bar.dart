import 'package:flutter/material.dart';

import '../utils/navigation_trace_utils.dart';

class DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onPostTap;
  final int currentIndex;
  final Function(int) onNavTap;

  const DesktopAppBar({
    super.key,
    required this.onPostTap,
    required this.currentIndex,
    required this.onNavTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          // Logo + College Name (LEFT)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/branding/nexlist_logo_dark.png'
                    : 'assets/branding/nexlist_logo.png',
                height: 32,
              ),
              const SizedBox(width: 12),
              const Text(
                "NIT Kurukshetra",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),

          // Navigation (CENTER)
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavItem(
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    onTap: () => onNavTap(0),
                  ),
                  _NavItem(
                    label: 'Services',
                    isSelected: currentIndex == 1,
                    onTap: () => onNavTap(1),
                  ),
                  _NavItem(
                    label: 'Requests',
                    isSelected: currentIndex == 2,
                    onTap: () => onNavTap(2),
                  ),
                ],
              ),
            ),
          ),

          // Actions (RIGHT)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: onPostTap, icon: const Icon(Icons.add)),
              IconButton(
                onPressed: () => context.tracedPush('/notifications'),
                icon: const Icon(Icons.notifications_outlined),
              ),
              IconButton(
                onPressed: () => onNavTap(3), // mapped to Profile index 3
                icon: const Icon(Icons.person_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          foregroundColor: isSelected
              ? colors.primary
              : colors.onSurface.withValues(alpha: 0.6),
          backgroundColor: isSelected
              ? colors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
