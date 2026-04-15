import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

# 1. Insert method before build
insert_target = """  @override
  Widget build(BuildContext context) {"""

method_code = """  Widget _buildStudentsNeedSection(BuildContext context) {
    final allItems = _buildStudentsNeedItems(_allDocs);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final visibleItems = isDesktop
        ? allItems.take(8).toList()
        : allItems.take(2).toList();

    if (visibleItems.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final onSurface = colors.onSurface;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Students Need',
                    style: AppTypography.h3.copyWith(
                      color: onSurface,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => context.go('/requests'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        'View All →',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            isDesktop
                ? SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 260,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: HomeRequestCard(
                              data: visibleItems[index].data,
                              onTap: () => _openHomeItem(
                                context,
                                visibleItems[index].id,
                                visibleItems[index].data,
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
                        index < visibleItems.length;
                        index++
                      ) ...[
                        HomeRequestCard(
                          data: visibleItems[index].data,
                          onTap: () => _openHomeItem(
                            context,
                            visibleItems[index].id,
                            visibleItems[index].data,
                          ),
                        ),
                        if (index != visibleItems.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {"""

if insert_target in text:
    text = text.replace(insert_target, method_code)
    print("Inserted _buildStudentsNeedSection.")
else:
    print("WARNING: Could not insert method.")

# 2. Replace the inline block
inline_target = """                  if (showStudentsNeedSection && _studentsNeedItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Students Need',
                                    style: AppTypography.h3.copyWith(
                                      color: onSurface,
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () => context.go('/requests'),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        'View All →',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: colors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (isDesktop)
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
                              ),
                          ],
                        ),
                      ),
                    ),"""

inline_replacement = """                  if (showStudentsNeedSection)
                    _buildStudentsNeedSection(context),"""

if inline_target in text:
    text = text.replace(inline_target, inline_replacement)
    print("Replaced inline students need block correctly.")
else:
    print("WARNING: Could not find inline students need target block.")

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(text)

