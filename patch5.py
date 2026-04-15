import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

# Add isDesktop
target_decl = """            final isDark = theme.brightness == Brightness.dark;"""
if "final isDesktop =" not in text:
    text = text.replace(target_decl, f"final isDesktop = MediaQuery.of(context).size.width >= 800;\n{target_decl}")
    
lines = text.split('\n')

start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if "SliverToBoxAdapter(" in line and "Header / App Bar content" in lines[i-1]:
        start_idx = i - 1
    
    if "if (showBrowseSections && _activityItems.isNotEmpty)" in line:
        end_idx = i - 1
        break

if start_idx == -1 or end_idx == -1:
    print("Could not find bounds.")
    sys.exit(1)

# Grab the block
block = lines[start_idx:end_idx]

new_block = ["                  if (!isDesktop) ...["]
for line in block:
    if line.strip() == "":
        new_block.append(line)
    else:
        new_block.append("  " + line) # Add 2 spaces indentation
new_block.append("                  ],")

# Reconstruct
new_lines = lines[:start_idx] + new_block + lines[end_idx:]

# Final check for brackets
def check_brackets(text):
    stack = []
    lines = text.split('\n')
    for i, line in enumerate(lines):
        for j, char in enumerate(line):
            if char in '([{':
                stack.append((char, i + 1, j + 1))
            elif char in ')]}':
                if not stack:
                    return f'Unmatched closing {char} at line {i+1}, col {j+1}'
                last_char, row, col = stack.pop()
                if (char == ')' and last_char != '(') or \
                   (char == ']' and last_char != '[') or \
                   (char == '}' and last_char != '{'):
                    return f'Mismatched {char} at line {i+1}, col {j+1}'
    if stack:
        return 'Unclosed brackets'
    else:
        return 'All brackets match!'

patched_text = '\n'.join(new_lines)
print(check_brackets(patched_text))

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(patched_text)

print("Patch 5 applied successfully.")
