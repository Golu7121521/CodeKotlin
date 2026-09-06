# AdBlock Browser (Android)

Simple WebView-based Android browser jisme:
- **Network-level blocking** — 120+ known ad/tracker/analytics domains ki requests block, PLUS Brave/uBlock-style **URL pattern matching**: same-domain ad/tracking paths (e.g. `youtube.com/pagead/`, `/api/stats/ads`, `/ptracking`) bhi block hote hain, sirf poore domain ka blacklist nahi.
- **Video black-screen fix** — WebView ki default user-agent string mein `; wv` flag hota hai jo site ko batata hai "yeh ek embedded app WebView hai", jiske jawab mein YouTube kabhi restricted player deta hai jisme video black dikhta hai (audio chalta rehta hai). Is app mein `wv` flag hata diya gaya hai + hardware layer force kiya gaya hai taaki video normally render ho.
- **Cosmetic filtering (Brave/uBlock style)** — CSS + JS rules jo har website par ad-shaped elements (`class*="ad-"`, `[data-ad-slot]`, `ins.adsbygoogle`, known ad iframes, YouTube ad overlays, etc.) ko hide/collapse kar dete hain, chahe woh domain block-list mein ho ya na ho. Yeh script `document-start` par hi inject hota hai (page load se pehle) jaise Brave apne filters apply karta hai, phir ek `MutationObserver` continuously naye ads ko bhi pakadta rehta hai.
- **YouTube ad-skip** — "Skip Ad" button auto-click, unskippable video ads mute+fast-forward.
- **Popup / redirect blocking** — `window.open`, `target="_blank"` popups aur non-http(s) scheme redirects block.
- **Edge-to-edge fullscreen UI** — status bar/nav bar ke peeche content draw hota hai, sirf ek chhota address bar + WebView.
- **GitHub Actions se build** — koi Android Studio local install karne ki zaroorat nahi.

> **Note:** Yeh Brave jaisa hi *approach* use karta hai (network blocklist + URL pattern rules + cosmetic filters), lekin Brave ka asli adblock-rust engine EasyList/EasyPrivacy ke lakhon regex rules compile karke chalata hai — is app mein ek curated (100+ domain + pattern) list + generic CSS patterns hain. Zyadatar banner/sidebar/pop-up ads aur skippable YouTube ads block/skip ho jaayenge.
>
> **Honest limitation:** YouTube ke kuch video ads ab same video stream (`googlevideo.com`) ke andar hi server-side stitch kar diye jaate hain, content ke sath ek hi stream mein. Aise ads ko bina real video tode WebView level par pura block karna practically possible nahi hai. Skip-button wale ads reliably skip ho jaate hain; kuch unskippable ads kabhi-kabhi dikh sakte hain.

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
