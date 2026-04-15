import sys

with open('lib/shared/widgets/custom_bottom_nav_bar.dart', 'r') as f:
    orig = f.read()

# First we need to add the go_router import
if "import 'package:go_router/go_router.dart';" not in orig:
    orig = orig.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:go_router/go_router.dart';")

# Now let's inject isDesktop in build:
#   Widget build(BuildContext context) {
#     final theme = Theme.of(context);
#     final colors = theme.colorScheme;
#     final isDesktop = MediaQuery.of(context).size.width >= 800;

orig = orig.replace(
    "final colors = theme.colorScheme;",
    "final colors = theme.colorScheme;\n    final isDesktop = MediaQuery.of(context).size.width >= 800;"
)

# Now modify Scaffold:
scaffold_old = """        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,"""

scaffold_new = """        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: (isDesktop && widget.currentIndex == 0)
              ? AppBar(
                  automaticallyImplyLeading: false,
                  titleSpacing: 16,
                  title: Row(
                    children: [
                      const Text("NEXLIST"),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => context.go('/home'),
                              child: const Text("Home"),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () => context.go('/services'),
                              child: const Text("Services"),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () => context.go('/requests'),
                              child: const Text("Requests"),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_outlined),
                          ),
                          IconButton(
                            onPressed: () => context.go('/profile'),
                            icon: const Icon(Icons.person_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : null,"""

orig = orig.replace(scaffold_old, scaffold_new)

# Modify FAB
fab_old = """          floatingActionButton: _isSheetOpen
              ? null
              : FloatingActionButton"""

fab_new = """          floatingActionButton: (isDesktop && widget.currentIndex == 0)
              ? null 
              : _isSheetOpen
                  ? null
                  : FloatingActionButton"""

orig = orig.replace(fab_old, fab_new)

# Modify Bottom Nav
nav_old = """          bottomNavigationBar: CustomBottomNavBar("""

nav_new = """          bottomNavigationBar: (isDesktop && widget.currentIndex == 0) ? null : CustomBottomNavBar("""

orig = orig.replace(nav_old, nav_new)

with open('lib/shared/widgets/custom_bottom_nav_bar.dart', 'w') as f:
    f.write(orig)

print("Patched structure.")
