import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/filter_state.dart';

class GlassFilterPanel extends StatefulWidget {
  final FilterState initialState;
  final List<String> availableLocations;

  const GlassFilterPanel({
    super.key,
    required this.initialState,
    required this.availableLocations,
  });

  @override
  State<GlassFilterPanel> createState() => _GlassFilterPanelState();
}

class _GlassFilterPanelState extends State<GlassFilterPanel> {
  late String _sort;
  late List<String> _locations;

  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sort = widget.initialState.sort;
    _locations = List<String>.from(widget.initialState.locations);

    final min = widget.initialState.minPrice;
    final max = widget.initialState.maxPrice;
    if (min != null) _minController.text = min.toString();
    if (max != null) _maxController.text = max.toString();
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  FilterState _buildState() {
    final minText = _minController.text.trim();
    final maxText = _maxController.text.trim();
    final minPrice = minText.isEmpty ? null : int.tryParse(minText);
    final maxPrice = maxText.isEmpty ? null : int.tryParse(maxText);

    return FilterState(
      sort: _sort,
      minPrice: minPrice,
      maxPrice: maxPrice,
      locations: List<String>.unmodifiable(_locations),
    );
  }

  void _reset() {
    setState(() {
      _sort = 'newest';
      _locations = [];
      _minController.clear();
      _maxController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final onSurface = colors.onSurface;
    final onSurfaceMuted = onSurface.withValues(alpha: 0.55);
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final borderRadius = isDesktop 
        ? BorderRadius.circular(20) 
        : const BorderRadius.vertical(top: Radius.circular(20));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color.fromRGBO(20, 30, 45, 0.80)
                  : const Color.fromRGBO(255, 255, 255, 0.82),
              borderRadius: borderRadius,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.5),
                width: isDark ? 1 : 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle (Mobile only)
                        if (!isDesktop) ...[
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: onSurface.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filters',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: onSurface,
                                  ),
                            ),
                            TextButton(
                              onPressed: _reset,
                              child: Text(
                                'Reset',
                                style: TextStyle(color: colors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Sort Section
                        Text(
                          'Sort by',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        _SortRadio(
                          value: 'newest',
                          label: 'Newest First',
                          groupValue: _sort,
                          onChanged: (v) => setState(() => _sort = v),
                          onSurface: onSurface,
                        ),
                        _SortRadio(
                          value: 'price_low',
                          label: 'Price: Low to High',
                          groupValue: _sort,
                          onChanged: (v) => setState(() => _sort = v),
                          onSurface: onSurface,
                        ),
                        _SortRadio(
                          value: 'price_high',
                          label: 'Price: High to Low',
                          groupValue: _sort,
                          onChanged: (v) => setState(() => _sort = v),
                          onSurface: onSurface,
                        ),
                        const SizedBox(height: 16),

                        // Price Section
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Price Range',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PriceField(
                                controller: _minController,
                                hint: 'Min ₹',
                                onSurface: onSurface,
                                onSurfaceMuted: onSurfaceMuted,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PriceField(
                                controller: _maxController,
                                hint: 'Max ₹',
                                onSurface: onSurface,
                                onSurfaceMuted: onSurfaceMuted,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),

                        // Location Section
                        if (widget.availableLocations.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Location',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: onSurface,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.availableLocations.map((loc) {
                              final isSelected = _locations.contains(loc);
                              return FilterChip(
                                label: Text(
                                  loc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? colors.onPrimary
                                        : onSurface,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _locations.add(loc);
                                    } else {
                                      _locations.remove(loc);
                                    }
                                  });
                                },
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.05),
                                selectedColor: colors.primary,
                                checkmarkColor: colors.onPrimary,
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? colors.primary
                                        : onSurface.withValues(alpha: 0.12),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(_buildState()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortRadio extends StatelessWidget {
  final String value;
  final String label;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final Color onSurface;

  const _SortRadio({
    required this.value,
    required this.label,
    required this.groupValue,
    required this.onChanged,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primary : onSurface.withValues(alpha: 0.4),
                  width: isSelected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}


class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color onSurface;
  final Color onSurfaceMuted;
  final bool isDark;

  const _PriceField({
    required this.controller,
    required this.hint,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(color: onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: onSurfaceMuted, fontSize: 14),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: onSurface.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: onSurface.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Opens GlassFilterPanel correctly for mobile or desktop.
Future<FilterState?> showFilterPanel({
  required BuildContext context,
  required FilterState currentState,
  required List<String> availableLocations,
}) {
  final isDesktop = MediaQuery.of(context).size.width >= 768;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (isDesktop) {
    return showDialog<FilterState>(
      context: context,
      barrierColor: isDark 
          ? Colors.black.withValues(alpha: 0.5) 
          : Colors.black.withValues(alpha: 0.2),
      builder: (_) => Center(
        child: Container(
          width: 420,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Material(
            color: Colors.transparent,
            child: GlassFilterPanel(
              initialState: currentState,
              availableLocations: availableLocations,
            ),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<FilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: isDark 
        ? Colors.black.withValues(alpha: 0.5) 
        : Colors.black.withValues(alpha: 0.2),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.62,
      child: GlassFilterPanel(
        initialState: currentState,
        availableLocations: availableLocations,
      ),
    ),
  );
}
