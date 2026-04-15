import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class InlineMetadataRow extends StatelessWidget {
  final String timeText;
  final String locationText;
  final TextStyle? textStyle;
  final double iconSize;
  final double iconTextGap;
  final double sectionGap;

  const InlineMetadataRow({
    super.key,
    this.timeText = '',
    this.locationText = '',
    this.textStyle,
    this.iconSize = 12,
    this.iconTextGap = 4,
    this.sectionGap = 8,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedTime = _cleanTime(timeText);
    final resolvedLocation = _clean(locationText);
    final hasTime = resolvedTime.isNotEmpty;
    final hasLocation = resolvedLocation.isNotEmpty;

    if (!hasTime && !hasLocation) {
      return const SizedBox.shrink();
    }

    final style =
        textStyle ??
        AppTypography.bodySmall.copyWith(color: AppColors.textHint);
    final color = style.color ?? AppColors.textHint;

    final metadataText = [
      if (hasLocation) resolvedLocation,
      if (hasTime) resolvedTime,
    ].join(' • ');

    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          if (hasLocation) ...[
            Icon(Icons.location_on, size: iconSize, color: color),
            SizedBox(width: iconTextGap),
          ],
          Expanded(
            child: Text(
              metadataText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }

  String _clean(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text;
  }

  String _cleanTime(dynamic value) {
    final text = _clean(value);
    if (text.isEmpty || text == 'Unknown' || text == 'Posting...') {
      return '';
    }
    return text;
  }
}
