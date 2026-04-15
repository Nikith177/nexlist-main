import sys

with open('lib/features/listing/presentation/listing_detail_screen.dart', 'r') as f:
    lines = f.read().split('\n')

start = -1
for i, line in enumerate(lines):
    if 'const SizedBox(height: 100),' in line:
        start = i
        break

print(f"SizedBox is at {start}")

# Generate the correct ending sequence
correct_ending = [
    "                            ],",
    "                          ),",
    "                        ), // closes SingleChildScrollView",
    "                      ); // closes ConstrainedBox",
    "                    },",
    "                  ),",
    "                ),",
    "          floatingActionButtonLocation:"
]

# Find floatingActionButtonLocation
end = -1
for i in range(start, len(lines)):
    if 'floatingActionButtonLocation:' in lines[i]:
        end = i
        break

print(f"FAB is at {end}")

new_lines = lines[:start+1] + correct_ending + lines[end+1:]

with open('patched.dart', 'w') as f:
    f.write('\n'.join(new_lines))

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
                    return f'Mismatched {char} at line {i+1}, col {j+1}. Expected match for {last_char} from line {row}'
    
    if stack:
        res = 'Unclosed brackets:\n'
        for char, row, col in stack:
            res += f'{char} at line {row}, col {col}\n'
        return res
    else:
        return 'All brackets match!'

print("Testing patched file:", check_brackets('\n'.join(new_lines)))

