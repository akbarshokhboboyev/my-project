import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shieldguard/app/app.dart';
import 'package:shieldguard/core/platform.dart';

void main() {
  final pending = <Map<String, dynamic>>[];
  final calls = <String>[];
  setUp(() {
    pending.clear();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ShieldPlatform.channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'status' => {'intro': true},
            'history' || 'apkHistory' => [],
            'pending' => pending.isEmpty ? null : pending.removeAt(0),
            _ => null,
          };
        });
  });
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShieldApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('unmatched file location never exposes URI or raw GoException', (
    tester,
  ) async {
    await launch(tester);
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(ShieldApp)),
    );
    scope
        .read(routerProvider)
        .go(
          'content://synthetic.documents/PRIVATE_FILE.apk?token=PRIVATE_TOKEN',
        );
    await tester.pumpAndSettle();
    expect(find.byType(RouteRecoveryPage), findsOneWidget);
    expect(find.textContaining('GoException'), findsNothing);
    expect(find.textContaining('PRIVATE_FILE'), findsNothing);
    expect(find.textContaining('PRIVATE_TOKEN'), findsNothing);
    expect(
      find.textContaining('Fayl tekshirilgan yoki xavfsiz deb hisoblanmaydi.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Bosh sahifa'));
    await tester.pumpAndSettle();
    expect(find.byType(RouteRecoveryPage), findsNothing);
    expect(calls.where((c) => c == 'pick' || c == 'apkForward'), isEmpty);
  });
  testWidgets(
    'native incoming result recovers from a previous unmatched route',
    (tester) async {
      await launch(tester);
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(ShieldApp)),
      );
      scope.read(routerProvider).go('/old-file.apk');
      await tester.pumpAndSettle();
      pending.addAll([
        {'kind': 'fileProgress', 'busy': true},
        {
          'batch': [
            {
              'kind': 'file',
              'format': 'APK',
              'complete': false,
              'findings': {'filePermission': 0},
            },
          ],
        },
        {'kind': 'fileProgress', 'busy': false},
      ]);
      tester.binding.channelBuffers.push(
        ShieldPlatform.channel.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('incoming'),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(find.byType(RouteRecoveryPage), findsNothing);
      expect(find.text('Tekshiruv natijasi'), findsOneWidget);
      expect(find.textContaining('GoException'), findsNothing);
      expect(calls.where((c) => c == 'apkForward'), isEmpty);
    },
  );
  testWidgets(
    'returning home from recovery keeps the native incoming handler alive',
    (tester) async {
      await launch(tester);
      final router = ProviderScope.containerOf(
        tester.element(find.byType(ShieldApp)),
      ).read(routerProvider);
      router.go('content://synthetic.documents/OTHER_PRIVATE.apk');
      await tester.pumpAndSettle();
      expect(find.byType(RouteRecoveryPage), findsOneWidget);
      await tester.tap(find.text('Bosh sahifa'));
      await tester.pumpAndSettle();
      expect(find.byType(RouteRecoveryPage), findsNothing);
      pending.addAll([
        {'kind': 'fileProgress', 'busy': true},
        {
          'batch': [
            {
              'kind': 'file',
              'format': 'APK',
              'complete': false,
              'findings': {'filePermission': 0},
            },
          ],
        },
        {'kind': 'fileProgress', 'busy': false},
      ]);
      tester.binding.channelBuffers.push(
        ShieldPlatform.channel.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('incoming'),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(find.text('Tekshiruv natijasi'), findsOneWidget);
      expect(pending, isEmpty);
      expect(find.textContaining('OTHER_PRIVATE'), findsNothing);
      expect(
        find.textContaining('Ma’lum xavf belgisi topilmadi'),
        findsNothing,
      );
      expect(calls.where((c) => c == 'apkForward'), isEmpty);
    },
  );
}
