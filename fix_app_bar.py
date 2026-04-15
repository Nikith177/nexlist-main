import sys

with open('lib/shared/widgets/desktop_app_bar.dart', 'r') as f:
    text = f.read()

target = """      title: Row(
        children: [
          const Text("NEXLIST"),
          const SizedBox(width: 24),

          const Spacer(),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onPostTap,
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
      ),"""

replacement = """      title: Row(
        children: [
          // Logo (icon + wordmark)
          Row(
            children: [
              Image.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/branding/nexlist_logo_dark.png'
                    : 'assets/branding/nexlist_logo.png',
                height: 32,
              ),
              const SizedBox(width: 8),
            ],
          ),

          const SizedBox(width: 12),

          // Campus name (move it INTO header)
          const Text(
            "NIT Kurukshetra",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blueAccent,
            ),
          ),

          const Spacer(),

          // Actions
          Row(
            children: [
              IconButton(
                onPressed: onPostTap,
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
      ),"""

if target in text:
    text = text.replace(target, replacement)
    print("Replaced app bar.")
else:
    print("WARNING: app bar target not found.")

with open('lib/shared/widgets/desktop_app_bar.dart', 'w') as f:
    f.write(text)

