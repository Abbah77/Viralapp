/// ── AdHtmlTemplates ───────────────────────────────────────────────────────────
/// Generates self-contained HTML pages loaded into WebViews.
///
/// WHY HTML TEMPLATES?
/// Adsterra scripts expect to run inside a real browser context (document, 
/// window, DOM). A raw WebView.loadRequest to the script URL won't work —
/// the script needs a host HTML page to inject into.
/// We build that page ourselves, giving full control over background color,
/// viewport, and click interception.

class AdHtmlTemplates {

  /// Full-screen Popunder page.
  /// The Adsterra popunder script fires its ad immediately on load.
  /// We set background to match app dark theme so there's no white flash.
  static String popunder() => '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0"/>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 100%; height: 100%;
      background: #07070B;
      overflow: hidden;
    }
    /* Loading state — shown until ad fires */
    #loader {
      position: fixed;
      inset: 0;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 16px;
      color: rgba(245,245,255,0.4);
      font-family: sans-serif;
      font-size: 13px;
    }
    .ring {
      width: 48px; height: 48px;
      border: 2.5px solid rgba(255,255,255,0.08);
      border-top-color: #2196F3;
      border-radius: 50%;
      animation: spin 0.9s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div id="loader">
    <div class="ring"></div>
    <span>Loading ad…</span>
  </div>
  <!-- Adsterra Popunder script -->
  <script src="https://pl29592547.effectivecpmnetwork.com/d9/23/c8/d923c861139300c98028e2054bc85459.js"></script>
  <script>
    // Hide loader once script executes
    window.addEventListener('load', function() {
      var loader = document.getElementById('loader');
      if (loader) loader.style.display = 'none';
    });
  </script>
</body>
</html>
''';

  /// Native Banner page.
  /// Renders the 4:1 horizontal banner centered in a dark container.
  /// The container div ID must match exactly what Adsterra expects.
  static String nativeBanner() => '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0"/>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 100%; height: 100%;
      background: transparent;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    #container-37364927d22a8849c3cf562dd9cba921 {
      width: 100%;
      max-width: 100%;
    }
  </style>
</head>
<body>
  <script async="async" data-cfasync="false"
    src="https://pl29592548.effectivecpmnetwork.com/37364927d22a8849c3cf562dd9cba921/invoke.js">
  </script>
  <div id="container-37364927d22a8849c3cf562dd9cba921"></div>
</body>
</html>
''';
}
