# M3SB IPA Builder

Private template repository for manually building an **unsigned iOS IPA** on a GitHub-hosted macOS runner. The workflow is intentionally manual-only (`workflow_dispatch`) until it is integrated with the M3SB API, package binding, Owner/Premium quotas, Telegram delivery, and automatic cleanup.

The demo uses XcodeGen to generate the Xcode project, builds with signing disabled, packages `Payload/HelloIPA.app` as an IPA, and uploads the artifact with one-day retention. No Apple certificates or signing secrets are used.

## Test

Open **Actions → Build unsigned IPA → Run workflow**. The generated IPA is available as a short-retention workflow artifact. This repository is private.
