# Flutter and its plugins keep their entry points through reflection.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Microphone capture for the chord and pitch detectors, and the screen-awake
# lock held during practice, are resolved by name at runtime.
-keep class com.llfbandit.record.** { *; }
-keep class dev.fluttercommunity.plus.wakelock.** { *; }
