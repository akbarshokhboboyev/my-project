import 'package:flutter/services.dart';

import 'engine.dart';

class ShieldPlatform {
  static const channel = MethodChannel('uz.app.shieldguard/platform');

  Future<Map<String, dynamic>> status() async =>
      await channel.invokeMapMethod<String, dynamic>('status') ?? {};

  Future<void> setOption(String key, bool value) =>
      channel.invokeMethod<void>('option', {'key': key, 'value': value});

  Future<void> scanInstalled() => channel.invokeMethod<void>('installedScan');
  Future<Map<String, dynamic>?> installedReport() =>
      channel.invokeMapMethod<String, dynamic>('installedReport');

  Future<void> openAccess() => channel.invokeMethod<void>('access');
  Future<void> allowAlerts() => channel.invokeMethod<void>('alerts');

  Future<Map<String, dynamic>?> pick() =>
      channel.invokeMapMethod<String, dynamic>('pick');

  Future<Map<String, dynamic>?> pending() =>
      channel.invokeMapMethod<String, dynamic>('pending');

  Future<List<Map<String, dynamic>>> history() async =>
      (await channel.invokeListMethod<Map>('history') ?? [])
          .map(Map<String, dynamic>.from)
          .toList();

  Future<void> clear() => channel.invokeMethod<void>('clear');
  Future<void> record(ScanResult result) =>
      channel.invokeMethod<void>('record', {
        'type': result.type.name,
        'score': result.score,
        'count': result.findings.length,
        'complete': result.complete,
        'time': result.time.millisecondsSinceEpoch,
      });

  ScanResult decode(Map<dynamic, dynamic> value) => ScanResult(
    value['kind'] == 'alert' ? ThreatType.notification : ThreatType.file,
    (value['findings'] as Map? ?? {}).entries.map(
      (e) => Finding(e.key as String, e.value as int),
    ),
    subject: value['format'] as String?,
    hash: value['hash'] as String?,
    details: Map<String, dynamic>.from(value['details'] as Map? ?? {}),
    signatureUnchecked:
        (value['format'] as String? ?? '').startsWith('APK') &&
        value['signatureChecked'] != true,
    signers: List<String>.unmodifiable(value['signers'] as List? ?? []),
    scannedAt: switch (value['time']) {
      final int time when time > 0 => DateTime.fromMillisecondsSinceEpoch(time),
      _ => null,
    },
    complete: value['complete'] == true,
  );
}
