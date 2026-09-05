# VS Code Mobile IDE & CI/CD Terminal

Ultra-lightweight native Kotlin Android terminal app for cloning, editing, and
pushing GitHub repos, and driving GitHub Actions builds, entirely from your phone.

## One-time setup (before first push to GitHub)

Gradle's wrapper jar (`gradle/wrapper/gradle-wrapper.jar`) is a binary file and
is not included here since it can't be generated as plain text. Before your
first commit, run this once on any machine with Gradle installed (or in a
throwaway Actions step) from the project root:

```bash
gradle wrapper --gradle-version 8.9
```

This generates `gradlew`, `gradlew.bat`, and `gradle/wrapper/gradle-wrapper.jar`.
Commit all three alongside the rest of this project. After that, every push to
`main` (or a manual "Run workflow" click) builds `app/build/outputs/apk/release/*.apk`
via `.github/workflows/build.yml` and uploads it as a workflow artifact.

## In-app usage

1. Launch the app — no permission prompts needed; the workspace lives in the app's own private-but-app-scoped storage.
2. `token <your_github_pat>` — saves a PAT locally (needs `repo` and `workflow` scopes).
3. `clone owner/repo` — downloads and unzips into the app's own workspace folder (`Android/data/com.vsm.ide/files/Vscode/owner_repo`), which needs no special permission on any Android version.
4. `files` — browse the workspace; tap a file to open it in the editor; SAVE writes it back to disk.
5. `push owner/repo path/to/file.kt "commit message"` — pushes a single file.
6. `pushall owner/repo "commit message"` — pushes every changed file via the Git Data API tree flow.
7. `build owner/repo build.yml` — triggers that workflow via `workflow_dispatch`.
8. `status owner/repo` — shows the latest run's status/conclusion.
9. `download owner/repo` — opens the repo's Actions page in your browser to grab build artifacts.

## Notes

- Release builds are signed with the AGP-generated debug keystore so CI can
  produce an installable APK with zero keystore setup. Swap in your own
  release signing config before shipping to production/Play Store.
- Target ABI is restricted to `arm64-v8a` and resources/code are shrunk to
  keep the APK under ~3MB.
