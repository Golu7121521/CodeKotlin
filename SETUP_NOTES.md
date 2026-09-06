# Gitbox — Setup Notes (read before first push)

## 1. Gradle wrapper JAR — now self-healing in CI
This scaffold ships `gradlew`, `gradlew.bat`, and `gradle/wrapper/gradle-wrapper.properties`
(pinned to Gradle 8.7), but the binary `gradle/wrapper/gradle-wrapper.jar` couldn't be generated in
this sandboxed, network-disabled environment. The workflow now handles this automatically:

- On every run, a step checks whether `gradle/wrapper/gradle-wrapper.jar` exists.
- If it's missing, it runs `gradle wrapper --gradle-version 8.7 --distribution-type bin` using the
  system Gradle already on the runner image, regenerating the jar.
- On non-PR events, that regenerated jar (plus `gradlew`/`gradlew.bat`) is committed straight back
  to the branch with `[skip ci]`, so subsequent pushes skip regeneration entirely.

If you'd rather not have CI commit to your branch, generate it once locally instead and delete the
"Regenerate Gradle wrapper jar" / "Commit regenerated wrapper jar" steps from the workflow:

```bash
gradle wrapper --gradle-version 8.7
git add gradle/wrapper/gradle-wrapper.jar gradlew gradlew.bat
git commit -m "chore: add gradle wrapper jar"
```

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
