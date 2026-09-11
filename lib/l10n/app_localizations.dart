import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SurSaar'**
  String get appTitle;

  /// No description provided for @findSongsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Find Your Perfect Song'**
  String get findSongsHeadline;

  /// No description provided for @songFinderDescription.
  ///
  /// In en, this message translates to:
  /// **'Select a chord and capo position to discover songs you can play'**
  String get songFinderDescription;

  /// No description provided for @selectChordLabel.
  ///
  /// In en, this message translates to:
  /// **'Select a Chord'**
  String get selectChordLabel;

  /// No description provided for @recommendedSongsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommended Songs'**
  String get recommendedSongsLabel;

  /// No description provided for @songs.
  ///
  /// In en, this message translates to:
  /// **'songs'**
  String get songs;

  /// No description provided for @noSongsFound.
  ///
  /// In en, this message translates to:
  /// **'No songs match this selection'**
  String get noSongsFound;

  /// No description provided for @tryDifferentChord.
  ///
  /// In en, this message translates to:
  /// **'Try a different chord or capo position'**
  String get tryDifferentChord;

  /// No description provided for @difficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficultyLabel;

  /// No description provided for @strummingPatternLabel.
  ///
  /// In en, this message translates to:
  /// **'Strumming'**
  String get strummingPatternLabel;

  /// No description provided for @openTutorialButton.
  ///
  /// In en, this message translates to:
  /// **'Watch Tutorial'**
  String get openTutorialButton;

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'Start Practice'**
  String get startPractice;

  /// No description provided for @capoLabel.
  ///
  /// In en, this message translates to:
  /// **'Capo: {fret}'**
  String capoLabel(int fret);

  /// No description provided for @chords.
  ///
  /// In en, this message translates to:
  /// **'Chords'**
  String get chords;

  /// No description provided for @tempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get tempo;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @practiceMode.
  ///
  /// In en, this message translates to:
  /// **'Practice Mode'**
  String get practiceMode;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @mistakes.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get mistakes;

  /// No description provided for @stopPractice.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopPractice;

  /// No description provided for @savePractice.
  ///
  /// In en, this message translates to:
  /// **'Save Session'**
  String get savePractice;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// No description provided for @lessonsDescription.
  ///
  /// In en, this message translates to:
  /// **'Master guitar with structured lessons designed for all skill levels'**
  String get lessonsDescription;

  /// No description provided for @allLessons.
  ///
  /// In en, this message translates to:
  /// **'All Lessons'**
  String get allLessons;

  /// No description provided for @noLessonsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No lessons available yet'**
  String get noLessonsAvailable;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @yourStats.
  ///
  /// In en, this message translates to:
  /// **'Your Stats'**
  String get yourStats;

  /// No description provided for @practiceTime.
  ///
  /// In en, this message translates to:
  /// **'Practice Time'**
  String get practiceTime;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @songsLearned.
  ///
  /// In en, this message translates to:
  /// **'Songs Learned'**
  String get songsLearned;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @lessonsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessonsCompleted;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @currentLevel.
  ///
  /// In en, this message translates to:
  /// **'Current Level'**
  String get currentLevel;

  /// No description provided for @averageAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Average Accuracy'**
  String get averageAccuracy;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @musicLearner.
  ///
  /// In en, this message translates to:
  /// **'Music Learner'**
  String get musicLearner;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get profileDetails;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About SurSaar'**
  String get aboutApp;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get help;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @lessonSteps.
  ///
  /// In en, this message translates to:
  /// **'Lesson Steps'**
  String get lessonSteps;

  /// No description provided for @startLesson.
  ///
  /// In en, this message translates to:
  /// **'Start Lesson'**
  String get startLesson;

  /// No description provided for @xpLabel.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xpLabel;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @noAchievements.
  ///
  /// In en, this message translates to:
  /// **'Complete a practice session to unlock achievements.'**
  String get noAchievements;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @searchSongs.
  ///
  /// In en, this message translates to:
  /// **'Search songs'**
  String get searchSongs;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Song, artist, chord or tag…'**
  String get searchHint;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No songs found for'**
  String get noResultsFor;

  /// No description provided for @requestSong.
  ///
  /// In en, this message translates to:
  /// **'Request this song'**
  String get requestSong;

  /// No description provided for @requestSongHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll add the chords, strumming and structure to the catalogue so you can practise it with the AI teacher.'**
  String get requestSongHint;

  /// No description provided for @aiTeacher.
  ///
  /// In en, this message translates to:
  /// **'AI Teacher'**
  String get aiTeacher;

  /// No description provided for @aiTeacherTagline.
  ///
  /// In en, this message translates to:
  /// **'Turn on your camera and mic. I\'ll show you where your fingers go, listen to every chord and keep you on the beat.'**
  String get aiTeacherTagline;

  /// No description provided for @aiTeacherHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How the teacher works'**
  String get aiTeacherHowItWorks;

  /// No description provided for @aiTeacherExplanation.
  ///
  /// In en, this message translates to:
  /// **'The microphone listens for the chord you play and compares it with the target. The camera tracks your hands so the overlay can point each finger to its string and fret, and the metronome grid checks your strumming timing. Everything runs on your device; nothing is uploaded.'**
  String get aiTeacherExplanation;

  /// No description provided for @quickPractice.
  ///
  /// In en, this message translates to:
  /// **'Quick practice'**
  String get quickPractice;

  /// No description provided for @quickPracticeHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a few chords and a strumming pattern to start an ad-hoc session.'**
  String get quickPracticeHint;

  /// No description provided for @pickChords.
  ///
  /// In en, this message translates to:
  /// **'Pick chords'**
  String get pickChords;

  /// No description provided for @practiceWithTeacher.
  ///
  /// In en, this message translates to:
  /// **'Practise with the AI Teacher'**
  String get practiceWithTeacher;

  /// No description provided for @playNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get playNow;

  /// No description provided for @nextChord.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextChord;

  /// No description provided for @chordsShort.
  ///
  /// In en, this message translates to:
  /// **'Chords'**
  String get chordsShort;

  /// No description provided for @timing.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get timing;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @hearing.
  ///
  /// In en, this message translates to:
  /// **'Hearing'**
  String get hearing;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @bar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get bar;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @microphone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get microphone;

  /// No description provided for @metronome.
  ///
  /// In en, this message translates to:
  /// **'Metronome'**
  String get metronome;

  /// No description provided for @cameraStartsOnPlay.
  ///
  /// In en, this message translates to:
  /// **'The camera starts when you press play.'**
  String get cameraStartsOnPlay;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera is not available on this device.'**
  String get cameraUnavailable;

  /// No description provided for @handTrackingWebOnly.
  ///
  /// In en, this message translates to:
  /// **'Finger guidance with hand tracking is available in the web app; on mobile the teacher listens and shows the chord diagram.'**
  String get handTrackingWebOnly;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlay;

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session complete'**
  String get sessionComplete;

  /// No description provided for @chordsPlayed.
  ///
  /// In en, this message translates to:
  /// **'chords played'**
  String get chordsPlayed;

  /// No description provided for @strums.
  ///
  /// In en, this message translates to:
  /// **'strums'**
  String get strums;

  /// No description provided for @sessionSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get sessionSaved;

  /// No description provided for @keyLabel.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get keyLabel;

  /// No description provided for @sections.
  ///
  /// In en, this message translates to:
  /// **'Song structure'**
  String get sections;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @difficultyAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get difficultyAll;

  /// No description provided for @startCourse.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startCourse;

  /// No description provided for @continueCourse.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueCourse;

  /// No description provided for @courseComplete.
  ///
  /// In en, this message translates to:
  /// **'Course complete!'**
  String get courseComplete;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark lesson complete'**
  String get markComplete;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @teacherSettings.
  ///
  /// In en, this message translates to:
  /// **'Teacher settings'**
  String get teacherSettings;

  /// No description provided for @leftHanded.
  ///
  /// In en, this message translates to:
  /// **'Left-handed player'**
  String get leftHanded;

  /// No description provided for @mirrorCamera.
  ///
  /// In en, this message translates to:
  /// **'Mirror camera preview'**
  String get mirrorCamera;

  /// No description provided for @showHandOverlay.
  ///
  /// In en, this message translates to:
  /// **'Show hand tracking overlay'**
  String get showHandOverlay;

  /// No description provided for @defaultTempo.
  ///
  /// In en, this message translates to:
  /// **'Default tempo'**
  String get defaultTempo;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code on GitHub'**
  String get sourceCode;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone are processed on your device only. Nothing is uploaded.'**
  String get privacyNote;

  /// No description provided for @recentSessions.
  ///
  /// In en, this message translates to:
  /// **'Recent sessions'**
  String get recentSessions;

  /// No description provided for @noSessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet. Start a quick practice to see your history here.'**
  String get noSessions;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
