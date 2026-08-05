import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// These tests exercise the HTTP layer against a mocked client, so they never
/// require a running backend.
void main() {
  late InMemoryTokenStorageService storage;

  setUp(() => storage = InMemoryTokenStorageService());

  ApiService buildApi(MockClient client) => ApiService(
    tokenStorage: storage,
    client: client,
    baseUrl: 'http://127.0.0.1:8000',
  );

  test(
    'sends Content-Type and no Authorization header when signed out',
    () async {
      late http.Request captured;

      final ApiService api = buildApi(
        MockClient((http.Request request) async {
          captured = request;
          return http.Response('{"status":"ok"}', 200);
        }),
      );

      await api.get('/api/health', authenticated: false);

      expect(captured.headers['Content-Type'], contains('application/json'));
      expect(captured.headers.containsKey('Authorization'), isFalse);
    },
  );

  test('attaches the stored token as a Bearer header', () async {
    await storage.saveToken('jwt-token');
    late http.Request captured;

    final ApiService api = buildApi(
      MockClient((http.Request request) async {
        captured = request;
        return http.Response('{}', 200);
      }),
    );

    await api.get('/api/children');

    expect(captured.headers['Authorization'], 'Bearer jwt-token');
  });

  test('builds query parameters for filtered requests', () async {
    late Uri captured;

    final ApiService api = buildApi(
      MockClient((http.Request request) async {
        captured = request.url;
        return http.Response('[]', 200);
      }),
    );

    await api.get('/api/messages', query: <String, dynamic>{'child_id': 3});

    expect(captured.path, '/api/messages');
    expect(captured.queryParameters['child_id'], '3');
  });

  test('encodes the request body as JSON', () async {
    late String captured;

    final ApiService api = buildApi(
      MockClient((http.Request request) async {
        captured = request.body;
        return http.Response('{}', 201);
      }),
    );

    await api.post(
      '/api/children',
      body: <String, dynamic>{'full_name': 'Ahmad', 'age': 13},
    );

    expect(jsonDecode(captured), <String, dynamic>{
      'full_name': 'Ahmad',
      'age': 13,
    });
  });

  test('decodes Hebrew response bodies as UTF-8', () async {
    const String hebrew = 'אף אחד לא אוהב אותך';

    final ApiService api = buildApi(
      MockClient((http.Request request) async {
        return http.Response.bytes(
          utf8.encode(jsonEncode(<String, dynamic>{'message': hebrew})),
          200,
        );
      }),
    );

    final Map<String, dynamic> result = await api.getObject('/api/messages/1');

    expect(result['message'], hebrew);
  });

  test('throws an ApiException carrying the FastAPI detail', () async {
    final ApiService api = buildApi(
      MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{'detail': 'Child not found'}),
          404,
        );
      }),
    );

    await expectLater(
      api.get('/api/children/99'),
      throwsA(
        isA<ApiException>()
            .having((ApiException e) => e.statusCode, 'statusCode', 404)
            .having((ApiException e) => e.detail, 'detail', 'Child not found')
            .having(
              (ApiException e) => e.message,
              'message',
              'הילד לא נמצא או שאינו שייך לחשבון שלכם.',
            ),
      ),
    );
  });

  test('invokes onUnauthorized for a 401 response', () async {
    int unauthorizedCount = 0;

    final ApiService api = buildApi(
      MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'detail': 'Invalid or expired authentication token',
          }),
          401,
        );
      }),
    );
    api.onUnauthorized = () => unauthorizedCount++;

    await expectLater(api.get('/api/auth/me'), throwsA(isA<ApiException>()));
    expect(unauthorizedCount, 1);
  });

  test('does not invoke onUnauthorized for other errors', () async {
    int unauthorizedCount = 0;

    final ApiService api = buildApi(
      MockClient((http.Request request) async => http.Response('{}', 500)),
    );
    api.onUnauthorized = () => unauthorizedCount++;

    await expectLater(api.get('/api/health'), throwsA(isA<ApiException>()));
    expect(unauthorizedCount, 0);
  });

  test('converts a transport failure into a network ApiException', () async {
    final ApiService api = buildApi(
      MockClient((http.Request request) async {
        throw const SocketExceptionStub();
      }),
    );

    await expectLater(
      api.get('/api/health'),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.message,
          'message',
          contains('לא ניתן להתחבר לשרת'),
        ),
      ),
    );
  });

  test('rejects a response whose shape does not match the contract', () async {
    final ApiService api = buildApi(
      MockClient((http.Request request) async => http.Response('[]', 200)),
    );

    // The endpoint should return an object, but returned an array.
    await expectLater(
      api.getObject('/api/dashboard/stats'),
      throwsA(isA<ApiException>()),
    );
  });

  test('strips a trailing slash from the configured base URL', () async {
    late Uri captured;

    final ApiService api = ApiService(
      tokenStorage: storage,
      baseUrl: 'http://127.0.0.1:8000/',
      client: MockClient((http.Request request) async {
        captured = request.url;
        return http.Response('{}', 200);
      }),
    );

    await api.get('/api/health');

    expect(captured.toString(), 'http://127.0.0.1:8000/api/health');
    expect(api.baseUrl, 'http://127.0.0.1:8000');
  });
}

/// Stands in for a transport-level failure (dart:io is unavailable on web).
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
