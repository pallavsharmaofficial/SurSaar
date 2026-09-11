import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ChordChip extends StatelessWidget {
  const ChordChip({
    super.key,
    required this.chord,
    required this.isSelected,
    required this.onSelected,
  });

  final String chord;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        chord,
        style: TextStyle(
          color: isSelected ? AppColors.surfaceLight : AppColors.textOnLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
    );
  }
}
