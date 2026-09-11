class AppConstants {
  static const String version = '1.1.0';

  static const List<String> chords = <String>[
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
    'Am',
    'Bm',
    'Cm',
    'Dm',
    'Em',
    'Fm',
    'Gm',
  ];

  static const int maxCapoFret = 7;

  /// Common strumming patterns offered for ad-hoc practice.
  static const List<String> strummingPresets = <String>[
    'D DU UDU',
    'D D U U D U',
    'D D D D',
    'D DU D DU',
    'D X DU X DU',
    'D DUDUDU',
    'D - D U - U D U',
  ];

  static const String githubOwner = 'pallavsharmaofficial';
  static const String githubRepo = 'SurSaar';
  static const String repositoryUrl =
      'https://github.com/$githubOwner/$githubRepo';
  static const String websiteUrl =
      'https://$githubOwner.github.io/$githubRepo/';
  static const String webAppUrl = '${websiteUrl}app/';
  static const String feedbackUrl = '$repositoryUrl/issues/new/choose';
  static const String songRequestUrl = '$repositoryUrl/issues/new';
}
