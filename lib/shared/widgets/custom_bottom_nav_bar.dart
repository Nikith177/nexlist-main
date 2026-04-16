import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'desktop_app_bar.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onPostTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: isDark ? colors.surface : Colors.white,
        elevation: 0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavBarItem(
              icon: Icons.handshake_rounded,
              label: 'Services',
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            const SizedBox(width: 48), // Space for FAB
            _NavBarItem(
              icon: currentIndex == 2 ? Icons.help : Icons.help_outline,
              label: 'Requests',
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavBarItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colors.primary
                    : colors.onSurfaceVariant,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Notification to control FAB visibility from child screens
class FABVisibilityNotification extends Notification {
  final bool isSheetOpen;
  const FABVisibilityNotification(this.isSheetOpen);
}

// Wrapper for screens with the FAB
class ScaffoldWithNavBar extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onNavTap;
  final VoidCallback onPostTap;

  const ScaffoldWithNavBar({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onNavTap,
    required this.onPostTap,
  });

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  bool _isSheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return NotificationListener<FABVisibilityNotification>(
      onNotification: (notification) {
        setState(() {
          _isSheetOpen = notification.isSheetOpen;
        });
        return true;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
            return;
          }

          if (widget.currentIndex != 0) {
            widget.onNavTap(0);
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: isDesktop
              ? DesktopAppBar(
                  onPostTap: widget.onPostTap,
                  currentIndex: widget.currentIndex,
                  onNavTap: (index) {
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) {
                      navigator.pop();
                    }
                    widget.onNavTap(index);
                  },
                )
              : null,
          body: widget.body,
          floatingActionButton: isDesktop
              ? null 
              : _isSheetOpen
                  ? null
                  : FloatingActionButton(
                  onPressed: widget.onPostTap,
                  backgroundColor: colors.primary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.add,
                    color: colors.onPrimary,
                    size: 32,
                  ),
                ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: isDesktop ? null : CustomBottomNavBar(
            currentIndex: widget.currentIndex,
            onTap: (index) {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              }
              widget.onNavTap(index);
            },
            onPostTap: widget.onPostTap,
          ),
        ),
      ),
    );
  }
}
