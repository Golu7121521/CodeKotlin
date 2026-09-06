/// Represents the parsed response from the backend download API.
class ApiVideoResponse {
  final String downloadUrl;
  final String? title;
  final int? fileSizeBytes;
  final int? durationMs;
  final String? thumbnailUrl;

  ApiVideoResponse({
    required this.downloadUrl,
    this.title,
    this.fileSizeBytes,
    this.durationMs,
    this.thumbnailUrl,
  });

  /// Parses the raw JSON map returned by the backend.
  ///
  /// Throws [FormatException] if the required `download_url` key is
  /// missing, empty, or not a valid http(s) URL.
  factory ApiVideoResponse.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['download_url'];
    if (rawUrl == null || rawUrl is! String || rawUrl.trim().isEmpty) {
      throw const FormatException('Missing or empty "download_url" in API response');
    }

    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.isAbsolute || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      throw const FormatException('Invalid "download_url" returned by API');
    }

    return ApiVideoResponse(
      downloadUrl: rawUrl.trim(),
      title: (json['title'] as String?)?.trim(),
      fileSizeBytes: _parseIntSafe(json['file_size']),
      durationMs: _parseIntSafe(json['duration_ms']),
      thumbnailUrl: (json['thumbnail'] as String?)?.trim(),
    );
  }

  static int? _parseIntSafe(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
