import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shieldguard/core/platform.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android saves and restores the theme preference', (
    tester,
  ) async {
    final platform = ShieldPlatform();
    final original = (await platform.status())['dark'] as bool;
    try {
      await platform.setOption('dark', !original);
      expect((await ShieldPlatform().status())['dark'], !original);
    } finally {
      await platform.setOption('dark', original);
    }
  });

  testWidgets('Android bridge returns typed status and metadata history', (
    tester,
  ) async {
    final platform = ShieldPlatform();
    final status = await platform.status();
    for (final key in [
      'access',
      'connected',
      'enabled',
      'alerts',
      'history',
      'intro',
    ]) {
      expect(status[key], isA<bool>());
    }
    for (final row in await platform.history()) {
      expect(
        row.keys,
        unorderedEquals(['type', 'score', 'count', 'complete', 'time']),
      );
    }
  });
}
