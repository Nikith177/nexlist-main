import 'package:flutter/material.dart';

class AppContentWrapper extends StatelessWidget {
  final Widget child;

  const AppContentWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Mobile → no constraint
    if (width < 900) {
      return child;
    }

    // Desktop / Tablet → constrained
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: child,
      ),
    );
  }
}
