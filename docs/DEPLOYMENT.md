# Deployment – GitHub Pages

The site and the web app are published from the `main` branch by
`.github/workflows/deploy-pages.yml`.

| URL | What |
|---|---|
| `https://pallavsharmaofficial.github.io/SurSaar/` | landing site (`site/`) |
| `https://pallavsharmaofficial.github.io/SurSaar/app/` | Flutter web app |
| `https://pallavsharmaofficial.github.io/SurSaar/content/sursaar_content.json` | catalogue the app fetches |

## One-time setup

1. Push this branch and merge it into `main` (or make it the default branch).
2. GitHub → **Settings → Pages → Build and deployment → Source: GitHub Actions**.
3. GitHub → **Settings → Actions → General → Workflow permissions: Read and write**
   (needed by `ingest-song.yml` to commit content and comment on issues).
4. Run the *Deploy website + web app* workflow once from the Actions tab (or
   push to `main`). The first build takes ~5 minutes.

The workflow builds with

```
flutter build web --release --base-href /SurSaar/app/ \
  --dart-define=SURSAAR_CONTENT_URL=https://pallavsharmaofficial.github.io/SurSaar/content/sursaar_content.json
```

If the repository is renamed or forked, the `--base-href` and content URL are
derived from `github.event.repository.name` / `github.repository_owner`, so
nothing needs editing.

## Local web development

```bash
flutter run -d chrome
```

Camera and microphone work on `localhost` (a secure context). To test the
production layout locally:

```bash
flutter build web --release --base-href /SurSaar/app/
mkdir -p dist/app dist/content && cp -R site/. dist/ && cp -R build/web/. dist/app/ && cp content/sursaar_content.json dist/content/
python3 -m http.server 8080 --directory dist   # open http://localhost:8080/SurSaar/ … or serve dist as /SurSaar
```

## Mobile builds

```bash
flutter build apk --release
flutter build ios --release      # needs signing in Xcode
```

Camera and microphone usage descriptions are already declared in
`ios/Runner/Info.plist` and `android/app/src/main/AndroidManifest.xml`.
