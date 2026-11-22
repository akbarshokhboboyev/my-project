import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shieldguard/core/intelligence.dart';

class Headers implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  set contentType(ContentType? value) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Reply extends Stream<List<int>> implements HttpClientResponse {
  Reply(this.statusCode, this.body);
  @override
  final int statusCode;
  final String body;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(utf8.encode(body)).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Request implements HttpClientRequest {
  Request(this.reply);
  final Reply reply;
  @override
  final headers = Headers();
  @override
  bool followRedirects = true;
  String body = '';
  @override
  void write(Object? object) {
    body += object.toString();
  }

  @override
  Future<HttpClientResponse> close() async => reply;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Client implements HttpClient {
  Client(this.request, {this.offline = false});
  final Request request;
  final bool offline;
  bool closed = false;
  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    if (offline) throw const SocketException('fixture');
    return request;
  }

  @override
  void close({bool force = false}) {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Overrides extends HttpOverrides {
  Overrides(this.client);
  final Client client;
  @override
  HttpClient createHttpClient(SecurityContext? context) => client;
}

void main() {
  for (final (code, body, status) in [
    (
      200,
      '{"provider":"webrisk","matched":true,"expires":"2099-01-01T00:00:00Z"}',
      ReputationStatus.match,
    ),
    (
      200,
      '{"provider":"webrisk","matched":false,"expires":"2020-01-01T00:00:00Z"}',
      ReputationStatus.noMatch,
    ),
    (200, 'invalid', ReputationStatus.invalidResponse),
    (200, '{"provider":"other"}', ReputationStatus.invalidResponse),
    (200, 'x' * 16385, ReputationStatus.invalidResponse),
    (429, '{}', ReputationStatus.rateLimited),
    (503, '{}', ReputationStatus.unavailable),
    (302, '{}', ReputationStatus.unavailable),
  ]) {
    test('remote response $code ${status.name}', () async {
      final request = Request(Reply(code, body));
      final client = Client(request);
      await HttpOverrides.runWithHttpOverrides(() async {
        final result = await RemoteReputationProvider(
          Uri.parse('https://gateway.test/v1/check'),
          'fixture',
        ).check(Uri.parse('https://example.test/'));
        expect(result.status, status);
        expect(request.followRedirects, false);
        expect(jsonDecode(request.body), {'url': 'https://example.test/'});
        expect(client.closed, true);
      }, Overrides(client));
    });
  }
  test('offline returns unavailable and closes client', () async {
    final client = Client(Request(Reply(200, '{}')), offline: true);
    await HttpOverrides.runWithHttpOverrides(() async {
      expect(
        (await RemoteReputationProvider(
          Uri.parse('https://gateway.test'),
          'fixture',
        ).check(Uri.parse('https://example.test'))).status,
        ReputationStatus.unavailable,
      );
      expect(client.closed, true);
    }, Overrides(client));
  });
}
