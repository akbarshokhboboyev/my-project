import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shieldguard/core/engine.dart';
import 'package:shieldguard/app/labels.dart';
import 'package:shieldguard/app/l10n/strings_uz.dart';

void main() {
  final engine = ThreatEngine();
  final rows = File('test/fixtures/telegram_phishing.tsv')
      .readAsLinesSync()
      .where((row) => !row.startsWith('#') && row.isNotEmpty);
  for (final row in rows) {
    final fields = row.split('\t');
    test('shared Telegram fixture: ${fields[0]}', () {
      final result = engine.message(fields[0]);
      final expected = fields[1] == '-' ? <String>[] : fields[1].split(',');
      expect(result.findings.map((f) => f.code).toSet(), expected.toSet());
      expect(result.score, int.parse(fields[2]));
      expect(result.complete, isTrue);
    });
  }
  test('fake Telegram host is distinct from official host', () {
    expect(
      engine.link('t.me-premium.uz').findings.map((f) => f.code),
      contains('brand'),
    );
    expect(engine.link('https://t.me/premium').score, 0);
  });
  test('bare domains are extracted without turning email into a URL', () {
    expect(
      engine.extract('Try t.me-premium.uz, then telegram.example/login.'),
      ['t.me-premium.uz', 'telegram.example/login'],
    );
    expect(engine.extract('support@telegram.example'), isEmpty);
  });
  test('repeated domains do not multiply findings or canonical scans', () {
    expect(
      engine.links('t.me-premium.uz https://t.me-premium.uz/'),
      hasLength(1),
    );
    expect(engine.message('t.me-premium.uz t.me-premium.uz').score, 72);
  });
  test('bot warning is localized and does not claim identity verification', () {
    expect(label(StringsUz(), 'bot'), contains('tasdiqlanmaydi'));
  });
}
