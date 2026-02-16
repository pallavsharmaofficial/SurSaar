import 'package:flutter/material.dart';

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
      label: Text(chord),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}
