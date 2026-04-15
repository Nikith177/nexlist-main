import sys

with open('lib/features/home/presentation/widgets/home_widgets.dart', 'r') as f:
    text = f.read()

# Filter target
row_target = """                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilterPill("""

row_replacement = """                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilterPill("""

if row_target in text:
    text = text.replace(row_target, row_replacement)
else:
    print("WARNING: row_target not found.")

# We also need to close the SingleChildScrollView properly.
# Find the exact closing
end_target = """                        ],
                      ],
                    ),
                  ),
                );
              },
            ),"""

# Wait, previously the structure was:
#                 return SingleChildScrollView(
#                   scrollDirection: Axis.horizontal,
#                   child: ConstrainedBox(
#                     constraints: BoxConstraints(minWidth: constraints.maxWidth),
#                     child: Row(
#                       mainAxisAlignment: MainAxisAlignment.center,
#                       children: [

# If I already have a SingleChildScrollView outside ConstrainedBox?!
# Ah! Let me check the actual current file structure!
