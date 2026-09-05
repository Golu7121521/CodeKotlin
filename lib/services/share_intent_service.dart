import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Listens for URLs shared into the app via the Android share sheet
/// (e.g. "Share" -> "All Video Downloader" from another app), and via
/// the app being launched cold with a shared link.
class ShareIntentService {
  StreamSubscription? _mediaStreamSub;

  /// Registers [onUrlReceived] for both the initial cold-start shared
  /// link (if any) and any subsequent shares while the app is running.
  Future<void> initialize({required void Function(String url) onUrlReceived}) async {
    try {
      final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
      final initialUrl = _extractUrl(initialMedia);
      if (initialUrl != null) {
        onUrlReceived(initialUrl);
      }
      ReceiveSharingIntent.instance.reset();
    } catch (_) {
      // Sharing intent plugin may be unavailable on some platforms/tests;
      // fail silently since this is a best-effort convenience feature.
    }

    try {
      _mediaStreamSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        (mediaFiles) {
          final url = _extractUrl(mediaFiles);
          if (url != null) onUrlReceived(url);
        },
        onError: (_) {},
      );
    } catch (_) {
      // Ignore stream setup failures.
    }
  }

  String? _extractUrl(List<SharedMediaFile>? files) {
    if (files == null || files.isEmpty) return null;
    for (final f in files) {
      final path = f.path;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }
    }
    return null;
  }

  void dispose() {
    _mediaStreamSub?.cancel();
  }
}
