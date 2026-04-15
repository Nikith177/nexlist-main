import sys

with open('lib/features/listing/presentation/listing_detail_screen.dart', 'r') as f:
    lines = f.read().split('\n')

start = -1
for i, line in enumerate(lines):
    if 'const SizedBox(height: 100),' in line:
        start = i
        break

# The correct sequence after SizedBox(height: 100),
correct_ending = [
    "                            ],",     # closes children of Column(443)
    "                          ),",       # closes Column(443)
    "                        ),",         # closes Padding(441)
    "                      ],",           # closes children of Column(418) <--- THIS WAS MISTAKENLY `),` BEFORE !!
    "                    ),",             # closes Column(418)
    "                  ),",               # closes SingleChildScrollView(417)
    "                );",                 # closes ConstrainedBox(403)
    "              },",                   # closes builder(401)
    "            ),",                     # closes LayoutBuilder(400)
    "          ),",                       # closes Center(399)
    "          floatingActionButtonLocation:"
]

end = -1
for i in range(start, len(lines)):
    if 'floatingActionButtonLocation:' in lines[i]:
        end = i
        break

new_lines = lines[:start+1] + correct_ending + lines[end+1:]

with open('patched2.dart', 'w') as f:
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
                    return f'Mismatched {char} at line {i+1}, col {j+1}. Expected match for {last_char} from line {row}. Line is: {line}'
    
    if stack:
        res = 'Unclosed brackets:\n'
        for char, row, col in stack[-5:]:
            res += f'{char} at line {row}, col {col}\n'
        return res
    else:
        return 'All brackets match!'

print(check_brackets('\n'.join(new_lines)))

