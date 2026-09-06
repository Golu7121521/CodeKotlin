import 'dart:async';

import '../constants/api_constants.dart';
import '../models/stream_source_model.dart';

/// Resolves a movie ID to one or more directly-playable [StreamSource]s.
///
/// This is the **entire** video-sourcing pipeline for MovieStream, and it
/// is intentionally simple: given a movie ID, return whatever URLs you
/// (the person configuring this app) have authorized for playback. There
/// is no scraping, no headless-browser network sniffing, and no request
/// header spoofing anywhere in this class or anywhere else in the app —
/// every URL that reaches the player is one this resolver was explicitly
/// told about.
///
/// Two ways to plug in real content:
///
/// 1. **Your own backend** — implement [_fetchFromBackend] to call an API
///    you control, which validates the user's entitlement/subscription
///    and returns a signed, time-limited CDN URL for that title. This is
///    how a legitimate licensed-content app works.
/// 2. **A static demo catalog** — for development/testing without a
///    backend, [_demoCatalog] maps a handful of movie IDs to public
///    domain / freely-licensed sample clips (Google's well-known sample
///    video CDN), so the player pipeline can be exercised end-to-end.
///
/// Swap `useDemoCatalog` to false and point [backendBaseUrl] at your API
/// once you have one; nothing else in the app needs to change, since
/// every screen only ever talks to this resolver's public methods.
class StreamResolver {
  StreamResolver({
    this.backendBaseUrl,
    this.useDemoCatalog = true,
  });

  /// Base URL of your own authorized streaming backend, e.g.
  /// `https://api.yourservice.com`. Only used when [useDemoCatalog] is
  /// false. The resolver expects `GET {backendBaseUrl}/stream/{movieId}`
  /// to return a JSON array of sources in the shape produced by
  /// [_sourceFromJson].
  final String? backendBaseUrl;

  /// When true (the default, for out-of-the-box demo/testing), resolves
  /// against [_demoCatalog] instead of a network call.
  final bool useDemoCatalog;

  /// A tiny catalog of public sample clips, keyed by TMDB movie ID, used
  /// purely so the playback pipeline works before you've wired up a real
  /// backend. Replace or extend this map with your own authorized
  /// content, or switch to backend mode entirely.
  static final Map<int, List<StreamSource>> _demoCatalog = {
    27205: const [
      // Inception (demo mapping) -> Big Buck Bunny sample
      StreamSource(
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        format: StreamFormat.mp4,
        label: 'Demo Source',
        quality: '1080p',
      ),
    ],
    155: const [
      // The Dark Knight (demo mapping) -> Elephants Dream sample
      StreamSource(
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        format: StreamFormat.mp4,
        label: 'Demo Source',
        quality: '720p',
      ),
    ],
    550: const [
      // Fight Club (demo mapping) -> Sintel sample + HLS variant
      StreamSource(
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
        format: StreamFormat.mp4,
        label: 'Server 1',
        quality: '1080p',
      ),
      StreamSource(
        url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
        format: StreamFormat.hls,
        label: 'Server 2 (HLS)',
        quality: 'Auto',
      ),
    ],
  };

  /// A single always-available fallback clip used when a requested movie
  /// has no demo mapping, so the player screen can still be exercised.
  static const StreamSource _genericFallback = StreamSource(
    url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    format: StreamFormat.mp4,
    label: 'Sample Preview',
    quality: '720p',
  );

  /// Resolves [movieId] to its playable sources, trying each configured
  /// source path with a bounded timeout, and returning an empty result
  /// (never throwing) if nothing could be resolved — callers should
  /// treat an empty [ResolvedStream] as "show a friendly unavailable
  /// state", not as an exceptional condition.
  Future<ResolvedStream> resolve(int movieId) async {
    try {
      final sources = useDemoCatalog
          ? await _resolveFromDemoCatalog(movieId)
          : await _fetchFromBackend(movieId).timeout(ApiConstants.streamResolveTimeout);

      if (sources.isEmpty) {
        return ResolvedStream(movieId: movieId, sources: const [_genericFallback], preferred: _genericFallback);
      }
      return ResolvedStream(movieId: movieId, sources: sources, preferred: sources.first);
    } on TimeoutException {
      return ResolvedStream.empty(movieId);
    } catch (_) {
      return ResolvedStream.empty(movieId);
    }
  }

  Future<List<StreamSource>> _resolveFromDemoCatalog(int movieId) async {
    // Simulate the small latency of a real resolution call so loading
    // states are exercised even in demo mode.
    await Future.delayed(const Duration(milliseconds: 400));
    return _demoCatalog[movieId] ?? const [];
  }

  /// Calls your own backend to obtain authorized stream URLs for
  /// [movieId]. This is a stub you fill in — it performs no scraping or
  /// third-party interaction; it only talks to `backendBaseUrl`, a
  /// server you operate.
  Future<List<StreamSource>> _fetchFromBackend(int movieId) async {
    if (backendBaseUrl == null || backendBaseUrl!.isEmpty) {
      throw StateError(
        'StreamResolver.useDemoCatalog is false but no backendBaseUrl was configured.',
      );
    }
    // Intentionally left as a clear extension point: wire up an http/dio
    // GET to '$backendBaseUrl/stream/$movieId', parse the JSON array of
    // sources with StreamSource.fromJson-equivalent logic, and return
    // them. Left unimplemented here since it depends entirely on your
    // backend's contract.
    throw UnimplementedError(
      'Implement _fetchFromBackend to call your authorized streaming backend.',
    );
  }
}
