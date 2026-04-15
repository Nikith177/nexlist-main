import sys

with open('lib/shared/widgets/desktop_app_bar.dart', 'r') as f:
    text = f.read()

target = """          Expanded(
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
          ),"""

replacement = """          const Spacer(),"""

if target in text:
    text = text.replace(target, replacement)
    print("Patched successfully.")
else:
    print("Could not find Target.")

with open('lib/shared/widgets/desktop_app_bar.dart', 'w') as f:
    f.write(text)

