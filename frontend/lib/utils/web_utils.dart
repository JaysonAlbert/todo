import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';

/// Handle Apple Sign-In callback URL for web platform
void handleAppleCallback(Function(Uri) onCallback) {
  if (kIsWeb) {
    final currentUrl = web.window.location.href;
    final uri = Uri.parse(currentUrl);

    // Check if this is an Apple Sign-In callback
    if (uri.path == '/auth/apple/callback') {
      onCallback(uri);
    }
  }
}

/// Clean up the URL after processing callback
void cleanupUrl() {
  if (kIsWeb) {
    web.window.history.pushState(null, '', '/');
  }
}
