import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

target = """  Widget _buildStudentsNeedSection(BuildContext context) {
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
  }"""

replacement = """  Widget _buildStudentsNeedSection(BuildContext context) {
    final allItems = _buildStudentsNeedItems(_allDocs);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final visibleItems = isDesktop
        ? allItems.take(8).toList()
        : allItems.take(2).toList();

    if (visibleItems.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
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
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 260,
                          child: HomeRequestCard(
                            data: visibleItems[index].data,
                            onTap: () => _openHomeItem(
                              context,
                              visibleItems[index].id,
                              visibleItems[index].data,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < visibleItems.length; i++) ...[
                        HomeRequestCard(
                          data: visibleItems[i].data,
                          onTap: () => _openHomeItem(
                            context,
                            visibleItems[i].id,
                            visibleItems[i].data,
                          ),
                        ),
                        if (i != visibleItems.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }"""

if target in text:
    text = text.replace(target, replacement)
    print("Replace _buildStudentsNeedSection with updated prompt instructions successfully.")
else:
    print("WARNING: Could not find method targeted.")

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(text)

