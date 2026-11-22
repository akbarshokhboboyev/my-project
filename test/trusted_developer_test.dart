import 'package:flutter_test/flutter_test.dart';
import 'package:shieldguard/core/trusted_developer.dart';

void main() {
  final registry = TrustedDeveloperRegistry([
    TrustedDeveloperReference(
      package: 'example.fixture',
      certificates: {'fixture-only'},
      source: Uri.parse('https://example.test/reference'),
      verifiedAt: DateTime(2026),
    ),
  ]);
  test(
    'name alone cannot establish identity',
    () => expect(
      registry.matches(
        package: 'example.fixture',
        certificates: {},
        signatureVerified: true,
      ),
      false,
    ),
  );
  test(
    'invalid signature cannot establish identity',
    () => expect(
      registry.matches(
        package: 'example.fixture',
        certificates: {'fixture-only'},
        signatureVerified: false,
      ),
      false,
    ),
  );
  test(
    'certificate set must agree',
    () => expect(
      registry.matches(
        package: 'example.fixture',
        certificates: {'different'},
        signatureVerified: true,
      ),
      false,
    ),
  );
  test(
    'empty production registry trusts no package',
    () => expect(
      TrustedDeveloperRegistry([]).matches(
        package: 'uz.egov.oneId',
        certificates: {'fixture-only'},
        signatureVerified: true,
      ),
      false,
    ),
  );
  test(
    'explicit reference with valid signature matches',
    () => expect(
      registry.matches(
        package: 'example.fixture',
        certificates: {'fixture-only'},
        signatureVerified: true,
      ),
      true,
    ),
  );
}
