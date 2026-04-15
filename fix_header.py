import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    orig = f.read()

# I need to find the `if (!isDesktop) ...[` and remove it.
# It starts around line 836.
lines = orig.split('\n')

res = []
in_block = False
skip_next_bracket = False
for i, line in enumerate(lines):
    if line.strip() == 'if (!isDesktop) ...[':
        continue # skip
    if line.strip() == '],' and 'SliverPersistentHeader(' in '\n'.join(lines[i-20:i]):
        # This is the closing bracket I added.
        # Wait, I just appended `                  ],` after the filter chips!
        # Let's verify by just looking for the exact indentation.
        continue

    # But wait, I also indented everything by 2 spaces!
    # Let me just rollback `lib/features/home/presentation/home_screen.dart` via git to before I made this specific change? No, wait! I also added feed filtering logic (`matchesType = true;`)!
    pass

# A simpler way: we can just find `if (!isDesktop) ...[` and the corresponding `],`, 
# and un-indent.
out_lines = []
inside_if = False
for line in lines:
    if line == '                  if (!isDesktop) ...[':
        inside_if = True
        continue
    
    if inside_if and line == '                  ],':
        inside_if = False
        continue
        
    if inside_if:
        if line.startswith('  '):
            out_lines.append(line[2:])
        else:
            out_lines.append(line)
    else:
        out_lines.append(line)

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write('\n'.join(out_lines))
    
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

print(check_brackets('\n'.join(out_lines)))
