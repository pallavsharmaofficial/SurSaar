# Launching

The app is free on every platform, with no advertising, no subscription and
nothing to buy inside it. This is what is already done and what still needs a
human.

## Already done in this repository

- **Icons** for Android (legacy, adaptive and monochrome), iOS, and the web,
  generated from `tools/branding/make_icon.py`. The mark is a chord box: a card
  with the nut, strings and frets, and three finger dots in the app's own
  finger colours. Below about sixty pixels the small renders drop to three
  strings and no fret lines so the shape still reads at favicon size.
- **Splash screens** for Android (including the Android 12 style) and iOS. The
  app is dark only, so the launch screen is the same navy in either mode.
- **Web app manifest** with name, description, categories, maskable icons and
  four shortcuts (tuner, songs, learn, progress), so the app installs to a
  phone's home screen from the browser.
- **Page metadata**: title, description, canonical link, Open Graph and Twitter
  cards with a generated social image, `robots.txt` and `sitemap.xml`.
- **Android**: app label in English and Hindi, a real application id
  (`in.pallavsharma.sursaar`, Play refuses `com.example`), microphone, camera
  and internet permissions with the camera and microphone marked not required,
  no photo or storage permission because the profile photo uses the system
  picker, `minSdk` 24, R8 shrinking with rules for the plugins, and release
  signing wired to `android/key.properties`.
- **iOS**: display name, Hindi and English localisations, the three usage
  descriptions, and the encryption declaration.
- **Privacy policy** and **terms** published at `/privacy.html` and
  `/terms.html`, linked from the site footer and from the app's Profile tab.
  The policy discloses the two downloads the app makes: the song catalogue from
  GitHub, and the Poppins font from Google Fonts.
- **Store listings** in English and Hindi, inside `store/`, with the Play data
  safety answers and the content rating notes written out.

## What still needs you

1. **A signing key for Android.** Make it once and keep it safe: losing it
   means never updating the listing again.

   ```bash
   keytool -genkey -v -keystore ~/sursaar-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Then write `android/key.properties`, which git ignores:

   ```properties
   storePassword=…
   keyPassword=…
   keyAlias=upload
   storeFile=/Users/you/sursaar-upload.jks
   ```

   Build the bundle with `flutter build appbundle --release`. Without
   `key.properties` it builds, but signed with the debug key, which Play will
   not accept.

2. **A Google Play developer account** — a one-time 25 USD registration. Play
   also asks for a public support email address; use a personal one, not a
   company address.

3. **An Apple Developer account** for the App Store — 99 USD a year. The web
   app needs none of this and reaches an iPhone through the browser in the
   meantime.

4. **Screenshots.** The one asset that cannot come out of this repository.
   Two or more at 1080 × 1920; `store/README.md` lists which screens to shoot
   and what must stay out of them.

5. **Two decisions about the app itself**, neither blocking:
   - The Poppins font is fetched from Google Fonts at runtime and not bundled,
     which is why the policy names Google. Bundling it and switching runtime
     fetching off would remove that request and make the first launch look right
     offline.
   - Hand tracking exists on the web only. The listing says so; if it reaches
     Android and iOS, the description and `store/README.md` change with it.

6. **A run on a real phone.** The release build is minified with R8, and the
   rules in `android/app/proguard-rules.pro` were checked only by building. Open
   a release build once and start a practice session and the tuner before
   uploading.

## Changing the icon

```bash
python3 tools/branding/make_icon.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

`flutter_launcher_icons` also rewrites one setting in
`ios/Runner.xcodeproj/project.pbxproj`
(`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` becomes
`AppIcon`). Put it back to `YES` before committing.

The script sets the og-image and feature graphic in Poppins, from
`tools/branding/fonts/`, in Latin only: this Pillow has no Raqm, and unshaped
Devanagari puts the matras in the wrong place.

## Checks before each release

```bash
flutter analyze
flutter test
flutter build web --release --base-href "/SurSaar/app/"
flutter build appbundle --release
```

CI runs the first two and the web build on every push, and the Pages workflow
runs all of them plus the deployment on `main`.

## Versioning

`pubspec.yaml` holds `version: x.y.z+build`, and `AppConstants.version` in
`lib/core/constants/app_constants.dart` shows the same number on the Profile
tab. The build number must rise with every upload to either store; the version
name is what people see.
