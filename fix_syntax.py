import re
with open("lib/features/listing/presentation/listing_detail_screen.dart", "r") as f:
    text = f.read()

text = text.replace("          }\n        );\n      }\n    );\n  }", "          }\n      }\n    );\n  }")

# Also let's fix `_buildServiceLayout`: 
# In `_buildServiceLayout`, I used `Theme.of(context)` but `context` isn't passed! I need to add `BuildContext context` as the first param!
text = text.replace("  Widget _buildServiceLayout({", "  Widget _buildServiceLayout({ required BuildContext context,")

with open("lib/features/listing/presentation/listing_detail_screen.dart", "w") as f2:
    f2.write(text)
