part of 'app.dart';

class ThreatPopupManager {
  static bool canShow(AppLifecycleState? state) =>
      state == AppLifecycleState.resumed;
  static Future<String?> show(
    BuildContext context,
    bool threat,
    Map assessment,
  ) => showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        label(context.l, threat ? 'apkBlockedTitle' : 'apkIncompleteTitle'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label(context.l, 'apkRisk${assessment['risk']}')),
            Text(label(context.l, 'apkConfidence${assessment['confidence']}')),
            for (final code
                in (assessment['evidence'] as List? ?? [])
                    .whereType<String>()
                    .take(64))
              Text(label(context.l, code)),
            Text(label(context.l, 'apkBlockedBody')),
          ],
        ),
      ),
      actions: [
        for (final key in ['apkDetails', 'close', 'apkAdviceButton'])
          TextButton(
            onPressed: () => Navigator.pop(context, key),
            child: Text(label(context.l, key)),
          ),
      ],
    ),
  );
}

extension _ApkGuardUi on _WorkspaceState {
  Future<void> showApkGate(Map<String, dynamic> details) async {
    final gate = details['apkGate'];
    if (gate is! Map ||
        gate['outcome'] is! String ||
        !['blockedByShieldGuard', 'scanIncomplete'].contains(gate['outcome'])) {
      return;
    }
    if (!ThreatPopupManager.canShow(WidgetsBinding.instance.lifecycleState)) {
      deferredApkDialog = details;
      return;
    }
    final id =
        '${details['apkToken'] ?? details['apkAssessment']}:${gate['outcome']}';
    if (!apkDialogs.add(id)) return;
    if (apkDialogs.length > 64) apkDialogs.remove(apkDialogs.first);
    if (!mounted) return;
    final action = await ThreatPopupManager.show(
      context,
      gate['outcome'] == 'blockedByShieldGuard',
      details['apkAssessment'] as Map? ?? {},
    );
    if (mounted && action == 'apkAdviceButton') {
      await info('apkAdviceButton', 'apkAdvice');
    }
  }

  List<Widget> apkResult(ScanResult result) {
    final assessment = result.details['apkAssessment'];
    if (assessment is! Map) return [];
    final gate = result.details['apkGate'];
    final token = result.details['apkToken'];
    return [
      heading('apkTitle'),
      Text(l('apkRisk${assessment['risk']}')),
      Text(l('apkConfidence${assessment['confidence']}')),
      Text('${l('score')} · ${assessment['score'] ?? 0}/100'),
      if (gate is Map) Text(l('apkOutcome${gate['outcome']}')),
      Text(l('apkBoundary')),
      if (token is String && gate is Map && gate['blocked'] != true)
        button(
          'apkOpen',
          () => act(() async {
            final approved = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l('apkForwardConfirm')),
                content: SingleChildScrollView(
                  child: Text(l('apkForwardHelp')),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l('close')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l('apkProceed')),
                  ),
                ],
              ),
            );
            if (approved != true || !mounted) return;
            final response = await platform.forwardApk(token);
            if (response?['blocked'] == true) {
              await showApkGate({...result.details, 'apkGate': response});
            }
            await refresh();
          }),
        ),
    ];
  }

  List<Widget> apkProtection() => [
    card([
      heading('apkTitle'),
      Text(l('apkBoundary')),
      SwitchListTile(
        title: Text(l('apkAutoBlock')),
        value: status['apkAutoBlock'] != false,
        onChanged: (value) => option('apkAutoBlock', value),
      ),
      Text(l('apkOffHelp')),
      SwitchListTile(
        title: Text(l('apkStrict')),
        value: status['apkStrict'] == true,
        onChanged: status['apkAutoBlock'] == false
            ? null
            : (value) => option('apkStrict', value),
      ),
      Text(l('apkStrictHelp')),
      SwitchListTile(
        title: Text(l('apkAlerts')),
        value: status['apkAlerts'] == true,
        onChanged: status['apkAutoBlock'] == false
            ? null
            : (value) => option('apkAlerts', value),
      ),
      Text(l('apkAlertsHelp')),
      button('grantAlerts', () => act(platform.allowAlerts)),
      Text(l('apkSources')),
      button('apkSettings', () => act(platform.installSourceSettings)),
      heading('apkHistory'),
      button(
        'apkClear',
        () => act(() async {
          await platform.clearApkHistory();
          await refresh();
        }),
      ),
      if (apkEntries.isEmpty) Text(l('apkHistoryEmpty')),
      for (final row in apkEntries)
        ListTile(
          title: Text(l('apkOutcome${row['outcome']}')),
          subtitle: Text(
            '${l('apkRisk${row['risk']}')}\n${stamp(row['time'] as int)}',
          ),
          onTap: () => act(() async {
            final report = await platform.apkReport(row['id'] as String);
            if (report != null) {
              await present([platform.decode(report)], record: false);
            }
          }),
        ),
    ]),
  ];
}
