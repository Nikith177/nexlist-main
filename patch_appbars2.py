import sys

filepath = 'lib/features/services/presentation/services_screen.dart'
with open(filepath, 'r') as f:
    text = f.read()

target = """      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Services',
          style: AppTypography.h2.copyWith(color: colors.onSurface),
        ),
        centerTitle: true,
      ),"""

replacement = """      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: MediaQuery.of(context).size.width >= 800
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                color: colors.onSurface,
                onPressed: () => context.go('/home'),
              )
            : null,
        title: Text(
          'Services',
          style: AppTypography.h2.copyWith(color: colors.onSurface),
        ),
        centerTitle: true,
      ),"""

if target in text:
    text = text.replace(target, replacement)
    with open(filepath, 'w') as f:
        f.write(text)
    print(f"Patched {filepath} safely.")
else:
    print(f"target not found in {filepath}!")
