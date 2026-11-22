import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shieldguard/core/hash_reputation.dart';

import 'remote_provider_test.dart' show Client, Request, Reply, Overrides;

void main() {
  for (final (status, body, expected) in [
    (
      200,
      '{"status":"reported","malicious":2,"suspicious":1}',
      HashLookupStatus.reported,
    ),
    (200, '{"status":"not_found"}', HashLookupStatus.noMatch),
    (200, '{"status":"unconfigured"}', HashLookupStatus.unconfigured),
    (200, '{"status":"rate_limited"}', HashLookupStatus.rateLimited),
    (200, '{"status":"unavailable"}', HashLookupStatus.unavailable),
    (
      200,
      '{"status":"reported","malicious":-1,"suspicious":0}',
      HashLookupStatus.invalidResponse,
    ),
    (
      200,
      '{"status":"reported","malicious":true,"suspicious":0}',
      HashLookupStatus.invalidResponse,
    ),
    (200, '[]', HashLookupStatus.invalidResponse),
    (200, 'invalid', HashLookupStatus.invalidResponse),
    (200, 'x' * 8193, HashLookupStatus.invalidResponse),
    (429, '{}', HashLookupStatus.rateLimited),
    (503, '{}', HashLookupStatus.unavailable),
  ]) {
    test('hash reply $status $expected', () async {
      final client = Client(Request(Reply(status, body)));
      await HttpOverrides.runWithHttpOverrides(() async {
        final value = await FileHashReputationProvider(
          Uri.parse('https://gateway.test/v1/hash'),
          'fixture',
        ).check('a' * 64, consent: true);
        expect(value.status, expected);
        expect(client.request.followRedirects, false);
        expect(client.closed, true);
        expect(client.request.body, contains('"consent":true'));
        expect(client.request.body, isNot(contains('"url"')));
      }, Overrides(client));
    });
  }
  test('no consent never creates a network request', () async {
    final client = Client(Request(Reply(200, '{}')));
    await HttpOverrides.runWithHttpOverrides(() async {
      expect(
        (await FileHashReputationProvider(
          Uri.parse('https://gateway.test'),
          'fixture',
        ).check('a' * 64, consent: false)).status,
        HashLookupStatus.disabled,
      );
      expect(client.request.body, isEmpty);
    }, Overrides(client));
  });
  test('malformed hash is rejected locally', () async {
    expect(
      (await FileHashReputationProvider(
        Uri.parse('https://gateway.test'),
        'fixture',
      ).check('../secret', consent: true)).status,
      HashLookupStatus.invalidResponse,
    );
  });
  test('insecure endpoint is rejected locally', () async {
    expect(
      (await FileHashReputationProvider(
        Uri.parse('http://gateway.test'),
        'fixture',
      ).check('a' * 64, consent: true)).status,
      HashLookupStatus.unconfigured,
    );
  });
  test('offline hash lookup retains the local scan', () async {
    final client = Client(Request(Reply(200, '{}')), offline: true);
    await HttpOverrides.runWithHttpOverrides(() async {
      expect(
        (await FileHashReputationProvider(
          Uri.parse('https://gateway.test'),
          'fixture',
        ).check('a' * 64, consent: true)).status,
        HashLookupStatus.unavailable,
      );
    }, Overrides(client));
  });
}
