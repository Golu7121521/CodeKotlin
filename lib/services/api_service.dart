import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../utils/url_validator.dart';

/// Exception thrown for any API-related failure, carrying a
/// user-friendly message suitable for direct display.
class ApiException implements Exception {
  final String userMessage;
  final Object? cause;

  ApiException(this.userMessage, [this.cause]);

  @override
  String toString() => 'ApiException: $userMessage (${cause ?? ''})';
}

/// Handles communication with the backend video-resolution API.
///
/// The API is called off the UI thread implicitly because Dart's `http`
/// calls are asynchronous and non-blocking by nature; this service also
/// enforces an explicit timeout and translates all failure modes into
/// friendly [ApiException]s.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseEndpoint =
      'https://allinonedownloader-api.onrender.com/download?url=';

  static const Duration _timeout = Duration(seconds: 30);

  /// Resolves [videoUrl] via the backend API and returns the parsed
  /// [ApiVideoResponse]. Throws [ApiException] with a friendly message
  /// on any failure.
  Future<ApiVideoResponse> resolveVideo(String videoUrl) async {
    if (!UrlValidator.isValid(videoUrl)) {
      throw ApiException('Please enter a valid video URL.');
    }

    final requestUrl = UrlValidator.buildApiUrl(_baseEndpoint, videoUrl);
    final uri = Uri.tryParse(requestUrl);
    if (uri == null) {
      throw ApiException('Please enter a valid video URL.');
    }

    http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on SocketException {
      throw ApiException('Internet connection unavailable.');
    } on HttpException {
      throw ApiException('Server is temporarily unavailable. Please try again.');
    } catch (e) {
      throw ApiException('Unable to process this URL.', e);
    }

    if (response.statusCode >= 500) {
      throw ApiException('Server is temporarily unavailable. Please try again.');
    }
    if (response.statusCode == 404 || response.statusCode == 400) {
      throw ApiException('Unable to process this URL.');
    }
    if (response.statusCode != 200) {
      throw ApiException('Server is temporarily unavailable. Please try again.');
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      throw ApiException('Unable to process this URL.');
    }

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected JSON shape');
      }
      json = decoded;
    } on FormatException catch (e) {
      throw ApiException('Unable to process this URL.', e);
    } catch (e) {
      throw ApiException('Unable to process this URL.', e);
    }

    try {
      return ApiVideoResponse.fromJson(json);
    } on FormatException catch (e) {
      throw ApiException('Video preview could not be loaded.', e);
    }
  }

  void dispose() {
    _client.close();
  }
}
