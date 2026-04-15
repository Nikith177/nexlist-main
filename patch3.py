import sys

with open('lib/shared/widgets/custom_bottom_nav_bar.dart', 'r') as f:
    orig = f.read()

appbar_old = """          appBar: isDesktop
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
                            onPressed: widget.onPostTap,
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

appbar_new = """          appBar: isDesktop
              ? DesktopAppBar(onPostTap: widget.onPostTap)
              : null,"""

if appbar_old in orig:
    orig = orig.replace(appbar_old, appbar_new)
else:
    print("WARNING: appbar_old not found exactly.")

# Inject import at the top
import_statement = "import 'desktop_app_bar.dart';\n"
if "import 'desktop_app_bar.dart';" not in orig:
    # Just put it under import 'package:flutter/material.dart';
    if "import 'package:go_router/go_router.dart';" in orig:
        orig = orig.replace("import 'package:go_router/go_router.dart';", "import 'package:go_router/go_router.dart';\nimport 'desktop_app_bar.dart';")
    else:
        orig = orig.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'desktop_app_bar.dart';")

with open('lib/shared/widgets/custom_bottom_nav_bar.dart', 'w') as f:
    f.write(orig)

print("Patch 3 applied successfully.")
