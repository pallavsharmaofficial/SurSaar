import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';

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
        Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/capo_instrument.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.capoLabel(capoFret),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textOnDark),
            ),
          ],
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
