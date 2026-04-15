import re

with open("lib/features/listing/presentation/listing_detail_screen.dart", "r") as f:
    text = f.read()

# I need to find the `Widget _buildServiceBottomBar({` and insert `  }\n\n` before it, and also the `_buildServiceLayout` method!

service_layout = """
  Widget _buildServiceLayout({
    required Map<String, dynamic> data,
    required String sellerId,
    required String? imageUrl,
    required String category,
    required String title,
    required String description,
    required String displayLocation,
  }) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl != 'placeholder')
            SizedBox(
              height: 280,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: colors.surfaceContainerHighest),
                errorWidget: (context, url, err) => Container(color: colors.surfaceContainerHighest, child: const Icon(Icons.broken_image)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h1.copyWith(color: colors.onSurface)),
                const SizedBox(height: 8),
                if (displayLocation.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: colors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(displayLocation, style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                const SizedBox(height: 24),
                Text('Description', style: AppTypography.h3.copyWith(color: colors.onSurface)),
                const SizedBox(height: 8),
                Text(description, style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

"""

# At the end of my previous script, I attached post_scaffold directly after `          }}\n`.
# So we have `          }}\nWidget _buildServiceBottomBar`

# We need to replace `          }\nWidget _buildServiceBottomBar` with `          }\n        );\n      }\n    );\n  }\n` + layout + `Widget ...`
# Let's cleanly find the exact split.
# Let's search for `return _buildMobileLayout();\n          }\nWidget _buildServiceBottomBar({`
# Actually it could have `          }\nWidget _buildServiceBottomBar` or `          }\n\nWidget _buildServiceBottomBar`

idx = text.find("return _buildMobileLayout();\n          }")
if idx != -1:
    end_bracket_idx = idx + len("return _buildMobileLayout();\n          }")
    
    # We need to close:
    # 1. build method is expecting `}`?
    # Wait, the scaffold was inside:
    # return Scaffold( ... body: Center(child: LayoutBuilder(builder: (context, constraints) { ...
    # Wait, my script OVERWROTE FROM `return Scaffold(` DOWN TO `Widget _buildServiceBottomBar`.
    # But wait, `return Scaffold` was just the return statement of `build()`!
    # No, it was the return statement of `FutureBuilder` builder: (context, snapshot) { ... } !!
    # Let's map it:
    # return Scaffold( ... ) is the main UI return!
    
    # Wait, in lines 373 to 1218, the `Scaffold` is inside a `return`. Does it belong to `builder: (context, snapshot)`?
    # NO! Let's look at lines 300 to 400:
    # 272:   @override
    # 273:   Widget build(BuildContext context) {
    # 274:     return FutureBuilder(...)
    #        builder: (context, snapshot) {
    #           ...
    #           return Scaffold( ... );
    #        }
    #     );
    #   }
    
    # Ah!!!
    # If it was inside `builder: (context, snapshot) {`, it needs `  }\n    );\n  }\n` to close the `builder`, `FutureBuilder`, and `build` method!
    # Let me check the original file's braces at line 1217!
    # Lines 1216-1218:
    # 1216:       ),
    # 1217:     );
    # 1218:   }
    # Where does `1217:     );` go to? The `Scaffold` ended earlier? No, `1217:     );` is the `return Scaffold();` end!
    # Wait, where does `FutureBuilder` end?!
    # Oh! Maybe `build` method did NOT use a `FutureBuilder`?! 
    # Look at line 373:
    # 373:           return Scaffold(
    # 374:             backgroundColor: theme.scaffoldBackgroundColor,
    # This implies it was inside something! Line 307 says `if (snapshot.hasError) {`
    # That means it IS inside `FutureBuilder`!
    
    # Wait, if `return Scaffold(...);` is line 1217, where does the `FutureBuilder` get closed?
    # Ah! Maybe line 1218 is `  }` for the `builder: (context, snapshot) {`?
    # And then 1219 is `    );` for the `FutureBuilder`?
    # Let's count back carefully!
    
    insertion = """
        );
      }
    );
  }

""" + service_layout + "\n"

    new_text = text[:end_bracket_idx] + insertion + text[end_bracket_idx:]
    with open("lib/features/listing/presentation/listing_detail_screen.dart", "w") as f2:
        f2.write(new_text)
