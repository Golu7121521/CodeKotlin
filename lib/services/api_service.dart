import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

/// Result wrapper so UI can distinguish success/failure/empty without
/// throwing exceptions across layers.
class ApiResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;

  ApiResult.ok(this.data)
      : success = true,
        errorMessage = null;

  ApiResult.fail(this.errorMessage)
      : success = false,
        data = null;
}

/// All network calls live here, isolated from UI/state-management code.
class ApiService {
  static const String _baseUrl = 'https://example-api-dnva.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 20);

  /// Searches songs by free-text query.
  /// Response shape: { success, data: { total, results: [ {...song...} ] } }
  Future<ApiResult<List<Song>>> searchSongs(String query) async {
    if (query.trim().isEmpty) {
      return ApiResult.fail('Empty query');
    }

    final uri = Uri.parse(
      '$_baseUrl/search/songs?query=${Uri.encodeQueryComponent(query.trim())}',
    );

    try {
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        return ApiResult.fail('Server error (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      final List<Song> songs = _parseSongList(decoded);
      return ApiResult.ok(songs);
    } catch (e) {
      return ApiResult.fail('Network error. Please check your connection.');
    }
  }

  /// Parses the various shapes the API might return defensively:
  ///   { data: { results: [...] } }
  ///   { results: [...] }
  ///   [...]  (bare array)
  List<Song> _parseSongList(dynamic decoded) {
    List<dynamic>? rawList;

    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      rawList = _firstList(decoded, ['results', 'data', 'songs', 'items']);

      if (rawList == null && decoded['data'] is Map<String, dynamic>) {
        rawList = _firstList(
          decoded['data'] as Map<String, dynamic>,
          ['results', 'songs', 'items'],
        );
      }
    }

    if (rawList == null) return [];

    final List<Song> songs = [];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        try {
          final song = Song.fromJson(item);
          if (song.title.isNotEmpty) songs.add(song);
        } catch (_) {
          // skip malformed entries rather than failing the whole list
        }
      }
    }
    return songs;
  }

  List<dynamic>? _firstList(Map<String, dynamic> obj, List<String> keys) {
    for (final key in keys) {
      final value = obj[key];
      if (value is List) return value;
    }
    return null;
  }
}
