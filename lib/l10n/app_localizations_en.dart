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
  String get accuracy => 'Accuracy';

  @override
  String get mistakes => 'Mistakes';

  @override
  String get stopPractice => 'Stop';

  @override
  String get savePractice => 'Save Session';

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
  String get language => 'Language';

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

  @override
  String get home => 'Home';

  @override
  String get learn => 'Learn';

  @override
  String get courses => 'Courses';

  @override
  String get searchSongs => 'Search songs';

  @override
  String get searchHint => 'Song, artist, chord or tag…';

  @override
  String get noResultsFor => 'No songs found for';

  @override
  String get requestSong => 'Request this song';

  @override
  String get requestSongHint =>
      'We\'ll add the chords, strumming and structure to the catalogue so you can practise it with the AI teacher.';

  @override
  String get aiTeacher => 'AI Teacher';

  @override
  String get aiTeacherTagline =>
      'Turn on your camera and mic. I\'ll show you where your fingers go, listen to every chord and keep you on the beat.';

  @override
  String get aiTeacherHowItWorks => 'How the teacher works';

  @override
  String get aiTeacherExplanation =>
      'The microphone listens for the chord you play and compares it with the target. The camera tracks your hands so the overlay can point each finger to its string and fret, and the metronome grid checks your strumming timing. Everything runs on your device; nothing is uploaded.';

  @override
  String get quickPractice => 'Quick practice';

  @override
  String get quickPracticeHint =>
      'Pick a few chords and a strumming pattern to start an ad-hoc session.';

  @override
  String get pickChords => 'Pick chords';

  @override
  String get practiceWithTeacher => 'Practise with the AI Teacher';

  @override
  String get playNow => 'Play now';

  @override
  String get nextChord => 'Next';

  @override
  String get chordsShort => 'Chords';

  @override
  String get timing => 'Timing';

  @override
  String get overall => 'Overall';

  @override
  String get hearing => 'Hearing';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get playAgain => 'Play again';

  @override
  String get finish => 'Finish';

  @override
  String get done => 'Done';

  @override
  String get bar => 'Bar';

  @override
  String get camera => 'Camera';

  @override
  String get microphone => 'Microphone';

  @override
  String get metronome => 'Metronome';

  @override
  String get cameraStartsOnPlay => 'The camera starts when you press play.';

  @override
  String get cameraUnavailable => 'Camera is not available on this device.';

  @override
  String get handTrackingWebOnly =>
      'Finger guidance with hand tracking is available in the web app; on mobile the teacher listens and shows the chord diagram.';

  @override
  String get howToPlay => 'How to play';

  @override
  String get sessionComplete => 'Session complete';

  @override
  String get chordsPlayed => 'chords played';

  @override
  String get strums => 'strums';

  @override
  String get sessionSaved => 'Saved';

  @override
  String get keyLabel => 'Key';

  @override
  String get sections => 'Song structure';

  @override
  String get source => 'Source';

  @override
  String get difficultyAll => 'All';

  @override
  String get startCourse => 'Start';

  @override
  String get continueCourse => 'Continue';

  @override
  String get courseComplete => 'Course complete!';

  @override
  String get markComplete => 'Mark lesson complete';

  @override
  String get completed => 'Completed';

  @override
  String get teacherSettings => 'Teacher settings';

  @override
  String get leftHanded => 'Left-handed player';

  @override
  String get mirrorCamera => 'Mirror camera preview';

  @override
  String get showHandOverlay => 'Show hand tracking overlay';

  @override
  String get defaultTempo => 'Default tempo';

  @override
  String get website => 'Website';

  @override
  String get sourceCode => 'Source code on GitHub';

  @override
  String get privacyNote =>
      'Camera and microphone are processed on your device only. Nothing is uploaded.';

  @override
  String get recentSessions => 'Recent sessions';

  @override
  String get noSessions =>
      'No sessions yet. Start a quick practice to see your history here.';

  @override
  String get modeLearn => 'Learn';

  @override
  String get modeLearnHint => 'Waits for you on every chord';

  @override
  String get modePlayAlong => 'Play along';

  @override
  String get modePlayAlongHint => 'Chords change on the beat';

  @override
  String get setupTitle => 'Let\'s get set up';

  @override
  String get setupSubtitle =>
      'Turn on your camera and microphone so I can see your hands and hear your guitar.';

  @override
  String get setupTurnOn => 'Turn on camera & mic';

  @override
  String get setupStarting => 'Starting…';

  @override
  String get checkCamera => 'Camera is on';

  @override
  String get checkHandWaiting => 'Show your fretting hand';

  @override
  String get checkHandDone => 'I can see your hand';

  @override
  String get checkMicWaiting => 'Strum the strings once';

  @override
  String get checkMicDone => 'I can hear your guitar';

  @override
  String get trackingLoading => 'Loading hand tracking…';

  @override
  String get trackingError =>
      'Hand tracking is unavailable. I\'ll still listen.';

  @override
  String get hearIt => 'Hear it';

  @override
  String get skip => 'Skip';

  @override
  String get voiceCoach => 'Voice';

  @override
  String chordOf(int current, int total) {
    return 'Chord $current of $total';
  }

  @override
  String get holdChord => 'Hold it…';

  @override
  String get strumAgain => 'Strum again';

  @override
  String get listeningPaused => 'Listening paused';

  @override
  String get moreOptions => 'More options';

  @override
  String get speedSlow => 'Slow';

  @override
  String get speedMedium => 'Medium';

  @override
  String get speedSong => 'Song speed';

  @override
  String get fingerLegend => 'Finger colours';

  @override
  String get fingerIndex => 'Index';

  @override
  String get fingerMiddle => 'Middle';

  @override
  String get fingerRing => 'Ring';

  @override
  String get fingerPinky => 'Pinky';

  @override
  String youPlayed(int count, int total) {
    return 'You played $count of $total chords';
  }

  @override
  String bestStreak(int count) {
    return 'Best streak: $count';
  }

  @override
  String get trickyChords => 'Chords to practise';

  @override
  String get practiceTricky => 'Practise these';

  @override
  String get allClean => 'Every chord was clean!';

  @override
  String get savedToProgress => 'Saved to your progress';

  @override
  String inARow(int count) {
    return '$count in a row!';
  }

  @override
  String get readyHint =>
      'Press Start when you\'re ready. Take your time on each chord.';

  @override
  String get paused => 'Paused';

  @override
  String get tuner => 'Tuner';

  @override
  String get tunerTitle => 'Tune your guitar';

  @override
  String get tunerHint => 'Pluck one string at a time and let it ring.';

  @override
  String get tuneUp => 'Tune up';

  @override
  String get tuneDown => 'Tune down';

  @override
  String get inTune => 'In tune';

  @override
  String get tunerAuto => 'Auto';

  @override
  String get tunerListen => 'Start listening';

  @override
  String get playReference => 'Play note';

  @override
  String get tunerWaiting => 'Pluck a string…';

  @override
  String get startHere => 'Start here';

  @override
  String get firstChordTitle => 'Your first chord in 2 minutes';

  @override
  String get firstChordBody =>
      'Learn E minor, just two fingers. The teacher waits for you.';

  @override
  String get onboardingTitle1 => 'Pick a song or a chord';

  @override
  String get onboardingBody1 =>
      'Start a course, search for a song, or practise any chords you like.';

  @override
  String get onboardingTitle2 => 'The teacher watches and listens';

  @override
  String get onboardingBody2 =>
      'Coloured dots show where each finger goes. The microphone hears whether the chord is right.';

  @override
  String get onboardingTitle3 => 'Go at your own pace';

  @override
  String get onboardingBody3 =>
      'In Learn mode nothing moves until you play the chord. Speed up with Play along when you\'re ready.';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get practiceThisChord => 'Practise this chord';

  @override
  String get tapChordHint => 'Tap a chord to see and hear it';

  @override
  String get addSong => 'Add a song';

  @override
  String get addSongSubtitle =>
      'Paste a chord sheet you found online. The chords, sections and key are read for you.';

  @override
  String get pasteSheet => 'Paste a chord sheet';

  @override
  String get pasteSheetHint => 'Paste the chords and lyrics here';

  @override
  String get findChordsOnline => 'Find chords online';

  @override
  String get searchOnlineHint =>
      'Can\'t find it here? Search the web for the chords, copy the sheet and paste it in.';

  @override
  String get songTitleLabel => 'Song title';

  @override
  String get artistLabel => 'Artist (optional)';

  @override
  String get chordsFound => 'Chords found';

  @override
  String get noChordsFound =>
      'No chords yet. Paste a sheet that has chord names like G, Em or C.';

  @override
  String get saveToMySongs => 'Add to my songs';

  @override
  String get songAdded => 'Added to your songs';

  @override
  String get mySongs => 'My songs';

  @override
  String get addedByYou => 'Added by you';

  @override
  String get removeSong => 'Remove song';

  @override
  String get removeSongConfirm =>
      'Remove this song from this device? Your progress stays.';

  @override
  String get remove => 'Remove';

  @override
  String get cancel => 'Cancel';

  @override
  String get refreshSongs => 'Check for new songs';

  @override
  String get songsUpdated => 'Song list updated';

  @override
  String get keepLyrics => 'Keep the lyrics on this device';

  @override
  String get sectionsFound => 'Sections';

  @override
  String get displaySettings => 'What to show';

  @override
  String get showHandSkeleton => 'Hand tracking lines';

  @override
  String get showFingerGuides => 'Finger guides';

  @override
  String get showNeckGuide => 'Guitar neck guide';

  @override
  String get showSoundField => 'Music from the guitar';

  @override
  String get showCoachMessages => 'Coach messages';

  @override
  String get showBeatDots => 'Beat dots';

  @override
  String get showStatusChips => 'Status chips';

  @override
  String get cameraView => 'Camera view';

  @override
  String get mirrorPreview => 'Mirror the preview';
}
