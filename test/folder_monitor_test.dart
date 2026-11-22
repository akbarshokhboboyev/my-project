import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shieldguard/app/app.dart';
import 'package:shieldguard/core/platform.dart';

void main() {
  var enabled = false;
  var state = 'idle';
  var partial = true;
  final roots = <Map<String, dynamic>>[];
  final calls = <MethodCall>[];
  var scanned = 0;
  var unverified = 0;
  setUp(() {
    enabled = false;
    state = 'idle';
    partial = true;
    roots.clear();
    calls.clear();
    scanned = 0;
    unverified = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ShieldPlatform.channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'status':
              return {
                'intro': true,
                'folderSecurity': {
                  'enabled': enabled,
                  'scheduled': enabled,
                  'state': state,
                  'roots': roots.toList(),
                  'scanned': scanned,
                  'unverified': unverified,
                  'partial': partial,
                  'lastScan': 0,
                  'indicators': <String>[],
                },
              };
            case 'history':
              return [];
            case 'folderPick':
              roots.add({
                'id': 'synthetic-folder',
                'label': 'Sinov papka',
                'granted': true,
              });
              return null;
            case 'folderEnabled':
              if (call.arguments['value'] == true &&
                  roots.any((r) => r['granted'] != true)) {
                throw PlatformException(code: 'folderPermission');
              }
              enabled = call.arguments['value'] as bool;
              if (!enabled) roots.clear();
              return null;
            case 'folderRemove':
              roots.removeWhere((r) => r['id'] == call.arguments['id']);
              return null;
            case 'folderScan':
              state = 'queued';
              return null;
            case 'folderCancel':
              state = 'cancelled';
              partial = true;
              return null;
            default:
              return null;
          }
        });
  });
  Future<void> visible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.25);
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShieldApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.shield_outlined).last);
    await tester.pumpAndSettle();
    await visible(
      tester,
      find.widgetWithText(SwitchListTile, 'Davriy papka tekshiruvini yoqish'),
    );
  }

  testWidgets('folder monitoring defaults off and never starts automatically', (
    tester,
  ) async {
    await open(tester);
    final toggle = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Davriy papka tekshiruvini yoqish'),
    );
    expect(toggle.value, false);
    expect(toggle.onChanged, isNull);
    expect(
      calls.any((c) => c.method == 'folderScan' || c.method == 'folderPick'),
      false,
    );
  });
  testWidgets(
    'folder selection is explicit and independent of Telegram access',
    (tester) async {
      await open(tester);
      final add = find.text('Papka qo‘shish');
      await visible(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(roots.length, 1);
      expect(enabled, false);
      expect(find.text('Sinov papka'), findsOneWidget);
      expect(
        calls.any(
          (c) =>
              c.method == 'access' ||
              c.method == 'alerts' ||
              c.method == 'pick',
        ),
        false,
      );
    },
  );
  testWidgets('opt-out clears authorized folders', (tester) async {
    roots.add({'id': 'one', 'label': 'Sinov papka', 'granted': true});
    await open(tester);
    final toggle = find.widgetWithText(
      SwitchListTile,
      'Davriy papka tekshiruvini yoqish',
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(enabled, true);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(enabled, false);
    expect(roots, isEmpty);
  });
  testWidgets(
    'manual folder scan and cancellation use their own bridge actions',
    (tester) async {
      roots.add({'id': 'one', 'label': 'Sinov papka', 'granted': true});
      await open(tester);
      final now = find.text('Hozir tekshirish');
      await visible(tester, now);
      await tester.tap(now);
      await tester.pumpAndSettle();
      expect(state, 'queued');
      final cancel = find.text('Joriy papka tekshiruvini bekor qilish');
      await visible(tester, cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(state, 'cancelled');
      expect(
        calls.any(
          (c) => c.method == 'cancelScan' || c.method == 'installedScan',
        ),
        false,
      );
    },
  );
  testWidgets(
    'revoked permission stays unknown and does not enable monitoring',
    (tester) async {
      roots.add({'id': 'one', 'label': 'Sinov papka', 'granted': false});
      state = 'permissionLost';
      await open(tester);
      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Davriy papka tekshiruvini yoqish'),
      );
      await tester.pumpAndSettle();
      expect(enabled, false);
      expect(find.textContaining('Papka ruxsati yo‘q'), findsWidgets);
    },
  );
  testWidgets('partial counters are localized without a safe verdict', (
    tester,
  ) async {
    scanned = 8;
    unverified = 249;
    await open(tester);
    await visible(
      tester,
      find.text('Tekshirilmagan yoki incomplete (kamida) · 249'),
    );
    expect(find.textContaining('Qamrov qisman'), findsOneWidget);
    expect(find.text('Xavfsiz'), findsNothing);
  });
  testWidgets('remove sends only the selected local folder ID', (tester) async {
    roots.add({'id': 'one', 'label': 'Sinov papka', 'granted': true});
    await open(tester);
    final remove = find.byTooltip('Papkani olib tashlash');
    await visible(tester, remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(roots, isEmpty);
    expect(calls.firstWhere((c) => c.method == 'folderRemove').arguments, {
      'id': 'one',
    });
  });
}
