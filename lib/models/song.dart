/// Core Song data model.
/// Parsing is defensive and targets the confirmed API response shape:
///   { id, name, duration, album: {name}, image: [{quality,url}],
///     artists: { primary: [{name}, ...] }, downloadUrl: [{quality,url}] }
class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String thumbnailUrl;
  final String mediaUrl;
  final int durationSeconds;
  final Map<String, String> downloadUrls; // quality label -> url

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.thumbnailUrl,
    required this.mediaUrl,
    required this.durationSeconds,
    required this.downloadUrls,
  });

  bool get hasPlayableUrl => mediaUrl.isNotEmpty && mediaUrl.startsWith('http');

  factory Song.fromJson(Map<String, dynamic> json) {
    final String id = _asString(json['id']) ?? '';
    final String title = _decodeHtmlEntities(
      _asString(json['name']) ?? _asString(json['title']) ?? '',
    );

    final String artist = _decodeHtmlEntities(_extractArtists(json));
    final String album = _decodeHtmlEntities(_extractAlbumName(json));
    final String thumbnailUrl = _extractBestImage(json['image']);

    final Map<String, String> downloadUrls = _extractDownloadUrls(json['downloadUrl']);
    final String mediaUrl = _bestDownloadUrl(downloadUrls);

    int durationSeconds = 0;
    final dynamic durationRaw = json['duration'];
    if (durationRaw is int) {
      durationSeconds = durationRaw;
    } else if (durationRaw is String) {
      durationSeconds = int.tryParse(durationRaw) ?? 0;
    }

    return Song(
      id: id,
      title: title.isNotEmpty ? title : 'Unknown Title',
      artist: artist.isNotEmpty ? artist : 'Unknown Artist',
      album: album,
      thumbnailUrl: thumbnailUrl,
      mediaUrl: mediaUrl,
      durationSeconds: durationSeconds,
      downloadUrls: downloadUrls,
    );
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// artists.primary is a list of {name, role, ...} objects.
  /// Joins all primary artist names with ", ".
  static String _extractArtists(Map<String, dynamic> json) {
    try {
      final dynamic artistsRaw = json['artists'];
      if (artistsRaw is Map<String, dynamic>) {
        final List<dynamic>? primary = artistsRaw['primary'] as List<dynamic>?;
        final String joined = _joinNames(primary);
        if (joined.isNotEmpty) return joined;

        final List<dynamic>? all = artistsRaw['all'] as List<dynamic>?;
        final String joinedAll = _joinNames(all);
        if (joinedAll.isNotEmpty) return joinedAll;
      } else if (artistsRaw is List<dynamic>) {
        final String joined = _joinNames(artistsRaw);
        if (joined.isNotEmpty) return joined;
      } else if (artistsRaw is String) {
        return artistsRaw;
      }
    } catch (_) {
      // fall through to generic fallback below
    }

    return _asString(json['artist']) ??
        _asString(json['singers']) ??
        _asString(json['subtitle']) ??
        '';
  }

  static String _joinNames(List<dynamic>? list) {
    if (list == null) return '';
    final names = <String>[];
    for (final entry in list) {
      if (entry is Map<String, dynamic>) {
        final name = entry['name']?.toString().trim();
        if (name != null && name.isNotEmpty) names.add(name);
      }
    }
    return names.join(', ');
  }

  /// album may be an object {id, name, url} or a plain string.
  static String _extractAlbumName(Map<String, dynamic> json) {
    try {
      final dynamic albumRaw = json['album'];
      if (albumRaw is Map<String, dynamic>) {
        return albumRaw['name']?.toString() ?? '';
      } else if (albumRaw is String) {
        return albumRaw;
      }
    } catch (_) {}
    return _asString(json['albumName']) ?? '';
  }

  /// image is a list of {quality, url} objects. Picks the highest quality
  /// (last entry) available.
  static String _extractBestImage(dynamic imageRaw) {
    try {
      if (imageRaw is List && imageRaw.isNotEmpty) {
        final last = imageRaw.last;
        if (last is Map<String, dynamic>) {
          final url = last['url']?.toString() ?? '';
          if (url.isNotEmpty) return url;
        }
      } else if (imageRaw is String) {
        return imageRaw;
      }
    } catch (_) {}
    return '';
  }

  /// downloadUrl is a list of {quality, url} objects
  /// (e.g. 12kbps, 48kbps, 96kbps, 160kbps, 320kbps).
  static Map<String, String> _extractDownloadUrls(dynamic downloadRaw) {
    final Map<String, String> result = {};
    try {
      if (downloadRaw is List) {
        for (final entry in downloadRaw) {
          if (entry is Map<String, dynamic>) {
            final quality = entry['quality']?.toString() ?? '';
            final url = entry['url']?.toString() ?? '';
            if (quality.isNotEmpty && url.startsWith('http')) {
              result[quality] = url;
            }
          }
        }
      }
    } catch (_) {}
    return result;
  }

  /// Prefers the highest quality available for streaming/download.
  static String _bestDownloadUrl(Map<String, String> urls) {
    const preferenceOrder = ['320kbps', '160kbps', '96kbps', '48kbps', '12kbps'];
    for (final quality in preferenceOrder) {
      if (urls.containsKey(quality)) return urls[quality]!;
    }
    if (urls.isNotEmpty) return urls.values.first;
    return '';
  }

  static String _decodeHtmlEntities(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'thumbnailUrl': thumbnailUrl,
      'mediaUrl': mediaUrl,
      'durationSeconds': durationSeconds,
      'downloadUrls': downloadUrls,
    };
  }

  factory Song.fromStorageJson(Map<String, dynamic> json) {
    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      artist: json['artist']?.toString() ?? '',
      album: json['album']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      mediaUrl: json['mediaUrl']?.toString() ?? '',
      durationSeconds: json['durationSeconds'] is int ? json['durationSeconds'] : 0,
      downloadUrls: Map<String, String>.from(json['downloadUrls'] ?? {}),
    );
  }

  /// Stable identity key for equality/dedup checks (favorites, recents, queue).
  String get identityKey => id.isNotEmpty ? id : '$title|$artist';

  @override
  bool operator ==(Object other) => other is Song && other.identityKey == identityKey;

  @override
  int get hashCode => identityKey.hashCode;
}
