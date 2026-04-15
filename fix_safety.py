import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content

    # 1. Fix silent catch blocks
    content = re.sub(
        r'catch\s*\((_|[a-zA-Z]+)\)\s*\{\s*\}',
        r"catch (\1, stack) {\n      debugPrint('ERROR: $\1');\n      debugPrint('STACK: $stack');\n    }",
        content
    )
    
    # Also fix catch (_) { ... } without stack trace to have debug print if not empty, but user literally said catch (_) {} or catch (e) {}
    
    # 2. Add User-facing feedback ONLY in user-triggered actions (already handled some manually, let's leave this for manual review if needed)
    
    # 3. Fix setState after await
    # 4. Fix pop after await
    # Instead of full AST, we can find typical patterns manually or via regex, e.g. await ... \n \s* setState, and insert if (!mounted) return;
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

