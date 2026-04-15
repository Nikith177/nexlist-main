import re

with open('lib/features/listing/presentation/listing_detail_screen.dart', 'r') as f:
    content = f.read()

# Define the boundaries of the parts we need to extract.
# I'll manually find the strings and replace the core body.

# Instead of parsing everything with regex, let's use exact line offsets or split by known markers.

# Marker 1: return Scaffold(
scaffold_start_idx = content.find("return Scaffold(\n            backgroundColor: theme.scaffoldBackgroundColor,")

# Marker 2: Widget _buildServiceBottomBar
scaffold_end_idx = content.find("Widget _buildServiceBottomBar({")

pre_scaffold = content[:scaffold_start_idx]
post_scaffold = content[scaffold_end_idx:]

# Let's extract the widgets verbatim from the existing code
main_image_src = content[content.find("if (hasImages)"):content.find("Padding(\n                          padding: const EdgeInsets.all(16.0),")]
main_image_src = main_image_src.strip()

# Next is the padding block
padding_start = content.find("Padding(\n                          padding: const EdgeInsets.all(16.0),")
padding_end = content.find("const SizedBox(height: 100),")
padding_block = content[padding_start:padding_end].strip()

# Now extract parts of the padding block for the different sections
header_end = padding_block.find("if (hasDisplayLocation || hasTimeAgo) ...[")
header_src = padding_block[:header_end].strip()

location_start = padding_block.find("if (hasDisplayLocation || hasTimeAgo) ...[")
location_end = padding_block.find("const SizedBox(height: 24),\n                              Row(")
location_src = padding_block[location_start:location_end].strip()

meta_start = padding_block.find("Row(\n                                children: [\n                                  if (hasCondition) ...[")
meta_end = padding_block.find("const SizedBox(height: 24),\n                              Text(\n                                'Description'")
meta_src = padding_block[meta_start:meta_end].strip()

desc_start = padding_block.find("Text(\n                                'Description'")
desc_end = padding_block.rfind("],\n                          ),")
desc_src = padding_block[desc_start:desc_end].strip()

# Note that desc_src might need adjustment to close brackets. 
# We can just craft the helper functions dynamically.

cta_start = content.find("                  : Container(\n                      padding: const EdgeInsets.symmetric(")
cta_end = content.find("    );\n  }\n\n  Widget _buildServiceBottomBar")
cta_src = content[content.find("Container(\n                      padding: const EdgeInsets.symmetric(", cta_start):cta_end].strip()

# Let's write the new scaffold logic
new_scaffold = f"""
          Widget _buildMainImage(bool isDesktop) {{
            if (!hasImages) return const SizedBox.shrink();
            return SizedBox(
              height: isDesktop ? 400 : 280,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      topLeft: isDesktop ? Radius.circular(16) : Radius.zero,
                      topRight: isDesktop ? Radius.circular(16) : Radius.zero,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: colors.surfaceContainerHighest),
                        CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          fadeInDuration: const Duration(milliseconds: 200),
                          fadeOutDuration: const Duration(milliseconds: 100),
                          placeholder: (context, url) => Container(color: colors.surfaceContainerHighest),
                          errorWidget: (context, url, error) => Container(
                            color: colors.surfaceContainerHighest,
                            child: Center(
                              child: Icon(Icons.broken_image, size: 64, color: colors.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: listingBadgeColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        listingBadgeLabel,
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (user != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildFavoriteBadge(context: context, userId: user.uid),
                    ),
                ],
              ),
            );
          }}

          Widget _buildHeaderSection() {{
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(title, style: AppTypography.h1.copyWith(color: colors.onSurface)),
                    ),
                    if (priceDisplay.hasPrice) ...[
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(priceDisplay.text, style: AppTypography.h1.copyWith(color: colors.primary)),
                          if (isNegotiable) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                'Negotiable',
                                style: TextStyle(fontSize: 10, color: colors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
                if (hasDisplayLocation || hasTimeAgo) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (hasDisplayLocation) ...[
                        Icon(Icons.location_on, size: 16, color: colors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            displayLocation,
                            style: AppTypography.bodySmall.copyWith(fontSize: 14, color: colors.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (hasDisplayLocation && hasTimeAgo) ...[
                        const SizedBox(width: 8),
                        Text('•', style: AppTypography.bodySmall.copyWith(fontSize: 14, color: colors.onSurfaceVariant)),
                        const SizedBox(width: 8),
                      ],
                      if (hasTimeAgo) ...[
                        Icon(Icons.access_time, size: 16, color: colors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(timeAgo, style: AppTypography.bodySmall.copyWith(fontSize: 14, color: colors.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ],
              ],
            );
          }}

          Widget _buildMetaSection() {{
            if (!hasCondition && !hasCategory) return const SizedBox.shrink();
            return Row(
              children: [
                if (hasCondition) ...[
                  Expanded(child: _buildAttributeBox('CONDITION', condition)),
                  const SizedBox(width: 8),
                ],
                if (hasCategory) ...[
                  Expanded(child: _buildAttributeBox('CATEGORY', category)),
                  const SizedBox(width: 8),
                ],
                Expanded(child: _buildAttributeBox('TYPE', listingTypeLabel)),
              ],
            );
          }}

          Widget _buildDescriptionSection() {{
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description', style: AppTypography.h3.copyWith(color: colors.onSurface)),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(height: 1.5, fontSize: 15, color: colors.onSurfaceVariant),
                ),
                if (!isRequestOrService) ...[
                  const SizedBox(height: 32),
                  Text('Seller Information', style: AppTypography.h3.copyWith(color: colors.onSurface)),
                  const SizedBox(height: 12),
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance.collection('users').doc(sellerId).get(),
                    builder: (context, sellerSnapshot) {{
                      if (sellerSnapshot.connectionState == ConnectionState.waiting) {{
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }}

                      if (sellerSnapshot.hasError) {{
                        return const Text('Seller info unavailable');
                      }}

                      final sellerData = sellerSnapshot.data?.data() ?? const <String, dynamic>{{}};
                      String sellerName = PhoneGateUtils.normalizeName(data['contactName']) ??
                          PhoneGateUtils.normalizeName(sellerData['name']) ??
                          PhoneGateUtils.normalizeName(data['user_name']) ??
                          PhoneGateUtils.normalizeName(data['name']) ??
                          'User';

                      if (user != null && sellerId == user.uid) {{
                        sellerName = '$sellerName (You)';
                      }}

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: colors.primary.withValues(alpha: 0.1),
                              child: Icon(Icons.person, color: colors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Posted by',
                                    style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sellerName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: colors.onSurface),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }},
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: colors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Nexlist Campus Safety Tips',
                              style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSafetyBullet('Meet in a public campus area during daylight.'),
                        _buildSafetyBullet('Always inspect the item before paying.'),
                        _buildSafetyBullet('Use campus UPI or cash for secure payments.'),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }}

          Widget _buildActionCTA() {{
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(color: colors.shadow.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (!isOwner) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {{
                            await ContactUtils.contactSellerOnWhatsApp(
                              context: context,
                              data: {{...data, 'id': widget.listingId}},
                            );
                          }},
                          icon: Icon(Icons.chat_bubble_outline, color: colors.onPrimary),
                          label: Text(
                            'Contact on WhatsApp',
                            style: TextStyle(color: colors.onPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                    if (isOwner) ...[
                      if (listingType == 'sell') ...[
                        if (status == 'available')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingStatus || _isDeleting
                                  ? null
                                  : () => _updateStatus(context, 'sold'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Mark as Sold', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        if (status == 'sold')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingStatus || _isDeleting
                                  ? null
                                  : () => _updateStatus(context, 'available'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Mark as Available', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                      if (listingType == 'rent') ...[
                        if (status == 'available')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingStatus || _isDeleting
                                  ? null
                                  : () => _updateStatus(context, 'rented'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Mark as Rented', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        if (status == 'rented')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingStatus || _isDeleting
                                  ? null
                                  : () => _updateStatus(context, 'available'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Mark as Available', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                      if (listingType == 'request') ...[
                        if (status == 'available')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingStatus || _isDeleting
                                  ? null
                                  : () => _updateStatus(context, 'resolved'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Mark as Resolved', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        if (status == 'resolved')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingStatus || _isDeleting
                                  ? null
                                  : () => _updateStatus(context, 'available'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Mark as Unresolved', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: colors.error), borderRadius: BorderRadius.circular(12)),
                        child: IconButton(
                          onPressed: _isUpdatingStatus || _isDeleting ? null : () => _deleteListing(context),
                          icon: _isDeleting
                              ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.error))
                              : Icon(Icons.delete_outline, color: colors.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }}

          Widget _buildMobileLayout() {{
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                iconTheme: IconThemeData(color: colors.onSurface),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.onSurface),
                  onPressed: () => _handleBackTap(context),
                ),
                title: Text('Listing Details', style: AppTypography.h3.copyWith(color: colors.onSurface)),
                centerTitle: true,
                actions: [
                  if (_canShareListing(listingType))
                    IconButton(icon: Icon(Icons.share, color: colors.onSurface), onPressed: () => _shareListing(data)),
                ],
              ),
              body: listingType == 'service'
                  ? _buildServiceLayout(
                      data: data,
                      sellerId: sellerId,
                      imageUrl: imageUrl,
                      category: category,
                      title: title,
                      description: description,
                      displayLocation: displayLocation,
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainImage(false),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeaderSection(),
                                const SizedBox(height: 24),
                                _buildMetaSection(),
                                const SizedBox(height: 24),
                                _buildDescriptionSection(),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: listingType == 'service'
                  ? _buildServiceBottomBar(context: context, isOwner: isOwner, status: status, data: data)
                  : _buildActionCTA(),
            );
          }}

          Widget _buildDesktopLayout(BuildContext context) {{
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                iconTheme: IconThemeData(color: colors.onSurface),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.onSurface),
                  onPressed: () => _handleBackTap(context),
                ),
                title: Text('Listing Details', style: AppTypography.h3.copyWith(color: colors.onSurface)),
                centerTitle: true,
                actions: [
                  if (_canShareListing(listingType))
                    IconButton(icon: Icon(Icons.share, color: colors.onSurface), onPressed: () => _shareListing(data)),
                ],
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: listingType == 'service'
                    ? _buildServiceLayout(
                        data: data,
                        sellerId: sellerId,
                        imageUrl: imageUrl,
                        category: category,
                        title: title,
                        description: description,
                        displayLocation: displayLocation,
                      )
                    : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMainImage(true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeaderSection(),
                                const SizedBox(height: 24),
                                _buildMetaSection(),
                                const SizedBox(height: 24),
                                _buildDescriptionSection(),
                                const SizedBox(height: 32),
                                _buildActionCTA(),
                                const SizedBox(height: 64),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }}

          final isDesktop = MediaQuery.of(context).size.width > 900;
          if (isDesktop) {{
            return _buildDesktopLayout(context);
          }} else {{
            return _buildMobileLayout();
          }}
"""

with open('lib/features/listing/presentation/listing_detail_screen.dart', 'w') as f:
    f.write(pre_scaffold + new_scaffold + post_scaffold)

