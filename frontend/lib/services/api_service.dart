import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_constants.dart';
import '../core/api_exception.dart';
import 'token_storage_service.dart';

/// Callback invoked when the backend rejects the stored token (401/403), so the
/// app can clear the session and return the user to the login screen.
typedef UnauthorizedCallback = void Function();

/// The single place where HTTP is spoken.
///
/// Feature services build on top of this class instead of duplicating
/// encoding, header, timeout and error-handling logic.
class ApiService {
  ApiService({
    required TokenStorageService tokenStorage,
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client(),
       _baseUrl = _normalizeBaseUrl(baseUrl ?? ApiConstants.baseUrl),
       _timeout = timeout ?? ApiConstants.requestTimeout;

  final TokenStorageService _tokenStorage;
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  UnauthorizedCallback? onUnauthorized;

  String get baseUrl => _baseUrl;

  static String _normalizeBaseUrl(String value) {
    final String trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final Uri base = Uri.parse('$_baseUrl$path');

    if (query == null || query.isEmpty) {
      return base;
    }

    final Map<String, String> stringQuery = <String, String>{
      for (final MapEntry<String, dynamic> entry in query.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };

    return base.replace(queryParameters: stringQuery);
  }

  Future<Map<String, String>> _headers({required bool authenticated}) async {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final String? token = await _tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) {
    return _send(
      () async => _client.get(
        _uri(path, query),
        headers: await _headers(authenticated: authenticated),
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send(
      () async => _client.post(
        _uri(path),
        headers: await _headers(authenticated: authenticated),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send(
      () async => _client.patch(
        _uri(path),
        headers: await _headers(authenticated: authenticated),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> postMultipartFile(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required String filename,
    required List<int> fileBytes,
    bool authenticated = true,
  }) async {
    http.Response response;

    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        _uri(path),
      );

      request.fields.addAll(fields);

      if (authenticated) {
        final String? token = await _tokenStorage.readToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      request.files.add(
        http.MultipartFile.fromBytes(fileField, fileBytes, filename: filename),
      );

      final http.StreamedResponse streamedResponse = await request
          .send()
          .timeout(_timeout);

      response = await http.Response.fromStream(streamedResponse);
    } on TimeoutException {
      throw ApiException.timeout();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.network();
    }

    return _handleResponse(response);
  }

  /// Executes a request and converts every failure into an [ApiException].
  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response response;

    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException.timeout();
    } on ApiException {
      rethrow;
    } catch (_) {
      // Socket errors, DNS failures and browser CORS/network errors land here.
      throw ApiException.network();
    }

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final int status = response.statusCode;
    final dynamic decoded = _decodeBody(response);

    if (status >= 200 && status < 300) {
      return decoded;
    }

    final ApiException exception = ApiException.fromResponse(status, decoded);

    if (exception.isAuthError) {
      onUnauthorized?.call();
    }

    throw exception;
  }

  dynamic _decodeBody(http.Response response) {
    // `bodyBytes` is decoded explicitly as UTF-8 so Hebrew text survives even
    // when the response omits a charset in its Content-Type header.
    final String body = utf8.decode(response.bodyBytes, allowMalformed: true);

    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  /// Convenience wrapper for endpoints that must return a JSON object.
  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) async {
    return asObject(
      await get(path, query: query, authenticated: authenticated),
    );
  }

  /// Convenience wrapper for endpoints that must return a JSON array.
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) async {
    return asObjectList(
      await get(path, query: query, authenticated: authenticated),
    );
  }

  static Map<String, dynamic> asObject(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ApiException.badFormat();
  }

  static List<Map<String, dynamic>> asObjectList(dynamic value) {
    if (value is! List) throw ApiException.badFormat();
    return value.map(asObject).toList();
  }

  void dispose() => _client.close();
}
