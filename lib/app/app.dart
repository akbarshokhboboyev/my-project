import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/engine.dart';
import '../core/intelligence.dart';
import '../core/hash_reputation.dart';
import '../core/platform.dart';
import 'labels.dart';
import 'l10n/strings.dart';

part 'apk_guard_ui.dart';

final platformProvider = Provider((ref) => ShieldPlatform());
final engineProvider = Provider((ref) => ThreatEngine());
final darkProvider = NotifierProvider<ThemeSetting, bool>(ThemeSetting.new);

class ThemeSetting extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

const tabs = ['home', 'scan', 'protection', 'history', 'settings'];
const modes = ['link', 'message', 'file'];
const tabIcons = [
  Icons.home_outlined,
  Icons.search,
  Icons.shield_outlined,
  Icons.history,
  Icons.settings_outlined,
];
String route(String key) => key == 'home' ? '/' : '/$key';

final routerProvider = Provider((ref) {
  final router = GoRouter(
    errorBuilder: (context, state) => const RouteRecoveryPage(),
    routes: [
      ShellRoute(
        builder: (context, state, child) => Workspace(path: state.uri.path),
        routes: [
          for (final key in tabs)
            GoRoute(path: route(key), builder: (_, _) => const SizedBox()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class ShieldApp extends ConsumerWidget {
  const ShieldApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'ShieldGuard',
    debugShowCheckedModeBanner: false,
    locale: const Locale('uz'),
    supportedLocales: Strings.supportedLocales,
    localizationsDelegates: Strings.localizationsDelegates,
    theme: theme(Brightness.light),
    darkTheme: theme(Brightness.dark),
    themeMode: ref.watch(darkProvider) ? ThemeMode.dark : ThemeMode.light,
    routerConfig: ref.watch(routerProvider),
  );

  ThemeData theme(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff1767b8),
      brightness: brightness,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

/// Single owner of the native method-channel handler. During page
/// transitions the next page's initState runs before the previous page's
/// dispose, so a plain `setMethodCallHandler(null)` would drop the new owner.
Object? _channelOwner;

void claimShieldChannel(
  Object owner,
  Future<dynamic> Function(MethodCall call) handler,
) {
  _channelOwner = owner;
  ShieldPlatform.channel.setMethodCallHandler(handler);
}

void releaseShieldChannel(Object owner) {
  if (!identical(_channelOwner, owner)) return;
  _channelOwner = null;
  ShieldPlatform.channel.setMethodCallHandler(null);
}

class RouteRecoveryPage extends StatefulWidget {
  const RouteRecoveryPage({super.key});

  @override
  State<RouteRecoveryPage> createState() => _RouteRecoveryPageState();
}

class _RouteRecoveryPageState extends State<RouteRecoveryPage> {
  @override
  void initState() {
    super.initState();
    // Native results stay queued in `pending`; returning home remounts the
    // Workspace, which drains them. Nothing is marked scanned or safe here.
    claimShieldChannel(this, (call) async {
      if (call.method == 'incoming' && mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    releaseShieldChannel(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l.routeErrorTitle)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 48),
              const SizedBox(height: 16),
              Text(context.l.routeErrorBody),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: Text(context.l.home),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class Workspace extends ConsumerStatefulWidget {
  const Workspace({super.key, required this.path});
  final String path;
  @override
  ConsumerState<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends ConsumerState<Workspace>
    with WidgetsBindingObserver {
  final input = TextEditingController();
  final gateway = TextEditingController();
  final gatewayToken = TextEditingController();
  ThreatIntelligenceEngine? intelligence;
  final hashResults = <String, HashLookupResult>{};
  final hashPending = <String>{};
  final checklist = <String>{};
  Map<String, dynamic> status = {};
  List<Map<String, dynamic>> entries = [];
  List<Map<String, dynamic>> apkEntries = [];
  final apkDialogs = <String>{};
  Map<String, dynamic>? deferredApkDialog;
  List<ScanResult> results = [];
  String mode = 'link';
  String filter = 'all';
  DateTime? date;
  bool riskOnly = false;
  bool busy = false;
  bool draining = false;
  String? notice;
  ShieldPlatform get platform => ref.read(platformProvider);
  ThreatEngine get engine => ref.read(engineProvider);
  String l(String key) => label(context.l, key);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    claimShieldChannel(this, (call) async {
      if (!mounted) return;
      if (call.method == 'incoming') await drain();
      if (call.method == 'statusChanged') await act(refresh);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await act(refresh);
      if (mounted && status['intro'] == false) {
        await info('intro', 'helpBody', action: 'continueButton');
        if (mounted) await act(() => platform.setOption('intro', true));
      }
      if (mounted) await drain();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    releaseShieldChannel(this);
    input.dispose();
    gateway.dispose();
    gatewayToken.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      act(refresh);
      drain();
      final pending = deferredApkDialog;
      deferredApkDialog = null;
      if (pending != null) showApkGate(pending);
    }
  }

  Future<void> refresh() async {
    final next = await platform.status();
    final rows = await platform.history();
    final apkRows = await platform.apkHistory();
    if (mounted && next['dark'] is bool) {
      ref.read(darkProvider.notifier).set(next['dark'] as bool);
    }
    if (mounted) {
      setState(() {
        status = next;
        entries = rows;
        apkEntries = apkRows;
      });
    }
  }

  Future<void> act(Future<void> Function() action) async {
    try {
      await action();
    } on PlatformException catch (error) {
      if (mounted) setState(() => notice = error.code);
    } on MissingPluginException {
      if (mounted) setState(() => notice = 'unavailable');
    }
  }

  Future<void> drain() async {
    if (draining || !mounted) return;
    draining = true;
    try {
      await act(() async {
        while (mounted) {
          final value = await platform.pending();
          if (value == null || !mounted) break;
          if (value['kind'] == 'text') {
            final text = value['text'] as String;
            await present([
              engine.message(text),
              ...engine.links(text).where((r) => r.complete),
            ]);
          } else if (value['kind'] == 'fileProgress') {
            setState(() {
              busy = value['busy'] == true;
              if (busy) {
                mode = 'file';
                results = [];
                notice = null;
              }
            });
            if (busy) context.go('/scan');
          } else if (value['kind'] == 'fileRejected') {
            setState(() => notice = value['code'] as String? ?? 'busy');
          } else {
            if (value['batch'] is List || value['kind'] == 'file') {
              mode = 'file';
            }
            await present(
              platform.decodeBatch(value),
              record: value['kind'] != 'alert',
            );
          }
        }
      });
    } finally {
      draining = false;
    }
  }

  void openScan(String next) {
    setState(() {
      mode = next;
      results = [];
      notice = null;
      input.clear();
    });
    context.go('/scan');
  }

  Future<void> runScan() async {
    if (busy) return;
    setState(() {
      busy = true;
      notice = null;
    });
    try {
      await act(() async {
        if (mode == 'file') {
          final value = await platform.pick();
          if (value != null) {
            await present(platform.decodeBatch(value));
          } else if (mounted) {
            setState(() => notice = 'cancelled');
          }
        } else {
          final text = input.text.trim();
          if (text.isEmpty) {
            setState(() => notice = 'empty');
            return;
          }
          input.clear();
          final found = mode == 'message'
              ? [engine.message(text)]
              : engine.links(text);
          if (mode == 'link' && status['onlineConsent'] == true) {
            intelligence ??= ThreatIntelligenceEngine(
              PlatformThreatCache(),
              RemoteReputationProvider(
                Uri.tryParse(gateway.text.trim()) ?? Uri(),
                gatewayToken.text.trim(),
              ),
            );
            final urls = engine.extract(text);
            if (urls.isEmpty) urls.add(text);
            final seen = <String>{};
            final normalized = [
              for (final raw in urls)
                if (seen.add(engine.normalize(raw)?.toString() ?? raw))
                  engine.normalize(raw),
            ];
            for (var i = 0; i < found.length && i < normalized.length; i++) {
              if (found[i].complete &&
                  normalized[i] != null &&
                  status['onlineConsent'] == true) {
                found[i] = aggregateReputation(
                  found[i],
                  await intelligence!.check(normalized[i]!, consent: true),
                );
              }
            }
          }
          await present(found.isEmpty ? [engine.link('')] : found);
        }
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> present(List<ScanResult> next, {bool record = true}) async {
    if (!mounted) return;
    setState(() {
      results = next;
      notice = null;
    });
    context.go('/scan');
    for (final result in next) {
      if (result.details['apkGate'] is Map) {
        await showApkGate(result.details);
      }
    }
    if (record && status['history'] == true) {
      for (final result in next) {
        await platform.record(result);
      }
      await refresh();
    }
  }

  Future<void> option(String key, bool value, {bool requestAccess = false}) =>
      act(() async {
        await platform.setOption(key, value);
        await refresh();
        if (requestAccess && status['access'] != true) {
          await platform.openAccess();
        }
      });

  String protectionState() {
    if (status['enabled'] != true) return 'inactive';
    if (status['access'] != true) return 'noAccess';
    if (status['connected'] != true) return 'paused';
    if (status['alerts'] != true) return 'noAlerts';
    return 'active';
  }

  @override
  Widget build(BuildContext context) {
    final index = tabs.indexWhere((key) => route(key) == widget.path);
    final name = tabs[index < 0 ? 0 : index];
    return Scaffold(
      appBar: AppBar(
        title: Text(name == 'home' ? 'ShieldGuard' : l(name)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l('help'),
            onPressed: () => info('help', 'helpBody'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              children: [
                if (notice != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(l(notice!)),
                    ),
                  ),
                ...switch (name) {
                  'home' => home(),
                  'scan' => scan(),
                  'protection' => protection(),
                  'history' => history(),
                  _ => settings(),
                },
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) {
          setState(() => notice = null);
          context.go(route(tabs[i]));
        },
        destinations: [
          for (final (i, key) in tabs.indexed)
            NavigationDestination(icon: Icon(tabIcons[i]), label: l(key)),
        ],
      ),
    );
  }

  Widget card(List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
  Widget heading(String key) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(l(key), style: Theme.of(context).textTheme.titleLarge),
  );
  Widget button(String key, VoidCallback? action) =>
      FilledButton(onPressed: action, child: Text(l(key)));
  String stamp(int time) {
    final d = DateTime.fromMillisecondsSinceEpoch(time);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${[two(d.day), two(d.month), d.year].join('.')}  ${[two(d.hour), two(d.minute)].join(':')}';
  }

  List<Widget> home() => [
    Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xff0b2341), Color(0xff124c66)],
        ),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white70, fontSize: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: Color(0xff81efcf),
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(l('tagline')),
            Text(
              l(protectionState()),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              [
                l('last'),
                entries.isEmpty ? '—' : stamp(entries.first['time'] as int),
              ].join(' · '),
            ),
            Text(
              [
                l('events'),
                entries.where((e) => (e['score'] as int) >= 50).length,
              ].join(' · '),
            ),
          ],
        ),
      ),
    ),
    heading('manual'),
    for (final (key, icon) in [
      ('link', Icons.link),
      ('file', Icons.description_outlined),
      ('message', Icons.chat_bubble_outline),
      ('automatic', Icons.security),
    ])
      Card(
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(l(key)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              key == 'automatic' ? context.go('/protection') : openScan(key),
        ),
      ),
  ];

  List<Widget> scan() {
    if (results.isNotEmpty) {
      return [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: Text(l('back')),
            onPressed: () => setState(() => results = []),
          ),
        ),
        heading('result'),
        for (final result in results) resultCard(result),
      ];
    }
    return [
      Wrap(
        spacing: 8,
        children: [
          for (final key in modes)
            ChoiceChip(
              label: Text(l(key)),
              selected: mode == key,
              onSelected: busy ? null : (_) => openScan(key),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (mode != 'file')
        TextField(
          controller: input,
          minLines: 4,
          maxLines: 8,
          maxLength: 32000,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: l(mode == 'link' ? 'pasteLink' : 'pasteMessage'),
            suffixIcon: IconButton(
              tooltip: l('clearInput'),
              onPressed: input.clear,
              icon: const Icon(Icons.clear),
            ),
          ),
        ),
      const SizedBox(height: 10),
      button(
        busy
            ? 'working'
            : mode == 'file'
            ? 'choose'
            : 'scan',
        busy ? null : runScan,
      ),
      if (busy) const LinearProgressIndicator(),
      if (busy && mode == 'file')
        TextButton(
          onPressed: () => act(platform.cancelFileScan),
          child: Text(l('cancelScan')),
        ),
    ];
  }

  Widget resultCard(ScanResult result) => card([
    ...apkResult(result),
    heading(
      result.complete || result.score > 0 ? result.level.name : 'partial',
    ),
    Text([l('score'), '${result.score}/100'].join(' · ')),
    Text([l('confidence'), l(result.confidence.name)].join(' · ')),
    Text([l('source'), l(result.source)].join(' · ')),
    Text(stamp(result.time.millisecondsSinceEpoch)),
    if (result.subject != null)
      SelectableText([l('subject'), result.subject].join(' · ')),
    for (final signer in result.signers)
      SelectableText([context.l.signer, signer].join('\n')),
    if (result.hash != null) SelectableText('SHA-256\n${result.hash!}'),
    if (result.findings.isNotEmpty) heading('why'),
    for (final f in result.findings) Text('• ${l(f.code)}'),
    if (result.complete && result.findings.isEmpty) Text(l('noFindings')),
    heading('limits'),
    if (result.hash != null) ...[
      TextButton(
        onPressed: hashPending.contains(result.hash)
            ? null
            : () => lookupHash(result.hash!),
        child: Text(l('hashLookup')),
      ),
      if (hashResults[result.hash] case final HashLookupResult remote) ...[
        Text(l('hashStatus${remote.status.name}')),
        if (remote.status == HashLookupStatus.reported)
          Text(context.l.hashCounts(remote.malicious, remote.suspicious)),
      ],
    ],
    TextButton(
      onPressed: () => Clipboard.setData(
        ClipboardData(
          text: jsonEncode({
            l('result'): l(result.verdict),
            l('date'): result.time.toUtc().toIso8601String(),
            l('done'): result.complete,
            l('score'): result.score,
            l('confidence'): l(result.confidence.name),
            l('why'): result.findings.map((f) => l(f.code)).toList(),
            'SHA-256': result.hash,
            l('source'): l(result.source),
          }),
        ),
      ),
      child: Text(l('exportReport')),
    ),
    heading(result.verdict),
    if (result.signatureUnchecked) Text(l('signatureUnchecked')),
    for (final entry in result.details.entries.where(
      (entry) => ![
        'apkToken',
        'apkHistoryId',
        'apkAssessment',
        'apkGate',
        'apkActualFormat',
      ].contains(entry.key),
    ))
      Text(
        [
          l(entry.key),
          entry.key == 'signatureStatus' || entry.key == 'installedCoverage'
              ? l(entry.value.toString())
              : entry.key == 'installedUpdated' && entry.value is int
              ? stamp(entry.value as int)
              : entry.value.toString(),
        ].join(' · '),
      ),
    Text(
      result.reputation == 'disabled'
          ? l('online')
          : l(
              'rep${result.reputation[0].toUpperCase()}${result.reputation.substring(1)}',
            ),
    ),
    Text(
      l(switch (result.type) {
        ThreatType.link => 'linkLimit',
        ThreatType.message => 'messageLimit',
        ThreatType.file => 'fileLimit',
        ThreatType.notification => 'alertLimit',
      }),
    ),
    if (!result.complete && result.score > 0) Text(l('partial')),
    if (result.type == ThreatType.file) Text(l('sharedAdvice')),
    heading('advice'),
    Text(
      l(switch (result.type) {
        ThreatType.link => 'linkAdvice',
        ThreatType.file => 'fileAdvice',
        _ => 'messageAdvice',
      }),
    ),
  ]);

  List<Widget> protection() => [
    card([
      heading(protectionState()),
      Text(l('disclosure')),
      const SizedBox(height: 12),
      if (status['enabled'] != true)
        button('enable', () => option('enabled', true, requestAccess: true))
      else ...[
        if (status['access'] != true)
          button('grant', () => act(platform.openAccess)),
        if (status['alerts'] != true)
          button('grantAlerts', () => act(platform.allowAlerts)),
        OutlinedButton(
          onPressed: () => option('enabled', false),
          child: Text(l('disable')),
        ),
      ],
      Text(l('hidden')),
    ]),
    card([
      heading('installedTitle'),
      Text(l('installedDisclosure')),
      SwitchListTile(
        title: Text(l('installedTitle')),
        value: status['appMonitoring'] == true,
        onChanged: (value) => option('appMonitoring', value),
      ),
      if (status['appMonitoring'] == true) ...[
        Text(
          l(
            status['appScheduled'] == true
                ? 'installedScheduled'
                : 'installedUnscheduled',
          ),
        ),
        Text(l('installedState${status['appLastState'] as String? ?? 'none'}')),
        if (status['appAlerts'] != true)
          button('grantAlerts', () => act(platform.allowAlerts)),
        button(
          'installedScan',
          () => act(() async {
            await platform.scanInstalled();
            await refresh();
          }),
        ),
        if (status['appHasReport'] == true)
          button(
            'installedReport',
            () => act(() async {
              final report = await platform.installedReport();
              if (report != null) {
                await present([platform.decode(report)], record: false);
              }
            }),
          ),
      ],
    ]),

    ...folderProtection(),
    ...apkProtection(),
    heading('guide'),
    button(
      'testAlert',
      () => act(() => ShieldPlatform.channel.invokeMethod<void>('testAlert')),
    ),
    Text(l('selfCheck')),
    for (final key in ['twoFactor', 'sessions', 'codes', 'report', 'incident'])
      CheckboxListTile(
        value: checklist.contains(key),
        title: Text(l(key)),
        onChanged: (value) => setState(
          () => value == true ? checklist.add(key) : checklist.remove(key),
        ),
      ),
  ];

  List<Widget> folderProtection() {
    final data = Map<String, dynamic>.from(
      status['folderSecurity'] as Map? ?? {},
    );
    final roots = (data['roots'] as List? ?? []).whereType<Map>().toList();
    final state = data['state'] as String? ?? 'idle';
    return [
      card([
        heading('folderTitle'),
        Text(l('folderDisclosure')),
        Text(l('folderOffCleanup')),
        button(
          'folderAdd',
          () => act(() async {
            await platform.pickFolder();
            await refresh();
          }),
        ),
        SwitchListTile(
          title: Text(l('folderPeriodic')),
          value: data['enabled'] == true,
          onChanged: roots.isEmpty && data['enabled'] != true
              ? null
              : (value) => act(() async {
                  await platform.setFolderMonitoring(value);
                  await refresh();
                }),
        ),
        Text(
          l(
            data['scheduled'] == true ? 'folderScheduled' : 'folderUnscheduled',
          ),
        ),
        Text(l('folderState$state')),
        if (data['cleanupPending'] == true) Text(l('folderCleanupPending')),
        for (final root in roots)
          ListTile(
            title: Text(
              (root['label'] as String?)?.isNotEmpty == true
                  ? root['label'] as String
                  : l('folderUnnamed'),
            ),
            subtitle: Text(
              l(root['granted'] == true ? 'folderGranted' : 'folderPermission'),
            ),
            trailing: IconButton(
              tooltip: l('folderRemove'),
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => act(() async {
                await platform.removeFolder(root['id'] as String);
                await refresh();
              }),
            ),
          ),
        if (roots.isNotEmpty) ...[
          button(
            'folderNow',
            () => act(() async {
              await platform.scanFolders();
              await refresh();
            }),
          ),
          if (['running', 'queued', 'deferred'].contains(state))
            button(
              'folderCancel',
              () => act(() async {
                await platform.cancelFolders();
                await refresh();
              }),
            ),
        ],
        Text(
          [
            l('folderLast'),
            (data['lastScan'] as int? ?? 0) > 0
                ? stamp(data['lastScan'] as int)
                : l('folderNever'),
          ].join(' · '),
        ),
        for (final field in ['visited', 'scanned', 'cached', 'unverified'])
          Text([l('folderCount$field'), data[field] ?? 0].join(' · ')),
        Text(
          l(
            data['partial'] == false
                ? 'folderCoverageBounded'
                : 'folderCoveragePartial',
          ),
        ),
        Text(
          [
            l('folderIndicators'),
            (data['indicators'] as List? ?? []).length,
          ].join(' · '),
        ),
        for (final code
            in (data['indicators'] as List? ?? []).whereType<String>())
          Text(l(code)),
      ]),
    ];
  }

  List<Widget> history() {
    final rows = entries
        .where(
          (row) =>
              (!riskOnly || (row['score'] as int) >= 50) &&
              (filter == 'all' || filter == row['type']) &&
              (date == null ||
                  DateUtils.isSameDay(
                    date,
                    DateTime.fromMillisecondsSinceEpoch(row['time'] as int),
                  )),
        )
        .toList();
    return [
      SwitchListTile(
        title: Text(l('onlyRisk')),
        value: riskOnly,
        onChanged: (value) => setState(() => riskOnly = value),
      ),
      Wrap(
        spacing: 12,
        children: [
          DropdownButton<String>(
            value: filter,
            onChanged: (value) => setState(() => filter = value ?? 'all'),
            items: [
              for (final key in ['all', ...modes, 'notification'])
                DropdownMenuItem(value: key, child: Text(l(key))),
            ],
          ),
          OutlinedButton(
            onPressed: () async {
              if (date != null) {
                setState(() => date = null);
                return;
              }
              final day = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (mounted && day != null) setState(() => date = day);
            },
            child: Text(
              date == null
                  ? l('date')
                  : '${stamp(date!.millisecondsSinceEpoch).split('  ').first} ×',
            ),
          ),
        ],
      ),
      if (rows.isEmpty)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(l('historyEmpty')),
        ),
      for (final row in rows)
        Card(
          child: ListTile(
            title: Text(l(row['type'] as String)),
            subtitle: Text(
              [
                stamp(row['time'] as int),
                l(ScanResult.levelForScore(row['score'] as int).name),
                [row['count'], l('why')].join(' · '),
                l(row['complete'] == true ? 'done' : 'partial'),
              ].join('\n'),
            ),
            trailing: Text('${row['score']}/100'),
          ),
        ),
      if (entries.isNotEmpty)
        OutlinedButton(onPressed: clear, child: Text(l('clearHistory'))),
    ];
  }

  Future<void> clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l('clearHistory')),
        content: Text(l('confirmClear')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l('later')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l('clearHistory')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await act(() async {
        await platform.clear();
        await refresh();
      });
    }
  }

  List<Widget> settings() => [
    heading('onlineTitle'),
    SwitchListTile(
      title: Text(l('onlineTitle')),
      subtitle: Text(l('onlineConsent')),
      value: status['onlineConsent'] == true,
      onChanged: (value) => option('onlineConsent', value),
    ),
    TextField(
      controller: gateway,
      decoration: InputDecoration(labelText: l('gateway')),
      onChanged: (_) => intelligence = null,
    ),
    const SizedBox(height: 12),
    TextField(
      controller: gatewayToken,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(labelText: l('gatewayToken')),
      onChanged: (_) => intelligence = null,
    ),
    Text(l('gatewayHint')),
    SwitchListTile(
      title: Text(l('dark')),
      value: ref.watch(darkProvider),
      onChanged: (value) {
        ref.read(darkProvider.notifier).set(value);
        option('dark', value);
      },
    ),
    SwitchListTile(
      title: Text(l('historyOpt')),
      subtitle: Text(l('historyDesc')),
      value: status['history'] == true,
      onChanged: (value) => option('history', value),
    ),
    for (final key in ['privacy', 'about', 'help'])
      ListTile(
        title: Text(l(key)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => info(key, '${key}Body'),
      ),
  ];

  Future<void> lookupHash(String hash) async {
    final allowed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l('hashLookup')),
        content: Text(l('hashDisclosure')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l('later')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l('hashAllow')),
          ),
        ],
      ),
    );
    if (allowed != true || !mounted) return;
    setState(() => hashPending.add(hash));
    final configured = Uri.tryParse(gateway.text.trim()) ?? Uri();
    final result = await FileHashReputationProvider(
      configured.replace(path: '/v1/hash', query: '', fragment: ''),
      gatewayToken.text.trim(),
    ).check(hash, consent: true);
    if (mounted) {
      setState(() {
        hashResults[hash] = result;
        hashPending.remove(hash);
      });
    }
  }

  Future<void> info(String title, String content, {String action = 'close'}) =>
      showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l(title)),
          content: SingleChildScrollView(child: Text(l(content))),
          actions: [button(action, () => Navigator.pop(dialog))],
        ),
      );
}
