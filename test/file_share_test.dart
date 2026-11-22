import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shieldguard/app/app.dart';
import 'package:shieldguard/core/platform.dart';

void main() {
  final pending = <Map<String, dynamic>>[];
  final calls = <String>[];
  Map<String, dynamic> result(String format) => {
    'kind': 'file',
    'format': format,
    'complete': true,
    'signatureChecked': true,
    'findings': <String, int>{},
    'details': {'batchItem': 1},
  };
  setUp(() {
    pending.clear();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ShieldPlatform.channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'status' => {'intro': true},
            'history' => [],
            'pending' => pending.isEmpty ? null : pending.removeAt(0),
            _ => null,
          };
        });
  });
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShieldApp()));
    await tester.pumpAndSettle();
  }

  void incoming(WidgetTester tester) {
    tester.binding.channelBuffers.push(
      ShieldPlatform.channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('incoming'),
      ),
      (_) {},
    );
  }

  test('mixed batch keeps qualified per-file verdicts', () {
    final results = ShieldPlatform().decodeBatch({
      'batch': [
        result('APK'),
        {
          'complete': false,
          'findings': {'filePermission': 0},
        },
      ],
    });
    expect(results.length, 2);
    expect(results.first.signatureUnchecked, false);
    expect(results.last.verdict, 'verdictUnknown');
  });
  testWidgets('cold incoming batch shows Uzbek results', (tester) async {
    pending.addAll([
      {'kind': 'fileProgress', 'busy': true},
      {
        'batch': [result('PDF')],
      },
      {'kind': 'fileProgress', 'busy': false},
    ]);
    await launch(tester);
    expect(find.text('Tekshiruv natijasi'), findsOneWidget);
    expect(
      find.textContaining('Domen yoki fayl formati · PDF'),
      findsOneWidget,
    );
    expect(find.text('Tekshiruvni bekor qilish'), findsNothing);
    expect(calls.where((m) => m == 'pick'), isEmpty);
  });
  testWidgets('warm share gets results without a picker or online lookup', (
    tester,
  ) async {
    await launch(tester);
    pending.addAll([
      {'kind': 'fileProgress', 'busy': true},
      {
        'batch': [result('APK')],
      },
      {'kind': 'fileProgress', 'busy': false},
    ]);
    incoming(tester);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Domen yoki fayl formati · APK'),
      findsOneWidget,
    );
    expect(calls.any((m) => m == 'pick' || m.startsWith('cache')), false);
  });
  testWidgets('incoming cancellation and busy rejection preserve progress', (
    tester,
  ) async {
    await launch(tester);
    pending.add({'kind': 'fileProgress', 'busy': true});
    incoming(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Tekshiruvni bekor qilish'), findsOneWidget);
    pending.add({'kind': 'fileRejected', 'code': 'busy'});
    incoming(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Tekshiruvni bekor qilish'));
    await tester.pump();
    expect(calls, contains('cancelScan'));
    pending.addAll([
      {
        'batch': [
          {
            'kind': 'file',
            'complete': false,
            'findings': {'scanCancelled': 0},
          },
        ],
      },
      {'kind': 'fileProgress', 'busy': false},
    ]);
    incoming(tester);
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('Tekshiruv bekor qilindi'), findsWidgets);
  });
  testWidgets('legacy text sharing remains available', (tester) async {
    pending.add({'kind': 'text', 'text': 'https://telegram.example/premium'});
    await launch(tester);
    expect(find.text('Tekshiruv natijasi'), findsOneWidget);
    expect(find.textContaining('72/100'), findsOneWidget);
  });
}
