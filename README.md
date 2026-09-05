# MovieStream

A next-gen movie streaming client built in Flutter: TMDB-powered discovery, a cinematic native video player, and offline downloads, all built around an OLED-true-black design system.

## Content and Compliance Note

This app performs no scraping, no third-party site sniffing, and no request-header spoofing of any kind. Its two data pipelines are entirely separate:

- Catalog metadata (titles, posters, backdrops, cast, ratings) comes exclusively from TMDB's public API. TMDB never serves video files, only metadata.
- Playback is served exclusively through StreamResolver (lib/services/stream_resolver.dart), which returns only URLs it was explicitly configured to know about, either a small built-in demo catalog of public sample clips (for out-of-the-box testing) or your own authorized backend, which you implement.

If you fork this project to serve real licensed content, you are responsible for ensuring you hold the rights to stream that content and that your backend properly enforces entitlement/DRM as required by your content agreements.

## Features

- Design system: OLED-true-black palette, 1.25 modular type scale, 8pt spacing grid, named easing curves/durations, all as reusable Dart tokens in lib/theme/
- Discovery: TMDB trending, Bollywood/Hindi cinema discovery, genre browsing, predictive search with pagination, resilient fallback catalog on network failure
- Home screen: hero banner with gradient scrim, parallax-scaling content rows, Continue Watching
- Movie details: shared-element (Hero) backdrop transition, metadata bar, cast carousel
- Cinematic player: layered Z-index architecture (video, subtitles, controls, gesture overlay), double-tap seek with spring-animated feedback, audio-focus-loss pause/dim, multi-server fallback plus manual server switcher, resume-from-last-position
- Downloads: Queued -> Downloading -> Paused -> Downloaded -> Expired state machine, glowing progress-ring thumbnails, Dio-based transfer with cancellation
- Accessibility and performance: reduced-motion/effects mode (manual toggle, extensible to an automatic low-end-device heuristic), shimmer loading states with a static fallback

## Requirements

- Flutter 3.27+ (Dart 3.3+)
- Android SDK: compileSdk/targetSdk 36, minSdk 21
- JDK 17
- Kotlin 2.2.20, AGP 8.11.1, Gradle 8.14

## Project Structure

```
lib/
  main.dart               Entry point
  app.dart                 MaterialApp + custom page transitions
  constants/                API configuration
  models/                   Movie, StreamSource, DownloadItem
  services/                 TMDB API client, StreamResolver, storage, downloads
  providers/                App state (Provider/ChangeNotifier)
  theme/                    Design tokens: colors, typography, spacing, motion
  widgets/                  Reusable UI components
  screens/                  Home, Details, Search, Player, Downloads, Profile

android/                   Native Android project (Kotlin, Gradle)
test/
  unit/                    Model and service unit tests
  widget/                  Widget tests
.github/workflows/         CI: builds a single arm64-v8a release APK
```

## Setup

```bash
flutter pub get
```

## Configuring Real Playback

By default, StreamResolver runs in demo mode against a small built-in catalog of public sample video clips, so the full pipeline (resolve -> player -> download) works immediately without any backend.

To connect your own authorized content source, edit lib/screens/player/video_player_screen.dart:

```dart
final _resolver = StreamResolver(
  useDemoCatalog: false,
  backendBaseUrl: 'https://api.yourservice.com',
);
```

Then implement StreamResolver._fetchFromBackend to call GET {backendBaseUrl}/stream/{movieId} against your own API, which should validate the user's entitlement and return a signed/authorized media URL.

## Build Instructions

### Debug

```bash
flutter run
```

### Release APK (arm64-v8a only)

```bash
flutter build apk --release --target-platform android-arm64
```

Output: build/app/outputs/flutter-apk/app-release.apk

The release build signs with the debug keystore so CI produces an installable APK immediately, and deliberately runs with minifyEnabled false (see the comment in android/app/build.gradle for why: R8 minification has a known failure mode with Flutter plugin classes referenced only via reflection). Replace the signing config with your own keystore before publishing.

## GitHub Actions

.github/workflows/flutter_build.yml builds a single arm64-v8a release APK on every push to main/master. It generates the Gradle wrapper from a real, freshly-downloaded Gradle binary in an isolated scratch directory (not this repo's android/ folder) before building, which avoids every wrapper-related failure mode encountered in earlier iterations of this CI setup (broken JVM-arg quoting in a hand-written gradlew, invalid/corrupted wrapper jars, and plugins {} block ordering errors from Gradle trying to evaluate app/build.gradle just to generate a wrapper).

Download the built APK from the Actions tab, the workflow run, Artifacts, app-release-arm64.apk.

## Testing

```bash
flutter test
```

## Troubleshooting

| Issue | Fix |
|---|---|
| flutter.sdk not set in local.properties | Let Android Studio regenerate android/local.properties, or set flutter.sdk=/path/to/flutter yourself. |
| Player shows "isn't available to stream" | The requested movie ID has no entry in StreamResolver's demo catalog and no backend is configured, see "Configuring Real Playback" above. |
| Home screen rows are empty | TMDB may be unreachable; the app falls back to a small embedded catalog automatically, but a completely offline first launch will show that fallback data rather than live TMDB results. |
