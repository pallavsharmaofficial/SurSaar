// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SurSaar';

  @override
  String get findSongsHeadline => 'Find songs that match your chord';

  @override
  String get selectChordLabel => 'Select a chord';

  @override
  String get recommendedSongsLabel => 'Recommended songs';

  @override
  String get noSongsFound =>
      'No songs match this chord and capo. Try another chord.';

  @override
  String get difficultyLabel => 'Difficulty';

  @override
  String get strummingPatternLabel => 'Strumming';

  @override
  String get openTutorialButton => 'Open tutorial';

  @override
  String capoLabel(int fret) {
    return 'Capo: $fret';
  }
}
