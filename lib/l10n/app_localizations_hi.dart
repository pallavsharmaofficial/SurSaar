// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'सुरसार';

  @override
  String get findSongsHeadline => 'अपनी कॉर्ड के अनुसार गाने खोजें';

  @override
  String get selectChordLabel => 'कॉर्ड चुनें';

  @override
  String get recommendedSongsLabel => 'सुझाए गए गाने';

  @override
  String get noSongsFound => 'इस कॉर्ड और कैपो पर कोई गाना नहीं मिला।';

  @override
  String get difficultyLabel => 'स्तर';

  @override
  String get strummingPatternLabel => 'स्ट्रमिंग';

  @override
  String get openTutorialButton => 'ट्यूटोरियल खोलें';

  @override
  String capoLabel(int fret) {
    return 'कैपो: $fret';
  }
}
