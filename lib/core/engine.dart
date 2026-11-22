enum ThreatType { link, message, file, notification }

enum ThreatLevel { low, caution, high, severe }

enum Confidence { limited, moderate, strong }

class Finding {
  const Finding(this.code, this.weight);
  final String code;
  final int weight;
  String get id => code;
  String get category => code == 'reputationMatch'
      ? 'reputation'
      : {'structure', 'mismatch', 'archivePath'}.contains(code)
      ? 'structure'
      : 'heuristic';
  ThreatLevel get severity => ScanResult.levelForScore(weight);
  String get evidence => code;
  Confidence get confidence =>
      category == 'reputation' ? Confidence.strong : Confidence.moderate;
  String get detectionMethod => category;
  String get limitations => category == 'reputation' ? 'online' : 'local';
  String get recommendedAction => 'advice';
}

class ScanResult {
  ScanResult(
    this.type,
    Iterable<Finding> findings, {
    this.subject,
    this.hash,
    this.signers = const [],
    this.complete = true,
    this.source = 'local',
    this.reputation = 'disabled',
    this.details = const {},
    this.signatureUnchecked = false,
    DateTime? scannedAt,
  }) : findings = List.unmodifiable(findings),
       time = scannedAt ?? DateTime.now();
  final ThreatType type;
  final List<Finding> findings;
  final DateTime time;
  final String? subject;
  final String? hash;
  final List<String> signers;
  final bool complete;
  final String source;
  final String reputation;
  final Map<String, dynamic> details;
  final bool signatureUnchecked;
  int get score =>
      {for (final f in findings) f.code: f.weight}.values
          .fold<int>(0, (sum, weight) => sum + weight)
          .clamp(0, 100);
  ThreatLevel get level => levelForScore(score);
  static ThreatLevel levelForScore(int score) =>
      ThreatLevel.values[score < 25
          ? 0
          : score < 50
          ? 1
          : score < 75
          ? 2
          : 3];
  Confidence get confidence => !complete || findings.isEmpty
      ? Confidence.limited
      : findings.any((f) => f.code == 'reputationMatch')
      ? Confidence.strong
      : type == ThreatType.file && findings.any((f) => f.code == 'mismatch')
      ? Confidence.strong
      : Confidence.moderate;
}

class ThreatEngine {
  static final _links = RegExp(
    r'(?:https?://|www\.)[^\s<>"«»]+',
    caseSensitive: false,
  );
  static final _domain = RegExp(
    r'^(?:[\p{L}\p{N}](?:[\p{L}\p{N}-]{0,61}[\p{L}\p{N}])?\.)+[\p{L}\p{N}-]{1,63}$',
    unicode: true,
  );
  static const trusted = {'t.me', 'telegram.org', 'telegram.me'};
  static const _lookalikes = {
    'а': 'a',
    'е': 'e',
    'г': 'r',
    'і': 'i',
    'ӏ': 'l',
    'м': 'm',
    'о': 'o',
    'р': 'p',
    'т': 't',
    'α': 'a',
    'ε': 'e',
    'τ': 't',
  };
  static bool official(String host) =>
      trusted.any((d) => host == d || host.endsWith('.$d'));

  Uri? normalize(String input) {
    final text = input.trim();
    if (text.isEmpty ||
        text.length > 4096 ||
        RegExp(r'[\s\\\x00-\x1f\u202a-\u202e\u2066-\u2069]').hasMatch(text)) {
      return null;
    }
    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) return null;
    try {
      final host = Uri.decodeComponent(uri.host)
          .toLowerCase()
          .replaceFirst(RegExp(r'\.$'), '');
      if (host.length > 253 ||
          (!_domain.hasMatch(host) && !host.contains(':'))) {
        return null;
      }
      if (uri.port < 1 || uri.port > 65535) return null;
      return uri
          .replace(host: host, path: uri.path.isEmpty ? '/' : null)
          .removeFragment()
          .normalizePath();
    } on FormatException {
      return null;
    }
  }

  List<String> extract(String text) => _links
      .allMatches(text)
      .take(100)
      .map((m) => m[0]!.replaceFirst(RegExp(r'[.,!?;:)}]+$'), ''))
      .toList();

  List<ScanResult> links(String input) {
    final candidates = extract(input);
    if (candidates.isEmpty && !input.trim().contains(RegExp(r'\s'))) {
      candidates.add(input.trim());
    }
    final seen = <String>{};
    return [
      for (final entry in candidates)
        if (seen.add(normalize(entry)?.toString() ?? entry)) link(entry),
    ];
  }

  ScanResult link(String input) {
    final uri = normalize(input);
    if (uri == null) {
      return ScanResult(ThreatType.link, [
        const Finding('invalid', 0),
      ], complete: false);
    }
    final host = Uri.decodeComponent(uri.host);
    final isOfficial = official(host);
    final context = [host, uri.path, uri.query].join(' ').toLowerCase();
    final hostSkeleton = host.split('').map((c) => _lookalikes[c] ?? c).join();
    final brand = RegExp(r'telegram|te1egram|teiegram|teleqram|(?:^|\.)t\.me\.')
        .hasMatch(hostSkeleton);
    final sensitive = RegExp(
      r'login|verify|verification|confirm|premium|gift|bonus|password|signin',
    ).hasMatch(context);
    return ScanResult(ThreatType.link, [
      if (uri.scheme == 'http') const Finding('http', 10),
      if (uri.userInfo.isNotEmpty) const Finding('userinfo', 35),
      if (host.contains(':') || RegExp(r'^\d+(?:\.\d+)+$').hasMatch(host))
        const Finding('ip', 25),
      if (host.split('.').any((s) => s.startsWith('xn--')) ||
          host.codeUnits.any((n) => n > 127))
        const Finding('idn', 30),
      if ({
        'bit.ly',
        'tinyurl.com',
        't.co',
        'cutt.ly',
        'is.gd',
        'rb.gy',
      }.contains(host))
        const Finding('short', 25),
      if (!isOfficial && brand) const Finding('brand', 45),
      if (!isOfficial && sensitive) const Finding('lure', 18),
    ], subject: host);
  }

  static final _request = RegExp(
    r'yubor|kiriting|bering|ayting|jo.nat|tasdiqlang|send|enter|provide|share|submit|введ|отправ|пришл|сообщ|подтверд',
  );
  static final _secret = RegExp(
    r'tasdiqlash kodi|sms.kod|telegram kodi|parol|otp|verification code|confirmation code|security code|password|passcode|код|парол',
  );
  static final _warning = RegExp(
    r'hech kimga|yubormang|bermang|do not share|never share|никому|не сообщайте',
  );
  static final _urgent = RegExp(
    r'zudlik|bloklan|darhol|shoshil|urgent|suspend|blocked|срочно|блокир',
  );
  static final _gift = RegExp(r'premium|sovg.a|gift|подар');
  static final _support = RegExp(r'q.ollab.quvvatlash|support|поддержк');
  static final _install = RegExp(r'install|o.rnat|установ');

  ScanResult message(String input) {
    final text = input.substring(0, input.length.clamp(0, 32000)).toLowerCase();
    final urls = extract(text).map(link).toList();
    final requestsSecret = text
        .split(RegExp(r'[\n.!?;]+'))
        .any(
          (clause) =>
              _secret.hasMatch(clause) &&
              _request.hasMatch(clause) &&
              !_warning.hasMatch(clause),
        );
    return ScanResult(ThreatType.message, [
      if (requestsSecret) const Finding('secret', 55),
      if (_gift.hasMatch(text) &&
          (requestsSecret || urls.any((r) => r.score >= 25)))
        const Finding('gift', 22),
      if (_urgent.hasMatch(text) &&
          (_request.hasMatch(text) || urls.isNotEmpty))
        const Finding('urgent', 23),
      if (_support.hasMatch(text) && requestsSecret)
        const Finding('support', 20),
      if (_install.hasMatch(text) && (urls.isNotEmpty || text.contains('.apk')))
        const Finding('install', 30),
      if (urls.any((r) => r.score >= 50))
        const Finding('messageLink', 45)
      else if (urls.any((r) => r.score >= 25))
        const Finding('messageLink', 25),
    ], complete: input.length <= 32000);
  }
}
