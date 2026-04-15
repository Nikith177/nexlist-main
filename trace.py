import sys

with open('lib/features/listing/presentation/listing_detail_screen.dart', 'r') as f:
    lines = f.read().split('\n')

stack = []
for i, line in enumerate(lines[:836]):
    for j, char in enumerate(line):
        if char in '([{':
            stack.append(f"{char} {i+1}")
        elif char in ')]}':
            if stack:
                stack.pop()

print("Open stack at 836:")
for s in stack:
    print(s)

