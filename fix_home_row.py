import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

target = """                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (!isDesktop) ...[
                                SizedBox(
                                  height: 34,
                                  child: Image.asset(
                                    logoAsset,
                                    height: 34,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 12),
                              // Compact Campus Pill
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Text(
                                  getCampusName(_campusId) ==
                                          'National Institute of Technology Kurukshetra'
                                      ? 'NIT KKR'
                                      : getCampusName(_campusId),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => context.push('/notifications'),
                                icon: Icon(
                                  Icons.notifications_outlined,
                                  size: 26,
                                  color: onSurface,
                                ),
                                tooltip: 'Notifications',
                                splashRadius: 22,
                              ),
                            ],
                          ),"""

replacement = """                          if (!isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 34,
                                  child: Image.asset(
                                    logoAsset,
                                    height: 34,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Compact Campus Pill
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    getCampusName(_campusId) ==
                                            'National Institute of Technology Kurukshetra'
                                        ? 'NIT KKR'
                                        : getCampusName(_campusId),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => context.push('/notifications'),
                                  icon: Icon(
                                    Icons.notifications_outlined,
                                    size: 26,
                                    color: onSurface,
                                  ),
                                  tooltip: 'Notifications',
                                  splashRadius: 22,
                                ),
                              ],
                            ),"""

if target in text:
    text = text.replace(target, replacement)
    print("Replaced home_screen row.")
else:
    print("WARNING: home screen target not found.")

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(text)

