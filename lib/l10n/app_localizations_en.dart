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
  String get findSongsHeadline => 'Find Your Perfect Song';

  @override
  String get songFinderDescription =>
      'Select a chord and capo position to discover songs you can play';

  @override
  String get selectChordLabel => 'Select a Chord';

  @override
  String get recommendedSongsLabel => 'Recommended Songs';

  @override
  String get songs => 'songs';

  @override
  String get noSongsFound => 'No songs match this selection';

  @override
  String get tryDifferentChord => 'Try a different chord or capo position';

  @override
  String get difficultyLabel => 'Difficulty';

  @override
  String get strummingPatternLabel => 'Strumming';

  @override
  String get openTutorialButton => 'Watch Tutorial';

  @override
  String get startPractice => 'Start Practice';

  @override
  String capoLabel(int fret) {
    return 'Capo: $fret';
  }

  @override
  String get chords => 'Chords';

  @override
  String get tempo => 'Tempo';

  @override
  String get duration => 'Duration';

  @override
  String get practiceMode => 'Practice Mode';

  @override
  String get listening => 'Listening...';

  @override
  String get tapToStart => 'Tap to start practicing';

  @override
  String get aiPracticePlaceholder =>
      'AI-powered practice mode coming soon! This feature will listen to your playing and provide real-time feedback.';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get mistakes => 'Mistakes';

  @override
  String get stopPractice => 'Stop';

  @override
  String get savePractice => 'Save Session';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get aiFeatureDescription =>
      'This AI feature is under development. It will use machine learning to analyze your playing, detect chord accuracy, and provide personalized feedback.';

  @override
  String get ok => 'OK';

  @override
  String get lessons => 'Lessons';

  @override
  String get lessonsDescription =>
      'Master guitar with structured lessons designed for all skill levels';

  @override
  String get allLessons => 'All Lessons';

  @override
  String get noLessonsAvailable => 'No lessons available yet';

  @override
  String get progress => 'Progress';

  @override
  String get yourStats => 'Your Stats';

  @override
  String get practiceTime => 'Practice Time';

  @override
  String get minutes => 'min';

  @override
  String get songsLearned => 'Songs Learned';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get days => 'days';

  @override
  String get lessonsCompleted => 'Lessons';

  @override
  String get level => 'Level';

  @override
  String get currentLevel => 'Current Level';

  @override
  String get averageAccuracy => 'Average Accuracy';

  @override
  String get profile => 'Profile';

  @override
  String get musicLearner => 'Music Learner';

  @override
  String get profileDetails => 'Profile Details';

  @override
  String get nameLabel => 'Name';

  @override
  String get bioLabel => 'Bio';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get about => 'About';

  @override
  String get aboutApp => 'About SurSaar';

  @override
  String get help => 'Help & Support';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get lessonSteps => 'Lesson Steps';

  @override
  String get startLesson => 'Start Lesson';

  @override
  String get xpLabel => 'XP';

  @override
  String get achievements => 'Achievements';

  @override
  String get noAchievements =>
      'Complete a practice session to unlock achievements.';
}
