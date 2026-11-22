import 'package:flutter_test/flutter_test.dart';
import 'package:shieldguard/core/engine.dart';
import 'package:shieldguard/core/platform.dart';

void main() {
  final engine = ThreatEngine();
  test('notification result retains the original scan time', () {
    const time = 1700000000000;
    final result = ShieldPlatform().decode({
      'kind': 'alert',
      'findings': {'secret': 55},
      'complete': true,
      'time': time,
    });
    expect(result.type, ThreatType.notification);
    expect(result.time.millisecondsSinceEpoch, time);
    expect(result.level, ThreatLevel.high);
  });
  for (final (raw, host) in [
    ('HTTPS://Example.COM./a#part', 'example.com'),
    ('example.com', 'example.com'),
    ('www.example.com/path', 'www.example.com'),
    ('http://127.0.0.1', '127.0.0.1'),
    ('https://[::1]/', '::1'),
  ]) {
    test('normalizes $raw', () => expect(engine.normalize(raw)?.host, host));
  }
  for (final raw in [
    '',
    'http://',
    'ftp://example.com',
    'a b',
    r'https://a.com\b',
    'https://example.com:65536',
    'https://foo..example.com',
    'https://localhost',
  ]) {
    test('rejects $raw', () => expect(engine.link(raw).complete, false));
  }
  for (final (raw, finding) in [
    ('http://example.com', 'http'),
    ('https://t.me@example.com', 'userinfo'),
    ('https://192.0.2.1', 'ip'),
    ('https://[::1]', 'ip'),
    ('https://xn--e1afmkfd.example', 'idn'),
    ('https://тест.example', 'idn'),
    ('https://bit.ly/example', 'short'),
    ('https://telegram.example/premium', 'brand'),
    ('https://tеlegrаm.example/premium', 'brand'),
    ('https://t.me.example.com', 'brand'),
    ('https://example.com/verify', 'lure'),
  ]) {
    test(
      'flags $finding in $raw',
      () => expect(
        engine.link(raw).findings.map((item) => item.code),
        contains(finding),
      ),
    );
  }
  for (final raw in [
    'https://t.me/premium',
    'https://telegram.org/gift',
    'https://core.telegram.org/login',
    'https://example.com/docs',
  ]) {
    test('keeps low score for $raw', () => expect(engine.link(raw).score, 0));
  }
  test(
    'extracts multiple links',
    () => expect(
      engine
          .links('Try https://example.com, and (https://example.org).')
          .length,
      2,
    ),
  );
  test(
    'deduplicates canonical links',
    () => expect(
      engine.links('https://EXAMPLE.com#x https://example.com/#y').length,
      1,
    ),
  );
  test(
    'no reputation service is needed',
    () => expect(engine.link('example.com').source, 'local'),
  );

  for (final (text, code) in [
    ('Telegram tasdiqlash kodi yuboring', 'secret'),
    ('Send the verification code', 'secret'),
    ('Пришлите код', 'secret'),
    ('Support: send your password', 'support'),
    ('Premium gift: send your password', 'gift'),
    ('Darhol parolni kiriting', 'urgent'),
    ('Install example.apk', 'install'),
    ('Go to https://telegram.example/premium', 'messageLink'),
    ('Open https://bit.ly/example', 'messageLink'),
  ]) {
    test(
      'context signal $code for $text',
      () => expect(
        engine.message(text).findings.map((item) => item.code),
        contains(code),
      ),
    );
  }
  for (final text in [
    'Premium gift',
    'Parol uzun bo‘lishi kerak',
    'Never share your password',
    'Tasdiqlash kodi hech kimga yubormang',
    'Никому код не сообщайте',
  ]) {
    test(
      'no risk from informational text $text',
      () => expect(engine.message(text).score, 0),
    );
  }
  for (final (score, level) in [
    (0, ThreatLevel.low),
    (24, ThreatLevel.low),
    (25, ThreatLevel.caution),
    (49, ThreatLevel.caution),
    (50, ThreatLevel.high),
    (74, ThreatLevel.high),
    (75, ThreatLevel.severe),
    (101, ThreatLevel.severe),
  ]) {
    test(
      'score boundary $score',
      () => expect(
        ScanResult(ThreatType.link, [Finding('test', score)]).level,
        level,
      ),
    );
  }
  test(
    'clamps total at 100',
    () => expect(
      ScanResult(ThreatType.link, const [
        Finding('a', 80),
        Finding('b', 40),
      ]).score,
      100,
    ),
  );
  test(
    'no findings have limited confidence',
    () => expect(engine.link('example.com').confidence, Confidence.limited),
  );
  test(
    'truncation is visible',
    () => expect(engine.message('a' * 32001).complete, false),
  );
}
