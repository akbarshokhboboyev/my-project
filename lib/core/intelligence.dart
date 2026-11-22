import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'engine.dart';
import 'platform.dart';

enum ReputationStatus {
  match,
  noMatch,
  disabled,
  unavailable,
  rateLimited,
  invalidResponse,
  unconfigured,
}

class ReputationResult {
  const ReputationResult(this.status, {this.expires, this.cached = false});
  final ReputationStatus status;
  final DateTime? expires;
  final bool cached;
}

abstract interface class ReputationProvider {
  Future<ReputationResult> check(Uri uri);
}

class RemoteReputationProvider implements ReputationProvider {
  RemoteReputationProvider(this.endpoint, this.token);
  final Uri endpoint;
  final String token;
  @override
  Future<ReputationResult> check(Uri uri) async {
    if (endpoint.scheme != 'https' ||
        endpoint.userInfo.isNotEmpty ||
        token.isEmpty) {
      return const ReputationResult(ReputationStatus.unconfigured);
    }
    final client = HttpClient();
    try {
      return await _request(client, uri).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      return const ReputationResult(ReputationStatus.unavailable);
    } on IOException {
      return const ReputationResult(ReputationStatus.unavailable);
    } on FormatException {
      return const ReputationResult(ReputationStatus.invalidResponse);
    } finally {
      client.close(force: true);
    }
  }

  Future<ReputationResult> _request(HttpClient client, Uri uri) async {
    final request = await client.postUrl(endpoint);
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.write(jsonEncode({'url': uri.toString()}));
    final response = await request.close();
    if (response.statusCode == 429) {
      return const ReputationResult(ReputationStatus.rateLimited);
    }
    if (response.statusCode != 200) {
      return const ReputationResult(ReputationStatus.unavailable);
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > 16384) throw const FormatException();
      bytes.addAll(chunk);
    }
    return parseReputation(jsonDecode(utf8.decode(bytes)));
  }
}

ReputationResult parseReputation(dynamic value) {
  if (value is! Map ||
      value['provider'] != 'webrisk' ||
      value['matched'] is! bool ||
      value['expires'] is! String) {
    return const ReputationResult(ReputationStatus.invalidResponse);
  }
  final expires = DateTime.tryParse(value['expires'] as String);
  if (expires == null ||
      (value['matched'] == true && !expires.isAfter(DateTime.now()))) {
    return const ReputationResult(ReputationStatus.invalidResponse);
  }
  return ReputationResult(
    value['matched'] == true
        ? ReputationStatus.match
        : ReputationStatus.noMatch,
    expires: expires,
  );
}

abstract interface class ThreatCache {
  Future<ReputationResult?> read(String key);
  Future<void> write(String key, ReputationResult value);
}

class PlatformThreatCache implements ThreatCache {
  @override
  Future<ReputationResult?> read(String key) async {
    final value = await ShieldPlatform.channel.invokeMapMethod<String, dynamic>(
      'cacheRead',
      {'key': key},
    );
    if (value == null) return null;
    final result = parseReputation(value);
    if (result.status == ReputationStatus.invalidResponse) return null;
    return ReputationResult(
      result.status,
      expires: result.expires,
      cached: true,
    );
  }

  @override
  Future<void> write(String key, ReputationResult value) =>
      ShieldPlatform.channel.invokeMethod<void>('cacheWrite', {
        'key': key,
        'matched': value.status == ReputationStatus.match,
        'expires': value.expires!.toUtc().toIso8601String(),
      });
}

class ThreatIntelligenceEngine {
  ThreatIntelligenceEngine(
    this.cache,
    this.provider, {
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final ThreatCache cache;
  final ReputationProvider provider;
  final DateTime Function() clock;
  final _pending = <String, Future<ReputationResult>>{};
  DateTime? _retryAfter;
  int _failures = 0;
  Future<ReputationResult> check(Uri uri, {required bool consent}) async {
    if (!consent) return const ReputationResult(ReputationStatus.disabled);
    final key = sha256.convert(utf8.encode('webrisk-v1:$uri')).toString();
    try {
      final cached = await cache.read(key);
      if (cached?.expires?.isAfter(clock()) == true) return cached!;
    } on Exception {
      /* Local analysis can continue if SQLite fails. */
    }
    if (_retryAfter?.isAfter(clock()) == true) {
      return const ReputationResult(ReputationStatus.rateLimited);
    }
    return _pending.putIfAbsent(key, () => _query(key, uri));
  }

  Future<ReputationResult> _query(String key, Uri uri) async {
    try {
      final result = await provider.check(uri);
      if ({
        ReputationStatus.match,
        ReputationStatus.noMatch,
      }.contains(result.status)) {
        _failures = 0;
        if (result.expires?.isAfter(clock()) == true) {
          try {
            await cache.write(key, result);
          } on Exception {
            /* Preserve the remote result. */
          }
        }
      } else {
        _failures = (_failures + 1).clamp(1, 8);
        _retryAfter = clock().add(Duration(seconds: 1 << _failures));
      }
      return result;
    } on Exception {
      _retryAfter = clock().add(const Duration(seconds: 30));
      return const ReputationResult(ReputationStatus.unavailable);
    } finally {
      scheduleMicrotask(() => _pending.remove(key));
    }
  }
}

ScanResult aggregateReputation(ScanResult local, ReputationResult remote) =>
    ScanResult(
      local.type,
      [
        ...local.findings,
        if (remote.status == ReputationStatus.match)
          const Finding('reputationMatch', 90),
      ],
      subject: local.subject,
      hash: local.hash,
      signers: local.signers,
      complete: local.complete,
      scannedAt: local.time,
      source: remote.cached ? 'webRiskCache' : 'webRisk',
      reputation: remote.status.name,
    );
