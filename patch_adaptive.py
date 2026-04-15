import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

target = """                            isDesktop
                                ? SizedBox(
                                    height: 120, // Tweak height if needed to fit card
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _studentsNeedItems.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        return SizedBox(
                                          width: 260,
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: HomeRequestCard(
                                              data: _studentsNeedItems[index].data,
                                              onTap: () => _openHomeItem(
                                                context,
                                                _studentsNeedItems[index].id,
                                                _studentsNeedItems[index].data,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (
                                        var index = 0;
                                        index < _studentsNeedItems.length;
                                        index++
                                      ) ...[
                                        HomeRequestCard(
                                          data: _studentsNeedItems[index].data,
                                          onTap: () => _openHomeItem(
                                            context,
                                            _studentsNeedItems[index].id,
                                            _studentsNeedItems[index].data,
                                          ),
                                        ),
                                        if (index != _studentsNeedItems.length - 1)
                                          const SizedBox(height: 8),
                                      ],
                                    ],
                                  ),"""

replacement = """                            if (isDesktop)
                              (_studentsNeedItems.length <= 3
                                  ? Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: _studentsNeedItems.map((item) {
                                        return SizedBox(
                                          width: 260,
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: HomeRequestCard(
                                              data: item.data,
                                              onTap: () => _openHomeItem(
                                                context,
                                                item.id,
                                                item.data,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  : SizedBox(
                                      height: 120, // Tweak height if needed to fit card
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _studentsNeedItems.length,
                                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          return SizedBox(
                                            width: 260,
                                            child: Align(
                                              alignment: Alignment.topCenter,
                                              child: HomeRequestCard(
                                                data: _studentsNeedItems[index].data,
                                                onTap: () => _openHomeItem(
                                                  context,
                                                  _studentsNeedItems[index].id,
                                                  _studentsNeedItems[index].data,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ))
                            else
                              Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < _studentsNeedItems.length;
                                    index++
                                  ) ...[
                                    HomeRequestCard(
                                      data: _studentsNeedItems[index].data,
                                      onTap: () => _openHomeItem(
                                        context,
                                        _studentsNeedItems[index].id,
                                        _studentsNeedItems[index].data,
                                      ),
                                    ),
                                    if (index != _studentsNeedItems.length - 1)
                                      const SizedBox(height: 8),
                                  ],
                                ],
                              ),"""

if target in text:
    text = text.replace(target, replacement)
    print("Patched requested section successfully.")
else:
    print("Could not find requested section.")

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
