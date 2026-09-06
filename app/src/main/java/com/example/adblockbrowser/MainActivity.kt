package com.example.adblockbrowser

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.ProgressBar
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import com.example.adblockbrowser.databinding.ActivityMainBinding
import java.io.ByteArrayInputStream
import java.net.URI

class MainActivity : AppCompatActivity() {

    // ---- Universal cosmetic filtering ----
    // This mirrors what Brave/uBlock Origin call "cosmetic filters": generic
    // CSS + JS that hides ad-shaped elements on ANY website, not just known
    // ad-network hosts. Runs on every page.
    private val universalAdBlockJs = """
        (function() {
            if (window.__cosmeticAdBlockInjected) return;
            window.__cosmeticAdBlockInjected = true;

            var css = [
                // Generic ad container patterns used across most sites
                '[class*="ad-banner" i]','[id*="ad-banner" i]',
                '[class^="ad-" i]','[class*=" ad-" i]','[id^="ad-" i]','[id*=" ad-" i]',
                '[class*="advert" i]','[id*="advert" i]',
                '[class*="sponsor" i]','[id*="sponsor" i]',
                '[class*="google-ad" i]','[id*="google-ad" i]',
                '[class*="banner-ad" i]','[id*="banner-ad" i]',
                '[class*="ad-container" i]','[id*="ad-container" i]',
                '[class*="ad-wrapper" i]','[id*="ad-wrapper" i]',
                '[class*="ad-slot" i]','[id*="ad-slot" i]',
                '[class*="ad_unit" i]','[id*="ad_unit" i]',
                '[class*="adsbygoogle" i]',
                'ins.adsbygoogle',
                'div[id^="div-gpt-ad"]',
                'div[id*="google_ads"]',
                'iframe[src*="doubleclick.net" i]',
                'iframe[src*="googlesyndication.com" i]',
                'iframe[src*="googleadservices.com" i]',
                'iframe[id^="google_ads_iframe"]',
                'iframe[src*="ads.pubmatic.com" i]',
                'iframe[src*="amazon-adsystem.com" i]',
                'iframe[src*="taboola" i]',
                'iframe[src*="outbrain" i]',
                '.taboola-widget','.OUTBRAIN','.trc_related_container',
                '.fb-ad','.adsbygoogle-noablate',
                '[data-ad-client]','[data-ad-slot]',
                '.ad-placement','.ad-slot-container','.dfp-ad',
                'ytd-companion-slot-renderer','ytd-ad-slot-renderer',
                'ytd-display-ad-renderer','ytd-promoted-sparkles-web-renderer',
                'ytd-promoted-video-renderer','#masthead-ad',
                '.video-ads','.ytp-ad-module','.ytp-ad-overlay-container',
                '.ytp-ad-text-overlay'
            ].join(',');

            var style = document.createElement('style');
            style.id = '__adblock_cosmetic_style';
            style.textContent = css + ' { display: none !important; visibility: hidden !important; height: 0 !important; }';
            (document.head || document.documentElement).appendChild(style);

            function collapseEmptyAdFrames() {
                document.querySelectorAll('iframe').forEach(function(f) {
                    var src = f.src || '';
                    if (/doubleclick|googlesyndication|googleadservices|adsystem|pubmatic|taboola|outbrain|criteo|rubiconproject|openx|adnxs/i.test(src)) {
                        f.style.display = 'none';
                        var p = f.parentElement;
                        if (p && p.children.length === 1) p.style.display = 'none';
                    }
                });
            }

            function skipYoutubeAds() {
                var skipSelectors = [
                    '.ytp-ad-skip-button', '.ytp-ad-skip-button-modern',
                    '.ytp-skip-ad-button', 'button.ytp-ad-overlay-close-button'
                ];
                skipSelectors.forEach(function(sel) {
                    var btn = document.querySelector(sel);
                    if (btn) btn.click();
                });
                var adShowing = document.querySelector('.ad-showing, .ad-interrupting');
                var player = document.querySelector('.html5-video-player video, video');
                if (adShowing && player && player.duration) {
                    try {
                        player.currentTime = player.duration;
                        player.muted = true;
                        player.playbackRate = 16;
                    } catch (e) {}
                }
            }

            function run() {
                collapseEmptyAdFrames();
                skipYoutubeAds();
            }

            run();
            setInterval(run, 500);

            var observer = new MutationObserver(run);
            observer.observe(document.documentElement, { childList: true, subtree: true });
        })();
    """.trimIndent()

    private lateinit var binding: ActivityMainBinding
    private val blockedHosts = HashSet<String>()
    private val emptyResponse: WebResourceResponse by lazy {
        WebResourceResponse("text/plain", "utf-8", ByteArrayInputStream(ByteArray(0)))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ---- Edge-to-edge fullscreen ----
        WindowCompat.setDecorFitsSystemWindows(window, false)

        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        applyEdgeToEdgeInsets()
        loadBlockList()
        setupWebView()
        setupUi()

        val startUrl = "https://www.google.com"
        binding.urlBar.setText(startUrl)
        binding.webView.loadUrl(startUrl)
    }

    /** Let content draw behind status/nav bars, but push the address bar down
     *  below the status bar and the WebView above the nav bar / cutouts. */
    private fun applyEdgeToEdgeInsets() {
        ViewCompat.setOnApplyWindowInsetsListener(binding.root) { _, insets ->
            val bars = insets.getInsets(
                WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
            )
            val extraPadding = (16 * resources.displayMetrics.density).toInt()
            binding.addressBar.updatePadding(
                top = bars.top + extraPadding,
                left = bars.left + extraPadding,
                right = bars.right + extraPadding
            )
            binding.webView.updatePadding(
                left = bars.left,
                right = bars.right,
                bottom = bars.bottom
            )
            insets
        }
    }

    private fun loadBlockList() {
        try {
            assets.open("adblock_hosts.txt").bufferedReader().useLines { lines ->
                lines.forEach { line ->
                    val h = line.trim()
                    if (h.isNotEmpty() && !h.startsWith("#")) blockedHosts.add(h)
                }
            }
        } catch (e: Exception) {
            Log.e("AdBlockBrowser", "Failed to load block list", e)
        }
    }

    private fun isAdHost(url: String): Boolean {
        return try {
            val host = URI(url).host?.lowercase() ?: return false
            blockedHosts.any { host == it || host.endsWith(".$it") }
        } catch (e: Exception) {
            false
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView() {
        val webView = binding.webView
        val settings = webView.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.loadWithOverviewMode = true
        settings.useWideViewPort = true
        settings.setSupportZoom(true)
        settings.builtInZoomControls = true
        settings.displayZoomControls = false
        settings.mediaPlaybackRequiresUserGesture = true
        settings.javaScriptCanOpenWindowsAutomatically = false

        // ---- Block popups / new windows (a common ad-redirect vector) ----
        webView.setOnLongClickListener(null)

        // Inject the cosmetic filter as early as possible (before the page's
        // own scripts run), similar to how Brave/uBlock apply filters at
        // document-start rather than waiting for page load to finish.
        if (androidx.webkit.WebViewFeature.isFeatureSupported(androidx.webkit.WebViewFeature.DOCUMENT_START_SCRIPT)) {
            androidx.webkit.WebViewCompat.addDocumentStartJavaScript(
                webView,
                universalAdBlockJs,
                setOf("*")
            )
        }

        webView.webViewClient = object : WebViewClient() {
            override fun shouldInterceptRequest(
                view: WebView,
                request: WebResourceRequest
            ): WebResourceResponse? {
                val url = request.url.toString()
                return if (isAdHost(url)) emptyResponse else super.shouldInterceptRequest(view, request)
            }

            override fun shouldOverrideUrlLoading(
                view: WebView,
                request: WebResourceRequest
            ): Boolean {
                val url = request.url.toString()
                // Block navigation straight to a known ad/redirect host.
                if (isAdHost(url)) return true
                // Only allow http/https navigation inside the WebView; anything
                // else (intent://, market://, custom app schemes used by ad
                // redirects) is dropped instead of leaving the browser.
                val scheme = request.url.scheme?.lowercase()
                if (scheme != "http" && scheme != "https") return true
                return false
            }

            override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) {
                binding.urlBar.setText(url)
                binding.progressBar.visibility = View.VISIBLE
                view.evaluateJavascript(universalAdBlockJs, null)
            }

            override fun onPageFinished(view: WebView, url: String) {
                binding.urlBar.setText(url)
                binding.progressBar.visibility = View.GONE
                view.evaluateJavascript(universalAdBlockJs, null)
            }
        }

        webView.webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(view: WebView, newProgress: Int) {
                binding.progressBar.progress = newProgress
            }

            // Refuse to open any new window/tab that ad scripts try to spawn
            // (window.open, target=_blank popups, etc.)
            override fun onCreateWindow(
                view: WebView,
                isDialog: Boolean,
                isUserGesture: Boolean,
                resultMsg: android.os.Message?
            ): Boolean {
                return false
            }
        }
    }

    private fun setupUi() {
        binding.btnBack.setOnClickListener {
            if (binding.webView.canGoBack()) binding.webView.goBack()
        }
        binding.btnReload.setOnClickListener { binding.webView.reload() }

        binding.urlBar.setOnEditorActionListener { _, actionId, event ->
            val isEnter = event != null && event.keyCode == KeyEvent.KEYCODE_ENTER
            if (actionId == EditorInfo.IME_ACTION_GO || isEnter) {
                navigateFromInput(binding.urlBar.text.toString())
                true
            } else {
                false
            }
        }
    }

    private fun navigateFromInput(input: String) {
        val trimmed = input.trim()
        if (trimmed.isEmpty()) return
        val looksLikeUrl = trimmed.contains(".") && !trimmed.contains(" ")
        val target = when {
            trimmed.startsWith("http://") || trimmed.startsWith("https://") -> trimmed
            looksLikeUrl -> "https://$trimmed"
            else -> "https://www.google.com/search?q=" + java.net.URLEncoder.encode(trimmed, "UTF-8")
        }
        binding.webView.loadUrl(target)
    }

    override fun onBackPressed() {
        if (binding.webView.canGoBack()) {
            binding.webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}
