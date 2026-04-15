import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

# Fix 1: Hide logo on desktop
logo_target = """                              SizedBox(
                                height: 34,
                                child: Image.asset(
                                  logoAsset,
                                  height: 34,
                                  fit: BoxFit.contain,
                                ),
                              ),"""

logo_replacement = """                              if (!isDesktop) ...[
                                SizedBox(
                                  height: 34,
                                  child: Image.asset(
                                    logoAsset,
                                    height: 34,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],"""

if logo_target in text:
    text = text.replace(logo_target, logo_replacement)
else:
    print("WARNING: logo_target not found.")


# Fix 2: Reduce header height
padding_target = """                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        12.0,
                        16.0,
                        16.0,
                      ),"""

padding_replacement = """                    child: Padding(
                      padding: isDesktop
                          ? const EdgeInsets.fromLTRB(16, 8, 16, 12)
                          : const EdgeInsets.fromLTRB(16, 12, 16, 16),"""

if padding_target in text:
    text = text.replace(padding_target, padding_replacement)
else:
    print("WARNING: padding_target not found.")


# Fix 3: Add Space Between Search & Filters
# Search bar ends before the list of Header widgets closing.
# I will locate the end of the search bar TextField. Here is the block:
search_target = """                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),"""

search_replacement = """                              },
                            ),
                          ),
                          if (isDesktop) const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),"""

if search_target in text:
    text = text.replace(search_target, search_replacement)
else:
    print("WARNING: search_target not found.")


with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(text)

print("Home screen UI patched successfully.")
