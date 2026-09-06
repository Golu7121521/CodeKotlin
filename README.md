# Synesthesia — Online Music Streaming App (Flutter)

A premium online music streaming app built with Flutter, using the
provided JioSaavn-style API for search and streaming, with local
favorites, playlists, recently played, and downloads.

## Features (Core release)

- **Home** — greeting, featured track hero card, horizontally scrolling
  sections (Trending, Frequently Resonating, Fresh Signal, Curated) built
  from real API search results plus your local Recently Played history.
- **Search** — debounced live search with loading/empty/error/offline states.
- **Full-screen Player ("The Canvas")** — album art, progress slider,
  shuffle/repeat, favorite, add-to-playlist, queue access.
- **Mini Player** — persistent above the bottom nav, tap to expand.
- **Queue** — view, remove, jump to any song, clear.
- **Library** — Liked Songs, Playlists (create/rename/delete/play-all/shuffle),
  Recently Played.
- **Download** — saves the highest-quality available audio stream to
  `Downloads/Synesthesia` on the device, with progress tracking.
- **Theme** — Dark, Light, and System Default, switchable from Settings.

## Building via GitHub Actions

This repo includes `.github/workflows/build.yml`, which automatically:

1. Checks out the code
2. Sets up Java 17 and Flutter (stable channel)
3. Runs `flutter pub get`
4. Builds a **release APK**
5. Uploads the APK as a downloadable workflow artifact named
   `synesthesia-release-apk`

**To build:** push this repository to GitHub (to the `main` or `master`
branch), or trigger the workflow manually from the **Actions** tab
("Run workflow" button, since `workflow_dispatch` is enabled).

Once the workflow finishes, open the completed run in the **Actions** tab
and download the `synesthesia-release-apk` artifact — it contains
`app-release.apk`, ready to install on an Android device.

## API Configuration

The base API URL is set in `lib/services/api_service.dart`:

```dart
static const String _baseUrl = 'https://example-api-dnva.onrender.com/api';
```

Change this if your API endpoint differs. The app expects:

- `GET {base}/search/songs?query=<text>` → 
  `{ success, data: { results: [ {...song...} ] } }`
- Each song object should include `name`, `artists.primary[].name`,
  `image[].url`, `downloadUrl[].url` (multiple qualities), and `duration`
  (seconds) — matching the JioSaavn-style shape this app was built against.

## Notes on scope

This is the **Core** release as scoped with the requester: Home, Search,
Player, Queue, Favorites/Playlists/Recently Played, Download, and
Dark/Light theme. Artist pages, Album pages, Explore/Charts screens,
Lyrics, and Autoplay-suggestions are intentionally deferred to a later
round to keep this build stable and easy to debug via CI (no local
Flutter SDK needed for iteration).
