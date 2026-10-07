# Store listings

Everything a submission needs, so the console is only copy and paste.

| File | Where it goes |
|---|---|
| `play/en-IN/title.txt` | Play Console → Main store listing → App name |
| `play/en-IN/short_description.txt` | Short description (80 characters) |
| `play/en-IN/full_description.txt` | Full description (4,000 characters) |
| `play/hi-IN/*` | The same three fields under the Hindi (hi-IN) translation |
| `appstore/en-IN/metadata.txt` | App Store Connect, field by field |

The package name is `in.pallavsharma.sursaar`. Play fixes it at the first
upload and it can never be changed after that.

## Graphics

| Asset | Size | Source |
|---|---|---|
| App icon | 512 × 512 | `store/play/icon-512.png` |
| iOS icon | 1024 × 1024 | `assets/branding/icon-1024.png` |
| Feature graphic | 1024 × 500 | `store/play/feature-graphic.png` |
| Phone screenshots | 1080 × 1920, at least two | `store/screenshots/01-…06-*.png`, regenerated with `flutter test --update-goldens test/screenshots_test.dart` |

The icon and the feature graphic are drawn by `tools/branding/make_icon.py`.
The six phone screenshots are drawn by the app itself in a golden test, so no
device or emulator is needed: Home, a practice session (the teacher hearing a
chord), the Learn tab with the tutor's pick, the tuner, the song library and
Progress. Regenerate them with

    flutter test --update-goldens test/screenshots_test.dart

after any change to those screens. They are 24-bit RGB PNGs in the dark theme,
with Poppins read from `tools/branding/fonts/`, a learner seeded with a week of
practice, and a synthesised guitar played into the real chord and pitch
detectors. A plain `flutter test` does not compare pixels (text and dates differ
by day and by operating system); it checks that each screen builds without an
overflow or a spinner and that the stored PNG is 1080 × 1920. The emoji come
from the host's colour emoji font, so regenerate on a Mac, not on the CI runner.
The camera cannot be drawn without a camera, so the practice screenshot shows
the stage without a preview; add a real-device shot if you want one.

## What the Android app does and does not do

The listing says it, and the screenshots must not contradict it: hand tracking
(the coloured dots following each fingertip) exists in the web app only. On
Android and iOS the camera is a live preview beside the chord diagram, and the
teacher coaches by ear. Spoken coaching and the "Hear it" reference chords are
web only as well, so none of them appear in the listing, and none should appear
in a screenshot.

## Play data safety

Answer the form this way, because it is what the code does:

- **Does your app collect or share any of the required user data types?** No.
  Audio, the camera picture, the profile, progress and added songs are used or
  kept on the device and never transmitted.
- **Is all of the user data collected by your app encrypted in transit?** Not
  applicable. For the record, both downloads below are HTTPS.
- **Do you provide a way for users to request that their data be deleted?**
  Not applicable, since none is collected. On the device: remove an added song
  from its page, reset the tutor's memory on the Insights screen, clear the
  app's storage, or uninstall.
- **Data types:** none.
- **Permissions** (see `android/app/src/main/AndroidManifest.xml`):
  - `RECORD_AUDIO`: practice sessions and the tuner. The sound is analysed in
    memory and never recorded.
  - `CAMERA`: the live preview in a practice session. Nothing is saved or sent.
  - `INTERNET`: the two downloads below.
  - No photo or storage permission is declared: the profile photo comes from the
    system photo picker, so the Photos and videos permissions form is not needed.
- **Network requests the app makes**, both plain GETs with no account, no
  identifier and nothing the user typed or played:
  - the public song catalogue, from `raw.githubusercontent.com`, on launch and
    on pull-to-refresh;
  - the Poppins typeface, from Google Fonts (`fonts.gstatic.com`), the first
    time it is needed. The `google_fonts` package fetches it at runtime because
    the font is not bundled.

  Both servers see the device's IP address, as any download does. The app
  neither reads nor keeps it, which is why the answer above is No. If you would
  rather be conservative, this is the one place to say more; the privacy policy
  already discloses both requests.

## App content declarations

- **Privacy policy URL:** `https://pallavsharmaofficial.github.io/SurSaar/privacy.html`
  (also linked inside the app, on the Profile tab under About).
- **Ads:** none.
- **Target audience:** 13 and over. Choosing a younger band puts the app under
  the Families policy, which it has not been built or reviewed for.
- **App category:** Music & Audio.
- **Access to the whole app:** no login, so there are no credentials to give a
  reviewer.

## Content rating questionnaire

Everything "no": no violence, no sexual content, no profanity, no controlled
substances, no gambling, no user-generated content shared with other users, no
sharing of location or personal information. Song requests are public GitHub
issues, which happen outside the app in the user's browser.
