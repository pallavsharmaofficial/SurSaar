# Security policy

SurSaar runs entirely on the user's device: camera and microphone streams are
processed in the browser / app and never transmitted; progress is stored
locally. The only network calls are fetching the public content JSON and, on
the web, the MediaPipe runtime and model from jsDelivr / Google storage.

If you find a vulnerability (for example in the ingestion workflow, which
fetches third-party pages in GitHub Actions), please open a private security
advisory on GitHub for `pallavsharmaofficial/SurSaar` rather than a public
issue. We aim to respond within a week.
