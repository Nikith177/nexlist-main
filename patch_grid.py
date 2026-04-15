import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

target = """                        delegate: SliverChildBuilderDelegate((context, index) {
                          final doc = _finalDocs[index];
                          final data =
                              doc.data() as Map<String, dynamic>? ?? const {};

                          final title = data['title'] as String? ?? 'Untitled';
                          final priceDisplay =
                              ListingPriceUtils.resolveDisplayPrice(data);
                          final displayLocation =
                              ListingLocationUtils.resolveDisplayLocation(data);
                          final isUrgent = data['is_urgent'] as bool? ?? false;
                          final images = ListingDataUtils.resolveImages(data);

                          String tagText = ListingPriceUtils.resolveBadgeText(
                            data,
                          );
                          if (isUrgent) {
                            tagText = 'URGENT';
                          }

                          Color tagColor = ListingPriceUtils.resolveBadgeColor(
                            data,
                          );
                          if (tagText == 'URGENT') {
                            tagColor = AppColors.error;
                          }
                          final isFavorite = _savedDocIds.contains(doc.id);

                          return ListingCard(
                            key: ValueKey(doc.id),
                            title: title,
                            priceText: priceDisplay.text,
                            imageUrls: images,
                            location: displayLocation,
                            timeAgo: TimeUtils.formatTimeAgo(
                              ListingDataUtils.resolveCreatedAt(data),
                            ),
                            tagText: tagText,
                            tagColor: tagColor,
                            isFavorite: isFavorite,
                            isNegotiable: data['allow_negotiation'] == true,
                            onFavoriteTap: () =>
                                _toggleFavorite(doc.id, isFavorite),
                            onTap: () => context.push('/listing/${doc.id}'),
                          );
                        }, childCount: _finalDocs.length),"""

replacement = """                        delegate: SliverChildBuilderDelegate((context, index) {
                          final doc = _finalDocs[index];
                          final data = doc.data() as Map<String, dynamic>? ?? const {};

                          final title = data['title'] as String? ?? 'Untitled';
                          final priceDisplay = ListingPriceUtils.resolveDisplayPrice(data);
                          final displayLocation = ListingLocationUtils.resolveDisplayLocation(data);
                          final isUrgent = data['is_urgent'] as bool? ?? false;
                          final images = ListingDataUtils.resolveImages(data);

                          String tagText = ListingPriceUtils.resolveBadgeText(data);
                          if (isUrgent) {
                            tagText = 'URGENT';
                          }

                          Color tagColor = ListingPriceUtils.resolveBadgeColor(data);
                          if (tagText == 'URGENT') {
                            tagColor = AppColors.error;
                          }
                          
                          final isFavorite = _savedDocIds.contains(doc.id);

                          return ListingCard(
                            key: ValueKey(doc.id),
                            title: title,
                            priceText: priceDisplay.text,
                            imageUrls: images,
                            location: displayLocation,
                            timeAgo: TimeUtils.formatTimeAgo(
                              ListingDataUtils.resolveCreatedAt(data),
                            ),
                            tagText: tagText,
                            tagColor: tagColor,
                            isFavorite: isFavorite,
                            isNegotiable: data['allow_negotiation'] == true,
                            onFavoriteTap: () => _toggleFavorite(doc.id, isFavorite),
                            onTap: () => _openHomeItem(context, doc.id, data),
                          );
                        }, childCount: _finalDocs.length),"""

if target in text:
    text = text.replace(target, replacement)
    print("Replaced feed delegate correctly.")
else:
    print("target not found")

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(text)
