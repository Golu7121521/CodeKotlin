# FlutIDE

Ek lightweight mobile Flutter code editor — naya Flutter project banaiye,
code likhiye (color syntax highlighting ke saath), aur GitHub Actions ki
madad se APK build kariye — sab kuch phone/tablet se hi.

## Features
- **New Project** → standard Flutter folder structure (`lib/`, `test/`,
  `android/`, `ios/`, `web/`) + `.github/workflows/flutter_build.yml`
  automatically ban jaata hai.
- **Code Editor** → Dart/YAML/XML/JSON syntax color-highlighting (no error
  checking / linting by design — sirf coloring).
- **Import / Export** → kisi bhi project ko `.zip` se import karein ya
  apna project `.zip` mein export karein.
- **Terminal** → basic commands (`ls`, `cd`, `mkdir`, `touch`, `rm`, `cat`,
  `echo`, `clear`) + build commands:
  - `push` → project files ko GitHub repo mein upload karta hai (Contents API)
  - `build` → GitHub Actions workflow trigger karta hai
  - `status` → latest build status + APK artifact link dikhata hai
- **Settings** → default template files (`main.dart`, `pubspec.yaml`,
  workflow file, etc.) ko customize kar sakte hain — naya project banate
  waqt wahi content use hoga.
- Compact UI — chhote toolbar icons/buttons taaki UI bhaari na lage.

## Setup (build this app yourself)
1. `flutter pub get`
2. Local run: `flutter run`
3. Ya GitHub Actions se build: push this repo, then run the
   **Build Flutter APK** workflow (Actions tab → Run workflow), or push to
   `main`. Download the APK from the workflow run's Artifacts section.

## GitHub token scopes needed (for the in-app push/build feature)
Create a Personal Access Token (classic) with `repo` and `workflow` scopes,
paste it in Settings inside a project → GitHub Setup.

## Notes on generated projects
Every project created inside FlutIDE ships with Android build files
pre-configured for Gradle 8.14 / AGP 8.11.1 / Kotlin 2.2.20 / Java 17,
`minifyEnabled false`, no ABI filters, and a safe fallback launcher icon —
so the very first GitHub Actions build has the best chance of succeeding
without manual Gradle troubleshooting.
