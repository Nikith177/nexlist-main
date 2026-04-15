
with open('patched.dart', 'r') as f:
    orig = f.read()

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
        for char, row, col in stack:
            res += f'{char} at line {row}, col {col}\n'
        return res
    else:
        return 'All brackets match!'

print(check_brackets(orig))

