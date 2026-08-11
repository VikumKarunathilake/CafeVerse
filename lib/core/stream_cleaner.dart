import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_win_floating/webview_win_floating.dart';

/// Helper utility that removes watermarks, branding overlays, and prevents
/// external redirects from the embedded video player.
class StreamCleaner {
  StreamCleaner._();

  /// Validates whether a navigation request inside the streaming webview should be permitted.
  /// Blocks redirects to external websites, homepages, popups, and ad tracking pages.
  static bool isAllowedNavigation(String requestUrl, String baseEmbedUrl) {
    final url = requestUrl.toLowerCase().trim();
    final base = baseEmbedUrl.toLowerCase().trim();

    // Allow base player embed url
    if (url.isNotEmpty && (url == base || url.startsWith(base))) {
      return true;
    }

    // Allow streaming embed paths and subpaths
    if (url.startsWith('https://vaplayer.ru/embed/') ||
        url.startsWith('http://vaplayer.ru/embed/')) {
      return true;
    }

    // Allow media chunks, streaming playlists, video blobs, data URIs and blank frames
    if (url.contains('.m3u8') ||
        url.contains('.mp4') ||
        url.contains('.ts') ||
        url.startsWith('blob:') ||
        url.startsWith('data:') ||
        url.startsWith('about:blank') ||
        url == 'about:blank') {
      return true;
    }

    debugPrint('[StreamCleaner] Blocked unauthorized player redirection to: $requestUrl');
    return false;
  }

  /// JavaScript payload injected into the player WebView to suppress watermarks,
  /// disable redirect links, override window.open, and neutralize top-right branding.
  static const String watermarkBlockerJs = r'''
(function() {
  try {
    // 1. Prevent external window popups and redirect attempts
    window.open = function() {
      console.log('[StreamCleaner] Blocked window.open attempt');
      return null;
    };

    // 2. Inject aggressive CSS rules to hide watermark, logo, brand and redirect elements
    if (!document.getElementById('cafeverse-clean-stream-style')) {
      var style = document.createElement('style');
      style.id = 'cafeverse-clean-stream-style';
      style.textContent = `
        /* Hide all watermarks, branding, and player external links */
        [class*="watermark" i],
        [id*="watermark" i],
        [class*="logo" i]:not([class*="control"]):not([class*="btn"]):not([class*="play"]):not([class*="sound"]):not([class*="volume"]),
        [id*="logo" i]:not([id*="control"]):not([id*="btn"]):not([id*="play"]):not([id*="sound"]):not([id*="volume"]),
        [class*="brand" i],
        [id*="brand" i],
        .jw-logo,
        .vjs-watermark,
        .vjs-logo,
        .player-logo,
        .branding,
        a[href*="vaplayer"],
        a[target="_blank"] {
          display: none !important;
          visibility: hidden !important;
          opacity: 0 !important;
          pointer-events: none !important;
          width: 0 !important;
          height: 0 !important;
          max-width: 0 !important;
          max-height: 0 !important;
          position: absolute !important;
          left: -9999px !important;
          top: -9999px !important;
          clip: rect(0, 0, 0, 0) !important;
          overflow: hidden !important;
        }
      `;
      (document.head || document.documentElement).appendChild(style);
    }

    // 3. Scan DOM and neutralize any clickable watermark / external link elements
    function neutralizeWatermarks() {
      try {
        // Disarm external anchor tags
        var anchors = document.querySelectorAll('a');
        for (var i = 0; i < anchors.length; i++) {
          var a = anchors[i];
          var href = (a.href || '').toLowerCase();
          if (href && !href.includes('/embed/')) {
            a.removeAttribute('href');
            a.removeAttribute('target');
            a.style.display = 'none';
            a.style.pointerEvents = 'none';
            a.onclick = function(e) {
              e.preventDefault();
              e.stopPropagation();
              return false;
            };
          }
        }

        // Specifically detect top-right quadrant overlay elements
        var elements = document.querySelectorAll('div, a, img, svg, span, p');
        var winWidth = window.innerWidth || document.documentElement.clientWidth || 800;
        for (var j = 0; j < elements.length; j++) {
          var el = elements[j];
          var rect = el.getBoundingClientRect();
          // Element situated in the top-right corner region (top < 90px, within 160px from right)
          if (rect.top >= 0 && rect.top <= 90 && (winWidth - rect.right) <= 160 &&
              rect.width > 0 && rect.width < 320 && rect.height > 0 && rect.height < 140) {
            var cls = (el.className || '').toString().toLowerCase();
            var id = (el.id || '').toLowerCase();
            var tag = el.tagName.toLowerCase();
            if (cls.includes('watermark') || cls.includes('logo') || cls.includes('brand') ||
                id.includes('watermark') || id.includes('logo') || id.includes('brand') ||
                tag === 'a' || tag === 'img' || tag === 'svg') {
              el.style.display = 'none';
              el.style.pointerEvents = 'none';
              el.style.visibility = 'hidden';
              el.style.opacity = '0';
            }
          }
        }
      } catch (e) {}
    }

    neutralizeWatermarks();

    // Repeat periodically during player startup
    var count = 0;
    var timer = setInterval(function() {
      neutralizeWatermarks();
      count++;
      if (count > 25) clearInterval(timer);
    }, 500);

    // Dynamic observation
    if (window.MutationObserver && document.body) {
      var obs = new MutationObserver(function() {
        neutralizeWatermarks();
      });
      obs.observe(document.body, { childList: true, subtree: true });
    }
  } catch (e) {}
})();
''';

  /// Applies the watermark blocker script to the active WebViewController or WinWebViewController.
  static void apply({
    WinWebViewController? winController,
    WebViewController? mobileController,
  }) {
    try {
      if (winController != null) {
        winController.runJavaScript(watermarkBlockerJs).catchError((_) {});
      } else if (mobileController != null) {
        mobileController.runJavaScript(watermarkBlockerJs).catchError((_) {});
      }
    } catch (_) {}
  }
}
