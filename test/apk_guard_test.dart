import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shieldguard/app/app.dart';
import 'package:shieldguard/core/platform.dart';

void main() {
  final pending = <Map<String, dynamic>>[];
  final calls = <MethodCall>[];
  final options = <String, bool>{};
  Map<String, dynamic> apk(
    String outcome,
    String risk, {
    bool blocked = true,
  }) => {
    'kind': 'file',
    'format': 'APK',
    'complete': risk != 'unknown',
    'findings': <String, int>{},
    'signatureChecked': true,
    'details': {
      'apkToken': 'private-test-token',
      'apkGate': {'outcome': outcome, 'blocked': blocked},
      'apkAssessment': {
        'risk': risk,
        'confidence': 'high',
        'score': 30,
        'evidence': ['signatureFailed'],
      },
    },
  };
  setUp(() {
    pending.clear();
    calls.clear();
    options.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ShieldPlatform.channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'status':
              return {'intro': true, ...options};
            case 'history':
            case 'apkHistory':
              return [];
            case 'pending':
              return pending.isEmpty ? null : pending.removeAt(0);
            case 'option':
              options[call.arguments['key'] as String] =
                  call.arguments['value'] as bool;
              return null;
            case 'apkForward':
              return {
                'blocked': false,
                'outcome': 'warningOnly',
                'handoffRequested': true,
              };
            default:
              return null;
          }
        });
  });
  Future<void> launch(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const ProviderScope(child: ShieldApp()));
    await tester.pumpAndSettle();
  }

  Future<void> visible(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 30 && target.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
  }

  test('background lifecycle never permits forced popup', () {
    expect(ThreatPopupManager.canShow(AppLifecycleState.paused), false);
    expect(ThreatPopupManager.canShow(AppLifecycleState.inactive), false);
    expect(ThreatPopupManager.canShow(null), false);
    expect(ThreatPopupManager.canShow(AppLifecycleState.resumed), true);
  });
  testWidgets('strong gate shows Uzbek modal and never forwards', (
    tester,
  ) async {
    pending.add(apk('blockedByShieldGuard', 'strongSuspicion'));
    await launch(tester);
    expect(find.text('APK BLOKLANDI'), findsOneWidget);
    expect(
      find.textContaining(
        'ShieldGuard orqali ochish/o‘rnatishga uzatish to‘xtatildi.',
      ),
      findsOneWidget,
    );
    expect(calls.where((c) => c.method == 'apkForward'), isEmpty);
    await tester.tap(find.text('Yopish'));
    await tester.pumpAndSettle();
    expect(find.text('APK nusxasini boshqa ilovada ochish'), findsNothing);
    expect(find.textContaining('private-test-token'), findsNothing);
  });
  testWidgets('strict incomplete is a precaution, not malware confirmation', (
    tester,
  ) async {
    pending.add(apk('scanIncomplete', 'unknown'));
    await launch(tester);
    expect(find.text('APK uzatish to‘xtatildi'), findsOneWidget);
    expect(find.text('APK BLOKLANDI'), findsNothing);
    await tester.tap(find.text('Yopish'));
    await tester.pumpAndSettle();
  });
  testWidgets('heuristic report never opens blocking popup or auto forwards', (
    tester,
  ) async {
    pending.add(apk('warningOnly', 'heuristicWarning', blocked: false));
    await launch(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(calls.where((c) => c.method == 'apkForward'), isEmpty);
    expect(find.textContaining('private-test-token'), findsNothing);
  });
  testWidgets('external open requires separate explicit confirmation', (
    tester,
  ) async {
    pending.add(apk('warningOnly', 'noFindings', blocked: false));
    await launch(tester);
    final open = find.text('APK nusxasini boshqa ilovada ochish');
    await visible(tester, open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'apkForward'), isEmpty);
    await tester.tap(find.text('Ogohlantirishni tushundim, uzatish'));
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'apkForward').single.arguments, {
      'token': 'private-test-token',
    });
    expect(
      calls.where((c) => c.method.toLowerCase().contains('installpackage')),
      isEmpty,
    );
  });
  testWidgets('cancel confirmation never forwards', (tester) async {
    pending.add(apk('warningOnly', 'unknown', blocked: false));
    await launch(tester);
    final open = find.text('APK nusxasini boshqa ilovada ochish');
    await visible(tester, open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yopish'));
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'apkForward'), isEmpty);
  });
  testWidgets('install source settings only navigate at explicit action', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    final settings = find.text('O‘rnatish ruxsatlarini tekshirish');
    await visible(tester, settings);
    expect(calls.where((c) => c.method == 'installSourceSettings'), isEmpty);
    await tester.tap(settings);
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'installSourceSettings').length, 1);
  });
  testWidgets('strict and background notification default off', (tester) async {
    await launch(tester);
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    final strict = find.widgetWithText(SwitchListTile, 'Qat’iy APK himoyasi');
    await visible(tester, strict);
    expect(tester.widget<SwitchListTile>(strict).value, false);
    final alerts = find.widgetWithText(
      SwitchListTile,
      'Ruxsatli papkadagi shubhali APK haqida bildirishnoma',
    );
    await visible(tester, alerts);
    expect(tester.widget<SwitchListTile>(alerts).value, false);
  });
  testWidgets('local APK history has a separate clear action', (tester) async {
    await launch(tester);
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    final clear = find.text('APK tarixini tozalash');
    await visible(tester, clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'apkHistoryClear').length, 1);
    expect(calls.where((c) => c.method == 'clear'), isEmpty);
  });
}
