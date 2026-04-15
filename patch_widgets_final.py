import sys

with open('lib/features/home/presentation/widgets/home_widgets.dart', 'r') as f:
    text = f.read()

# I will find the LayoutBuilder context:
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

# The end bracket closure:
# The children end with `],\n                      ],` (since we added `if (isDesktop) ...[` previously)
# Then it was closed by `\n                    ),` for the Row.
# I need to add `\n                    ),` for the SingleChildScrollView.

close_target = """                        ],
                      ],
                    ),
                  ),
                );"""

close_replacement = """                        ],
                      ],
                    ),
                    ),
                  ),
                );"""

if close_target in text:
    text = text.replace(close_target, close_replacement)
else:
    print("WARNING: close_target not found.")

with open('lib/features/home/presentation/widgets/home_widgets.dart', 'w') as f:
    f.write(text)

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

print(check_brackets(text))
print("Widgets patched successfully.")
