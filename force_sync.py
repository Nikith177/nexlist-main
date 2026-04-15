import sys
import os

filepath = 'lib/features/home/presentation/widgets/home_widgets.dart'
with open(filepath, 'r') as f:
    text = f.read()

# Just replace to exactly what it is to force modification
with open(filepath, 'w') as f:
    f.write(text)

print("Forced file sync.")
