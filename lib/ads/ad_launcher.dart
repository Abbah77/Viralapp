

import 'package:url_launcher/url_launcher.dart';

/// ── AdLauncher ────────────────────────────────────────────────────────────────
/// Smart URL router. Uses:
///   • Android → Custom Tabs (lightweight in-app browser, stays in app)
///   • iOS     → SFSafariViewController (same idea, Apple's version)
///   • Play Store / App Store URLs → routed to native store app
///   • Unknown deep links → fallback to in-app browser
///
/// The user NEVER leaves the app for web URLs.
/// Store URLs open the native store app directly.

class AdLauncher {
  static Future<void> open(String rawUrl) async {
    if (rawUrl.isEmpty) return;

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;

    // ── Store deep links ──────────────────────────────────────────────────────
    if (_isPlayStore(rawUrl)) {
      await _openPlayStore(uri);
      return;
    }
    if (_isAppStore(rawUrl)) {
      await _openAppStore(uri);
      return;
    }

    // ── Android / iOS in-app browser ─────────────────────────────────────────
    // LaunchMode.inAppBrowserView = Custom Tabs on Android, SFSafariVC on iOS
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(
          showTitle: false,           // cleaner — no URL bar clutter
        ),
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
      if (!launched) {
        // Fallback: external browser as last resort
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Silent fail — never crash the app because of an ad
    }
  }

  // ── Store detection ───────────────────────────────────────────────────────

  static bool _isPlayStore(String url) {
    return url.contains('play.google.com') ||
           url.contains('market://') ||
           url.startsWith('market:');
  }

  static bool _isAppStore(String url) {
    return url.contains('apps.apple.com') ||
           url.contains('itunes.apple.com') ||
           url.contains('appstore.com');
  }

  // ── Store launchers ───────────────────────────────────────────────────────

  static Future<void> _openPlayStore(Uri uri) async {
    // Try native Play Store app first
    String? packageId;
    if (uri.queryParameters.containsKey('id')) {
      packageId = uri.queryParameters['id'];
    }

    if (packageId != null) {
      final nativeUri = Uri.parse('market://details?id=$packageId');
      try {
        final launched = await launchUrl(
          nativeUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {}
    }

    // Fallback: open in Custom Tab
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  static Future<void> _openAppStore(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // iOS handles this natively
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }
}
