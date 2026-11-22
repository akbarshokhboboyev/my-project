import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum HashLookupStatus {
  reported,
  noMatch,
  disabled,
  unconfigured,
  unavailable,
  rateLimited,
  invalidResponse,
}

class HashLookupResult {
  const HashLookupResult(
    this.status, {
    this.malicious = 0,
    this.suspicious = 0,
  });
  final HashLookupStatus status;
  final int malicious;
  final int suspicious;
}

/// Reports provider evidence without treating an engine count as a probability.
class FileHashReputationProvider {
  FileHashReputationProvider(this.endpoint, this.token);
  final Uri endpoint;
  final String token;

  Future<HashLookupResult> check(String hash, {required bool consent}) async {
    if (!consent) return const HashLookupResult(HashLookupStatus.disabled);
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(hash)) {
      return const HashLookupResult(HashLookupStatus.invalidResponse);
    }
    if (endpoint.scheme != 'https' ||
        endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty ||
        token.isEmpty) {
      return const HashLookupResult(HashLookupStatus.unconfigured);
    }
    final client = HttpClient();
    try {
      return await _query(client, hash).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      return const HashLookupResult(HashLookupStatus.unavailable);
    } on IOException {
      return const HashLookupResult(HashLookupStatus.unavailable);
    } on FormatException {
      return const HashLookupResult(HashLookupStatus.invalidResponse);
    } finally {
      client.close(force: true);
    }
  }

  Future<HashLookupResult> _query(HttpClient client, String hash) async {
    final request = await client.postUrl(endpoint);
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.write(jsonEncode({'sha256': hash.toLowerCase(), 'consent': true}));
    final response = await request.close();
    if (response.statusCode == 429) {
      return const HashLookupResult(HashLookupStatus.rateLimited);
    }
    if (response.statusCode != 200) {
      return const HashLookupResult(HashLookupStatus.unavailable);
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > 8192) throw const FormatException();
      bytes.addAll(chunk);
    }
    return parseHashLookup(jsonDecode(utf8.decode(bytes)));
  }
}

HashLookupResult parseHashLookup(dynamic value) {
  if (value is! Map) {
    return const HashLookupResult(HashLookupStatus.invalidResponse);
  }
  switch (value['status']) {
    case 'reported':
      final malicious = value['malicious'];
      final suspicious = value['suspicious'];
      if (malicious is! int ||
          suspicious is! int ||
          malicious < 0 ||
          suspicious < 0 ||
          malicious > 10000 ||
          suspicious > 10000) {
        return const HashLookupResult(HashLookupStatus.invalidResponse);
      }
      return HashLookupResult(
        HashLookupStatus.reported,
        malicious: malicious,
        suspicious: suspicious,
      );
    case 'not_found':
      return const HashLookupResult(HashLookupStatus.noMatch);
    case 'unconfigured':
      return const HashLookupResult(HashLookupStatus.unconfigured);
    case 'rate_limited':
      return const HashLookupResult(HashLookupStatus.rateLimited);
    case 'unavailable':
      return const HashLookupResult(HashLookupStatus.unavailable);
    default:
      return const HashLookupResult(HashLookupStatus.invalidResponse);
  }
}
