/// Describes a single resolvable video source for a movie. This is the
/// **only** shape [StreamResolver] deals in: a direct, pre-authorized
/// media URL (a public demo `.mp4`/`.m3u8` CDN link, or a URL your own
/// backend returns after validating the user's entitlement) plus
/// optional playback hints. There is no scraping, sniffing, or header
/// spoofing anywhere in this pipeline — every URL here is one the
/// resolver was explicitly configured to know about.
class StreamSource {
  final String url;
  final StreamFormat format;
  final String label; // e.g. "Server 1", "1080p", "Auto"
  final String? quality; // e.g. "4K", "1080p", "720p"
  final Map<String, String>? headers; // Optional auth headers your own
  // backend may require (e.g. a signed CDN token) — never used to
  // impersonate a third-party site.

  const StreamSource({
    required this.url,
    required this.format,
    required this.label,
    this.quality,
    this.headers,
  });
}

enum StreamFormat { hls, mp4, dash }

/// The result of resolving a movie to one or more playable sources.
class ResolvedStream {
  final int movieId;
  final List<StreamSource> sources;
  final StreamSource? preferred;

  const ResolvedStream({
    required this.movieId,
    required this.sources,
    this.preferred,
  });

  bool get hasSources => sources.isNotEmpty;

  factory ResolvedStream.empty(int movieId) =>
      ResolvedStream(movieId: movieId, sources: const []);
}
