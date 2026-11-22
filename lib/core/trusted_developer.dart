class TrustedDeveloperReference {
  const TrustedDeveloperReference({
    required this.package,
    required this.certificates,
    required this.source,
    required this.verifiedAt,
  });
  final String package;
  final Set<String> certificates;
  final Uri source;
  final DateTime verifiedAt;
}

class TrustedDeveloperRegistry {
  TrustedDeveloperRegistry(Iterable<TrustedDeveloperReference> references)
    : references = List.unmodifiable(references);
  final List<TrustedDeveloperReference> references;
  bool matches({
    required String package,
    required Set<String> certificates,
    required bool signatureVerified,
  }) {
    if (!signatureVerified || certificates.isEmpty) return false;
    return references.any(
      (reference) =>
          reference.package == package &&
          reference.source.scheme == 'https' &&
          reference.certificates.isNotEmpty &&
          reference.certificates.length == certificates.length &&
          reference.certificates.containsAll(certificates),
    );
  }
}
