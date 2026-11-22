import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shieldguard/app/app.dart';
import 'package:shieldguard/core/platform.dart';

void main() {
  Map<String, dynamic>? fileResult;
  Map<String, dynamic> protection = {};
  setUp(() {
    fileResult = null;
    protection = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          ShieldPlatform.channel,
          (call) async => switch (call.method) {
            'status' => {'intro': true, 'enabled': false, ...protection},
            'history' => [],
            'pick' => fileResult,
            _ => null,
          },
        );
  });

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShieldApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('Uzbek dashboard', (tester) async {
    await launch(tester);
    expect(find.text('ShieldGuard'), findsOneWidget);
    expect(find.text('Himoya o‘chirilgan'), findsOneWidget);
  });

  testWidgets('online scan with missing server preserves local findings', (
    tester,
  ) async {
    protection = {'onlineConsent': true};
    await launch(tester);
    await tester.tap(find.text('Havolani tekshirish').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'https://telegram.example/premium',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Tekshirish'));
    await tester.pumpAndSettle();
    expect(find.text('Yuqori xavf'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('HTTPS server'), 300,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    expect(find.textContaining('HTTPS server'), findsOneWidget);
  });

  testWidgets('online settings disclose full URL transfer and hide token', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.textContaining('To‘liq URL'), findsOneWidget);
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.length, 2);
    expect(fields.last.obscureText, true);
  });

  testWidgets('manual phishing scan', (tester) async {
    await launch(tester);
    await tester.tap(find.text('Havolani tekshirish').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'https://telegram.example/premium',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Tekshirish'));
    await tester.pumpAndSettle();
    expect(find.text('Yuqori xavf'), findsOneWidget);
    expect(find.textContaining('telegram.example'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('protection disclosure', (tester) async {
    await launch(tester);
    await tester.tap(find.byIcon(Icons.shield_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Roziman, himoyani yoqish'), findsOneWidget);
    expect(find.textContaining('Android ushbu ruxsat'), findsOneWidget);
  });

  testWidgets('dark theme switch', (tester) async {
    await launch(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qorong‘i mavzu'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('file result explains a signature mismatch', (tester) async {
    fileResult = {
      'kind': 'file',
      'format': 'PDF',
      'hash': 'b' * 64,
      'complete': true,
      'findings': {'mismatch': 55},
    };
    await launch(tester);
    await tester.tap(find.text('Faylni tekshirish').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Faylni tanlash'));
    await tester.pumpAndSettle();
    expect(find.text('Yuqori xavf'), findsOneWidget);
    expect(find.textContaining('imzosi kengaytmasiga'), findsOneWidget);
  });

  testWidgets('cancelled file selector has localized feedback', (tester) async {
    await launch(tester);
    await tester.tap(find.text('Faylni tekshirish').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Faylni tanlash'));
    await tester.pumpAndSettle();
    expect(find.text('Fayl tanlash bekor qilindi'), findsOneWidget);
  });

  testWidgets('revoked access is reflected by the protection screen', (
    tester,
  ) async {
    protection = {
      'enabled': true,
      'access': false,
      'connected': false,
      'alerts': true,
    };
    await launch(tester);
    await tester.tap(find.byIcon(Icons.shield_outlined));
    await tester.pumpAndSettle();
    expect(
      find.text('Bildirishnomalarga kirish ruxsati kerak'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Ruxsat berish'), findsOneWidget);
  });
}
