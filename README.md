# AdBlock Browser (Android)

Simple WebView-based Android browser jisme:
- **Ad + tracker blocking** — `app/src/main/assets/adblock_hosts.txt` list ke hosts ki requests drop ho jaati hain (`shouldInterceptRequest`).
- **Popup / redirect blocking** — `window.open`, `target="_blank"` popups aur ad redirects (`onCreateWindow` returning `false`, non-http(s) scheme navigation block) automatically block hote hain.
- **Edge-to-edge fullscreen UI** — status bar/nav bar ke peeche content draw hota hai (`WindowCompat.setDecorFitsSystemWindows(false)`), sirf ek chhota address bar + WebView.
- **GitHub Actions se build** — koi Android Studio local install karne ki zaroorat nahi.

## GitHub par APK build kaise karein

1. Is poore folder ko apne GitHub repo mein push karein (root mein `build.gradle`, `settings.gradle`, `app/`, `.github/workflows/build.yml` hone chahiye).
2. GitHub par jaake **Actions** tab kholen → **Build APK** workflow ko dekhen. Push karte hi automatically chalega, ya "Run workflow" button se manually trigger karein.
3. Build complete hone ke baad, workflow run ke niche **Artifacts** section mein `adblock-browser-debug-apk` milega — usse download karke apne phone mein install kar sakte hain (unknown sources allow karna padega).

```bash
# Local push karne ke liye:
git init
git add .
git commit -m "Initial adblock browser app"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

## Block list customize karna

`app/src/main/assets/adblock_hosts.txt` mein ek line per domain hai. Naye ad-network domains add karne ke liye bas naya line daal dijiye (subdomains automatically match ho jaate hain, e.g. `doubleclick.net` blocked hone se `ads.doubleclick.net` bhi block hoga).

## Local build (agar Android Studio ho)

Agar kabhi local machine par Android Studio se bhi build karna ho, project ko simply open kar dein — Gradle sync khud gradlew wrapper generate/download kar lega. GitHub Actions workflow mein bhi yahi kaam `gradle wrapper --gradle-version 8.7` step karta hai, isliye repo mein `gradlew` file commit karne ki zaroorat nahi hai.

## Notes

- `minSdk 24` (Android 7.0+), `targetSdk 34`.
- App ka package name: `com.example.adblockbrowser` — chahें to `applicationId` (app/build.gradle) aur folder naam change kar sakte hain apne naam ke hisaab se.
- Yeh ek basic host-based blocker hai (EasyList jaisa full regex-rule engine nahi) — zyadatar common ad/tracker/redirect domains cover karta hai, but 100% ad-free guarantee nahi deta.
