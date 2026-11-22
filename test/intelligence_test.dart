import 'package:flutter_test/flutter_test.dart';
import 'package:shieldguard/core/engine.dart';
import 'package:shieldguard/core/intelligence.dart';

class Cache implements ThreatCache {
  final data = <String, ReputationResult>{};
  @override
  Future<ReputationResult?> read(String key) async => data[key];
  @override
  Future<void> write(String key, ReputationResult value) async {
    data[key] = value;
  }
}

class Provider implements ReputationProvider {
  Provider(this.value);
  ReputationResult value;
  int calls = 0;
  @override
  Future<ReputationResult> check(Uri uri) async {
    calls++;
    return value;
  }
}

void main() {
  final uri = Uri.parse('https://example.test/path?token=private');
  final now = DateTime.now();
  for (final status in [
    ReputationStatus.match,
    ReputationStatus.noMatch,
    ReputationStatus.unavailable,
    ReputationStatus.rateLimited,
    ReputationStatus.invalidResponse,
  ]) {
    test('provider returns ${status.name}', () async {
      final provider = Provider(ReputationResult(status));
      final result = await ThreatIntelligenceEngine(
        Cache(),
        provider,
      ).check(uri, consent: true);
      expect(result.status, status);
    });
  }
  test('no consent contacts neither provider nor cache', () async {
    final provider = Provider(const ReputationResult(ReputationStatus.match));
    expect(
      (await ThreatIntelligenceEngine(
        Cache(),
        provider,
      ).check(uri, consent: false)).status,
      ReputationStatus.disabled,
    );
    expect(provider.calls, 0);
  });
  test('cache stores hashes and avoids duplicate calls', () async {
    final cache = Cache();
    final provider = Provider(
      ReputationResult(
        ReputationStatus.match,
        expires: now.add(const Duration(hours: 1)),
      ),
    );
    final engine = ThreatIntelligenceEngine(cache, provider);
    await engine.check(uri, consent: true);
    await engine.check(uri, consent: true);
    expect(provider.calls, 1);
    expect(cache.data.keys.single, matches(r'^[a-f0-9]{64}$'));
    expect(cache.data.keys.single, isNot(contains('private')));
  });
  test('expired match queries provider', () async {
    final cache = Cache();
    final provider = Provider(
      ReputationResult(
        ReputationStatus.match,
        expires: now.add(const Duration(seconds: 1)),
      ),
    );
    var clock = now;
    final engine = ThreatIntelligenceEngine(
      cache,
      provider,
      clock: () => clock,
    );
    await engine.check(uri, consent: true);
    clock = now.add(const Duration(seconds: 2));
    await Future<void>.delayed(Duration.zero);
    await engine.check(uri, consent: true);
    expect(provider.calls, 2);
  });
  test('backoff suppresses repeated unavailable requests', () async {
    final provider = Provider(
      const ReputationResult(ReputationStatus.unavailable),
    );
    final engine = ThreatIntelligenceEngine(Cache(), provider);
    await engine.check(uri, consent: true);
    expect(
      (await engine.check(uri, consent: true)).status,
      ReputationStatus.rateLimited,
    );
    expect(provider.calls, 1);
  });
  test('simultaneous lookups share one request', () async {
    final provider = Provider(const ReputationResult(ReputationStatus.noMatch));
    final engine = ThreatIntelligenceEngine(Cache(), provider);
    await Future.wait([
      engine.check(uri, consent: true),
      engine.check(uri, consent: true),
    ]);
    expect(provider.calls, 1);
  });
  for (final body in [
    null,
    [],
    {},
    {'provider': 'unknown'},
    {'provider': 'webrisk', 'matched': 'yes', 'expires': 'bad'},
    {'provider': 'webrisk', 'matched': true, 'expires': 'bad'},
  ]) {
    test(
      'invalid remote response $body',
      () => expect(
        parseReputation(body).status,
        ReputationStatus.invalidResponse,
      ),
    );
  }
  test('no match preserves local risk', () {
    final local = ThreatEngine().link('https://telegram.example/premium');
    expect(
      aggregateReputation(
        local,
        const ReputationResult(ReputationStatus.noMatch),
      ).score,
      local.score,
    );
  });
  test('positive match dominates and repeated evidence is counted once', () {
    final local = ThreatEngine().link('https://example.com');
    final first = aggregateReputation(
      local,
      const ReputationResult(ReputationStatus.match),
    );
    expect(first.score, 90);
    expect(
      aggregateReputation(
        first,
        const ReputationResult(ReputationStatus.match),
      ).score,
      90,
    );
  });
  test('insecure gateway never sends a request', () async {
    final result = await RemoteReputationProvider(
      Uri.parse('http://localhost'),
      'token',
    ).check(uri);
    expect(result.status, ReputationStatus.unconfigured);
  });
  test('finding explanation metadata stays tied to its identifier', () {
    const finding = Finding('reputationMatch', 90);
    expect(finding.id, finding.evidence);
    expect(finding.category, 'reputation');
    expect(finding.confidence, Confidence.strong);
    expect(finding.severity, ThreatLevel.severe);
    expect(finding.detectionMethod, 'reputation');
    expect(finding.limitations, 'online');
    expect(finding.recommendedAction, 'advice');
  });
}
