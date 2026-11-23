part of 'app.dart';

class ThreatPopupManager {
  static bool canShow(AppLifecycleState? state) =>
      state == AppLifecycleState.resumed;
  static String kind(Map assessment, Map gate) =>
      gate['blocked'] == true && gate['outcome'] == 'blockedByShieldGuard'
      ? 'Blocked'
      : assessment['risk'] == 'unknown' ||
            assessment['complete'] != true ||
            gate['outcome'] == 'scanIncomplete'
      ? 'Unknown'
      : assessment['risk'] == 'noFindings'
      ? 'Clear'
      : 'Warning';
  static Color color(String kind) => switch (kind) {
    'Blocked' => const Color(0xffb3261e),
    'Warning' => const Color(0xff9b6500),
    'Clear' => const Color(0xff146c2e),
    _ => const Color(0xff59636e),
  };
  static Future<String?> show(
    BuildContext context,
    String kind,
    Map assessment,
    Map gate,
    List<String> reasons,
  ) => showDialog<String>(
    context: context,
    builder: (context) {
      String l(String key) => label(context.l, key);
      final blocked = gate['blocked'] == true;
      return AlertDialog(
        icon: Icon(
          switch (kind) {
            'Blocked' => Icons.shield_outlined,
            'Clear' => Icons.check_circle_outline,
            'Warning' => Icons.warning_amber_rounded,
            _ => Icons.help_outline,
          },
          color: color(kind),
          size: 40,
        ),
        title: Text(l('apkDialog${kind}Title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l('apkDialog${kind}Body')),
              const SizedBox(height: 12),
              Text(l('apkConfidence${assessment['confidence']}')),
              for (final reason in reasons.take(64))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(l(reason)),
                ),
              const SizedBox(height: 12),
              Text(l('apkDialogBoundary')),
            ],
          ),
        ),
        actions: [
          if (kind != 'Clear')
            FilledButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: Text(l('apkDoNotInstall')),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: Text(l('apkCancel')),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'details'),
            child: Text(l('apkDetails')),
          ),
          if (!blocked)
            TextButton(
              onPressed: () => Navigator.pop(context, 'continue'),
              child: Text(l('apkInstallContinue')),
            ),
        ],
      );
    },
  );
}

extension _ApkDialogUi on _WorkspaceState {
  void finishApkToken(String token) {
    finishedApkTokens.add(token);
    if (finishedApkTokens.length > 64) {
      finishedApkTokens.remove(finishedApkTokens.first);
    }
  }

  Future<void> discardApk(Map<String, dynamic> details) async {
    final token = details['apkToken'];
    if (token is! String) return;
    await platform.discardApk(token);
    if (mounted) updateApkUi(() => finishApkToken(token));
  }

  Future<void> continueApk(Map<String, dynamic> details) async {
    final token = details['apkToken'];
    if (token is! String || finishedApkTokens.contains(token)) return;
    final assessment = details['apkAssessment'] as Map? ?? {};
    if (assessment['risk'] != 'noFindings' || assessment['complete'] != true) {
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l('apkForwardConfirm')),
          content: SingleChildScrollView(child: Text(l('apkForwardHelp'))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l('apkCancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l('apkProceed')),
            ),
          ],
        ),
      );
      if (approved != true || !mounted) {
        await discardApk(details);
        return;
      }
    }
    final response = await platform.forwardApk(token);
    if (response?['blocked'] == true) {
      await showApkGate({...details, 'apkGate': response}, force: true);
    } else if (response?['handoffRequested'] == true && mounted) {
      updateApkUi(() {
        finishApkToken(token);
        notice = 'apkHandoffRequested';
      });
    }
    await refresh();
  }

  Future<void> showApkGate(
    Map<String, dynamic> details, {
    bool force = false,
  }) async {
    final gate = details['apkGate'];
    final assessment = details['apkAssessment'];
    final token = details['apkToken'];
    if (gate is! Map || assessment is! Map) return;
    if (token is! String && gate['blocked'] != true) {
      return; // Historical notification opens details, never an install prompt.
    }
    if (token is String && finishedApkTokens.contains(token)) return;
    if (!ThreatPopupManager.canShow(WidgetsBinding.instance.lifecycleState)) {
      deferredApkDialog = details;
      return;
    }
    final id = '${token ?? assessment}:${gate['outcome']}';
    if (!force && !apkDialogs.add(id)) return;
    if (apkDialogs.length > 64) apkDialogs.remove(apkDialogs.first);
    if (!mounted) return;
    final reasons = {
      ...(assessment['evidence'] as List? ?? []).whereType<String>(),
      ...(details['apkScanReasons'] as List? ?? []).whereType<String>(),
    }.toList();
    final action = await ThreatPopupManager.show(
      context,
      ThreatPopupManager.kind(assessment, gate),
      assessment,
      gate,
      reasons,
    );
    if (!mounted) return;
    if (action == 'continue') {
      await continueApk(details);
    } else if (action != 'details') {
      await discardApk(details);
    }
  }

  List<Widget> apkResult(ScanResult result) {
    final assessment = result.details['apkAssessment'];
    if (assessment is! Map) return [];
    final gate = result.details['apkGate'] as Map? ?? {};
    final token = result.details['apkToken'];
    final kind = ThreatPopupManager.kind(assessment, gate);
    return [
      DecoratedBox(
        decoration: BoxDecoration(
          color: ThreatPopupManager.color(kind).withValues(alpha: .10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            l('apkDialog${kind}Title'),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: ThreatPopupManager.color(kind)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(l('apkDialog${kind}Body')),
      Text(l('apkRisk${assessment['risk']}')),
      Text(l('apkConfidence${assessment['confidence']}')),
      if (gate['outcome'] is String) Text(l('apkOutcome${gate['outcome']}')),
      for (final row
          in (result.details['threatFamilies'] as List? ?? []).whereType<Map>())
        ExpansionTile(
          title: Text(l('family${row['family']}')),
          subtitle: Text(l('familyStatus${row['status']}')),
          children: [
            Text(l(row['explanation'] as String? ?? 'familyLimit')),
            Text(l('familyLimit')),
            if (row['complete'] != true) Text(l('familyIncomplete')),
            for (final code
                in (row['evidence'] as List? ?? []).whereType<String>())
              Text(l('evidence$code')),
          ],
        ),
      if (token is String && !finishedApkTokens.contains(token)) ...[
        FilledButton(
          onPressed: () => act(() => discardApk(result.details)),
          child: Text(l('apkDoNotInstall')),
        ),
        if (gate['blocked'] != true)
          TextButton(
            onPressed: () => act(() => continueApk(result.details)),
            child: Text(l('apkInstallContinue')),
          ),
      ],
      Text(l('apkBoundary')),
    ];
  }
}
