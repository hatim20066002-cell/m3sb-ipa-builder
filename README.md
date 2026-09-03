# M3SB IPA Builder

Private template repository for manually building an **unsigned iOS IPA** on a GitHub-hosted macOS runner. The app now uses a local-only activation gate and does not contact an API server.

The demo uses XcodeGen to generate the Xcode project, builds with signing disabled, packages `Payload/HelloIPA.app` as an IPA, and uploads the artifact with one-day retention. No Apple certificates, API credentials, or signing secrets are used. The only accepted activation key is `M3SBxYAGAMI`; successful activation is remembered in the device Keychain.

## Test

Open **Actions → Build unsigned IPA → Run workflow**. The generated IPA is available as a short-retention workflow artifact. This repository is private.
