# Gitbox — Setup Notes (read before first push)

## 1. Gradle wrapper JAR
This scaffold includes `gradlew`, `gradlew.bat`, and `gradle/wrapper/gradle-wrapper.properties`
(pinned to Gradle 8.7), but **not** the binary `gradle/wrapper/gradle-wrapper.jar` — it can't be
generated in a sandboxed, network-disabled environment. Before your first push, run once on any
machine with Gradle installed (or let Android Studio do it on project open):

```bash
gradle wrapper --gradle-version 8.7
```

This generates `gradle/wrapper/gradle-wrapper.jar`. Commit it — the CI workflow calls `./gradlew`
directly and needs that jar present in the repo.

## 2. Release signing secrets (optional, for signed release APKs)
`app/build.gradle.kts` resolves signing from environment variables the workflow injects from repo
secrets. Add these under **Settings → Secrets and variables → Actions**:

| Secret                     | Purpose                                |
|-----------------------------|-----------------------------------------|
| `GITBOX_KEYSTORE_BASE64`    | `base64 -w0 release.jks` output         |
| `GITBOX_KEYSTORE_PASSWORD`  | Keystore password                       |
| `GITBOX_KEY_ALIAS`          | Signing key alias                       |
| `GITBOX_KEY_PASSWORD`       | Signing key password                    |

If these are absent, CI still builds — `assembleRelease` falls back to debug signing so the
pipeline never breaks for lack of secrets; just don't ship that APK.

## 3. What's intentionally NOT here yet
Per the approved scope: domain layer (use cases, repository interfaces), data layer (Ktor GitHub
API client, Git Data API blob/tree/commit orchestration, SAF file I/O), and the Terminal Shell /
File Explorer / Code Editor presentation modules. Awaiting your go-ahead.
