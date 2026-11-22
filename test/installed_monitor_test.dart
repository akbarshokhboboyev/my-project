import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shieldguard/app/app.dart';
import 'package:shieldguard/core/platform.dart';

void main() {
  final platform = ShieldPlatform();
  var enabled = false;
  var scans = 0;
  final calls = <String>[];
  setUp(() {
    enabled = false;
    scans = 0;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ShieldPlatform.channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'status':
              return {
                'intro': true,
                'enabled': false,
                'appMonitoring': enabled,
                'appScheduled': enabled,
                'appLastState': 'metadata',
                'appAlerts': false,
                'appHasReport': true,
              };
            case 'option':
              if (call.arguments['key'] == 'appMonitoring') {
                enabled = call.arguments['value'] as bool;
              }
              return null;
            case 'installedScan':
              if (enabled) scans++;
              return null;
            case 'installedReport':
              return {
                'kind': 'file',
                'format': 'APK',
                'complete': false,
                'signatureChecked': false,
                'signers': <String>[],
                'details': {'installedCoverage': 'installedMetadataOnly'},
                'findings': {
                  'installedMetadataOnly': 0,
                  'installedTrustUnknown': 0,
                },
              };
            case 'history':
              return [];
            default:
              return null;
          }
        });
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShieldApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.shield_outlined).last);
    await tester.pumpAndSettle();
    final toggle = find.widgetWithText(
      SwitchListTile,
      'O‘rnatilgan ilovalar monitoringi',
    );
    await tester.scrollUntilVisible(
      toggle,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(toggle), alignment: 0.3);
    await tester.pumpAndSettle();
  }

  test(
    'metadata-only report remains unknown and signature unchecked',
    () async {
      final raw = await platform.installedReport();
      final result = platform.decode(raw!);
      expect(result.complete, false);
      expect(result.verdict, 'verdictUnknown');
      expect(result.signatureUnchecked, true);
      expect(result.score, 0);
    },
  );
  testWidgets('installed monitoring opt-in is independent of Telegram access', (
    tester,
  ) async {
    await open(tester);
    final toggle = find.widgetWithText(
      SwitchListTile,
      'O‘rnatilgan ilovalar monitoringi',
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(enabled, true);
    expect(calls, isNot(contains('access')));
    expect(find.text('Davriy tekshiruv rejalashtirilgan.'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(enabled, false);
    expect(
      find.text('Ko‘rinadigan ilovalarni tekshirishni rejalashtirish'),
      findsNothing,
    );
  });
  testWidgets('schedule button stays local and exposes partial coverage', (
    tester,
  ) async {
    enabled = true;
    await open(tester);
    expect(find.textContaining('Faqat ko‘rinadigan paketlar'), findsOneWidget);
    final button = find.text(
      'Ko‘rinadigan ilovalarni tekshirishni rejalashtirish',
    );
    await Scrollable.ensureVisible(tester.element(button), alignment: 0.3);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(scans, 1);
    expect(calls.any((m) => m.startsWith('cache') || m == 'pick'), false);
  });
  test('permission/visibility failure is not a benign result', () {
    final result = platform.decode({
      'kind': 'file',
      'complete': false,
      'findings': {'installedUnavailable': 0},
    });
    expect(result.verdict, 'verdictUnknown');
  });
  testWidgets('latest report shows Uzbek coverage and a qualified verdict', (
    tester,
  ) async {
    enabled = true;
    await open(tester);
    final button = find.text('Oxirgi ilova hisobotini ko‘rish');
    await Scrollable.ensureVisible(tester.element(button), alignment: 0.3);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Tekshiruv qamrovi · APK kontenti to‘liq tekshirilmadi',
      ),
      findsOneWidget,
    );
    expect(find.text('installedMetadataOnly'), findsNothing);
    expect(find.text('Aniqlab bo‘lmadi'), findsWidgets);
  });
}
