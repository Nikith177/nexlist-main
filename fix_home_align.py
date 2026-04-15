import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

# I need to fix the closures.
# The `close_replacement` was:
#                         ],
#                       ),
#                     ),
#                   ),
#                 ),

# It should be:
target_to_fix = """                          if (isDesktop) const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),"""

fixed_closure = """                          if (isDesktop) const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),"""

if target_to_fix in text:
    text = text.replace(target_to_fix, fixed_closure)
else:
    print("WARNING: target_to_fix not found.")

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
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
