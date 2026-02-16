# SurSaar - Project Structure

## 📂 Complete Project Architecture

```
lib/
├── main.dart                           # App entry point
├── core/                               # Core application configuration
│   ├── app.dart                       # Main app widget with theming
│   ├── constants/
│   │   └── app_constants.dart         # App-wide constants
│   ├── routing/
│   │   └── app_router.dart            # GoRouter configuration with shell routes
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 theme with Google Fonts
│   └── utils/
│       └── chord_transposer.dart      # Chord transposition logic
│
├── models/                             # Data models
│   ├── lesson.dart                    # Lesson model with difficulty enum
│   ├── practice_session.dart          # Practice session tracking
│   ├── song.dart                      # Enhanced song model with metadata
│   └── user_progress.dart             # User progress tracking
│
├── repositories/                       # Data layer
│   ├── lesson_repository.dart         # Lesson data management
│   ├── progress_repository.dart       # SharedPreferences progress storage
│   └── song_repository.dart           # Song catalog with filtering
│
├── blocs/                              # State management (BLoC pattern)
│   ├── lesson/
│   │   ├── lesson_bloc.dart
│   │   ├── lesson_event.dart
│   │   └── lesson_state.dart
│   ├── progress/
│   │   ├── progress_bloc.dart
│   │   ├── progress_event.dart
│   │   └── progress_state.dart
│   └── song_finder/
│       ├── song_finder_bloc.dart
│       ├── song_finder_event.dart
│       └── song_finder_state.dart
│
├── screens/                            # UI screens
│   ├── shell/
│   │   └── app_shell_screen.dart      # Bottom navigation shell
│   ├── home/
│   │   └── home_screen.dart           # Song finder with animations
│   ├── songs/
│   │   └── song_detail_screen.dart    # Song details with tutorial link
│   ├── lessons/
│   │   └── lessons_screen.dart        # Lessons catalog
│   ├── practice/
│   │   └── practice_screen.dart       # AI practice mode (placeholder)
│   ├── progress/
│   │   └── progress_screen.dart       # User statistics dashboard
│   └── profile/
│       └── profile_screen.dart        # Settings and profile
│
├── widgets/                            # Reusable components
│   ├── capo_slider.dart               # Capo fret selector
│   ├── chord_chip.dart                # Chord selection chip
│   ├── difficulty_badge.dart          # Difficulty indicator
│   ├── enhanced_song_card.dart        # Rich song card with metadata
│   ├── lesson_card.dart               # Lesson card with progress
│   ├── progress_stat_card.dart        # Stats display card
│   └── section_header.dart            # Section title component
│
└── l10n/                               # Localization
    ├── app_en.arb                     # English translations
    ├── app_hi.arb                     # Hindi translations
    ├── app_localizations.dart         # Generated localization
    ├── app_localizations_en.dart      # Generated English
    └── app_localizations_hi.dart      # Generated Hindi
```

## 🎯 Key Features Implemented

### 1. **Song Finder (Home Screen)**
- Interactive chord selection with chips
- Capo position slider (0-7 frets)
- Real-time song filtering
- Animated card reveals
- Empty state handling
- Bottom navigation integration

### 2. **Song Details**
- Full song information display
- Transposed chords based on capo
- Difficulty badges with color coding
- BPM and duration display
- YouTube tutorial integration
- Practice mode launcher
- Share and favorite buttons (UI ready)

### 3. **Practice Mode**
- AI placeholder screen
- Real-time accuracy simulation
- Chord count tracking
- Mistake monitoring
- Animated microphone indicator
- Session statistics
- Save functionality

### 4. **Lessons Catalog**
- Structured lesson library
- Difficulty-based filtering
- Progress indicators
- Duration and topic count
- Completion badges
- Beautiful card layouts

### 5. **Progress Tracking**
- Practice time statistics
- Songs learned counter
- Daily streak tracking
- Lessons completed
- Level system with visual indicator
- Average accuracy display
- Grid layout stats cards

### 6. **Profile & Settings**
- User profile display
- Settings menu structure
- Notifications toggle (UI ready)
- Language selection (UI ready)
- Theme switcher (UI ready)
- Help and feedback options
- About section

## 🎨 Design System

### Theme
- **Primary Color**: Purple (#7B2CBF)
- **Material 3 Design System**
- **Google Fonts**: Poppins
- **Dark Mode Ready**: Full dark theme implemented
- **Responsive**: Adapts to all screen sizes

### Animations
- **Flutter Animate Package**: Used throughout
- Fade-in animations (400ms duration)
- Slide animations with curves
- Scale animations for cards
- Stagger delays for list items

### Components
- Large app bars with scroll effects
- Custom navigation bar with icons
- Rounded cards (16px radius)
- Chip-based selections
- Linear progress indicators
- Custom difficulty badges
- Stat cards with gradients

## 🧱 Architecture Patterns

### BLoC Pattern
- **Separation of Concerns**: UI, Business Logic, Data
- **Event-Driven**: User actions trigger events
- **State Management**: Immutable state objects
- **Repository Pattern**: Data abstraction layer

### Routing
- **GoRouter**: Declarative routing
- **Shell Routes**: Persistent bottom navigation
- **Named Routes**: Type-safe navigation
- **Deep Linking Ready**: URL-based navigation

### Localization
- **ARB Files**: Standard Flutter localization
- **Generated Code**: Type-safe translations
- **Bilingual Support**: English + Hindi
- **Extensible**: Easy to add more languages

## 📦 Dependencies

### Core
- `flutter_bloc: ^8.1.6` - State management
- `go_router: ^14.2.7` - Routing
- `equatable: ^2.0.5` - Value equality

### UI & Design
- `google_fonts: ^6.2.1` - Custom fonts
- `flutter_animate: ^4.5.0` - Animations
- `animations: ^2.0.11` - Material transitions
- `shimmer: ^3.0.0` - Loading effects

### Utilities
- `url_launcher: ^6.3.0` - External links
- `shared_preferences: ^2.2.3` - Local storage
- `cached_network_image: ^3.3.1` - Image caching
- `flutter_svg: ^2.0.10+1` - SVG support

## 🚀 Running the App

```bash
# Get dependencies
flutter pub get

# Run on iOS simulator
flutter run

# Run on Android emulator
flutter run

# Build for production
flutter build ios
flutter build apk
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## 🔮 Future Enhancements (AI Features)

### Ready for Implementation:
1. **Audio Analysis**: TensorFlow Lite integration point in PracticeScreen
2. **Computer Vision**: Camera feed for hand position tracking
3. **ML Models**: Chord detection and accuracy scoring
4. **Firebase Integration**: User authentication and cloud sync
5. **Recommendation Engine**: Personalized song suggestions
6. **Social Features**: Practice challenges and leaderboards

### Placeholder Locations:
- `lib/screens/practice/practice_screen.dart` - AI practice logic
- `lib/repositories/progress_repository.dart` - Analytics tracking
- `lib/models/practice_session.dart` - Session data for ML

## 📱 Screenshots & Demo

The app features:
- ✅ Smooth 60fps animations
- ✅ Material 3 design language
- ✅ Responsive layouts
- ✅ Accessibility support
- ✅ Production-ready code quality
- ✅ Clean architecture
- ✅ Comprehensive error handling
- ✅ Empty state management

## 🎵 Current Song Catalog

8 Bollywood songs included:
- O Sanam (Lucky Ali)
- Yaaron (KK)
- Channa Mereya (Arijit Singh)
- Tum Hi Ho (Arijit Singh)
- Tere Sang Yaara (Atif Aslam)
- Pal (KK)
- Tera Ban Jaunga (Akhil Sachdeva)
- Raabta (Arijit Singh)

Easy to expand in `song_repository.dart`!

---

**Built with ❤️ using Flutter & BLoC**
