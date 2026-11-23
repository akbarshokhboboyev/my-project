part of 'app.dart';

extension _ApkProtectionUi on _WorkspaceState {
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
