import 'package:flutter/material.dart';
import 'package:sursaar/l10n/app_localizations.dart';

class CapoSlider extends StatelessWidget {
  const CapoSlider({
    super.key,
    required this.capoFret,
    required this.maxCapoFret,
    required this.onChanged,
  });

  final int capoFret;
  final int maxCapoFret;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.capoLabel(capoFret),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: capoFret.toDouble(),
          min: 0,
          max: maxCapoFret.toDouble(),
          divisions: maxCapoFret,
          label: capoFret.toString(),
          onChanged: (value) => onChanged(value.round()),
        ),
      ],
    );
  }
}
