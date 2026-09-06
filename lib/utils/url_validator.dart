/// Utility for validating user-entered video URLs.
class UrlValidator {
  UrlValidator._();

  /// Returns true if [input] is a well-formed, absolute http(s) URL.
  static bool isValid(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    if (!uri.isAbsolute) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    if (uri.host.isEmpty) return false;

    return true;
  }

  /// Normalizes the URL (trims whitespace). Returns null if invalid.
  static String? normalize(String input) {
    final trimmed = input.trim();
    if (!isValid(trimmed)) return null;
    return trimmed;
  }

  /// Builds the full backend API request URL with the target video URL
  /// safely percent-encoded as the `url` query parameter.
  static String buildApiUrl(String baseEndpoint, String videoUrl) {
    final encoded = Uri.encodeQueryComponent(videoUrl);
    return '$baseEndpoint$encoded';
  }
}
