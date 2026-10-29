import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/app_localizations.dart';
import 'package:fl_clash/common/app_ports.dart';
import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/common/l10n_labels.dart';
import 'package:fl_clash/common/tray.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/providers/outbound_ip.dart';
import 'package:fl_clash/providers/ip_quality.dart';
import 'package:fl_clash/providers/routed_probe.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tray/tray.dart';

import '../helpers/app_paths.dart';

const _channel = MethodChannel('tray');

const _proxyGroup = Group(
  name: 'Proxy',
  type: GroupType.Selector,
  all: [
    Proxy(name: 'A', type: 'Direct'),
    Proxy(name: 'B', type: 'Direct'),
    Proxy(name: 'C', type: 'Direct'),
  ],
);

HotKeyAction _bind(HotAction action, PhysicalKeyboardKey key) {
  return HotKeyAction(
    action: action,
    key: key.usbHidUsage,
    modifiers: const {KeyboardModifier.control, KeyboardModifier.shift},
  );
}

TrayState _trayState({
  bool isStart = false,
  bool tunEnable = false,
  bool systemProxy = false,
  bool autoLaunch = false,
  bool showTrayTitle = false,
  bool monochromeTrayIcon = true,
  bool safeMode = false,
  Mode mode = Mode.rule,
  List<Group> groups = const [],
  Map<HotAction, HotKeyAction> hotKeys = const {},
}) {
  return TrayState(
    mode: mode,
    port: 7890,
    autoLaunch: autoLaunch,
    systemProxy: systemProxy,
    tunEnable: tunEnable,
    isStart: isStart,
    groups: groups,
    selectedMap: const {},
    showTrayTitle: showTrayTitle,
    monochromeTrayIcon: monochromeTrayIcon,
    safeMode: safeMode,
    hotKeys: hotKeys,
  );
}

List<Map<Object?, Object?>> _items(MethodCall? call) {
  final menu = (call?.arguments as Map?)?['menu'] as List?;
  return menu?.cast<Map<Object?, Object?>>() ?? const [];
}

Map<Object?, Object?> _item(MethodCall? call, String label) {
  return _items(call).firstWhere((item) => item['label'] == label);
}

List<String> _labels(MethodCall? call) {
  return _items(call).map((item) => item['label']).whereType<String>().toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  late ProviderContainer container;
  late AppTray tray;

  late Directory root;

  setUpAll(() async {
    root = Directory.systemTemp.createTempSync('tray_menu_test');
    await useAppPaths(root);
    await AppLocalizations.load(const Locale('en'));
  });

  tearDownAll(() {
    // The shared system temp dir is not exclusively ours; another suite running
    // alongside this one can take the tree out from under the teardown, either
    // before the check or between the check and the delete.
    try {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    } on FileSystemException {
      return;
    }
  });

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    calls = [];
    tray = AppTray.forPlatform(isMacOS: true, isWindows: false);
    container = ProviderContainer();
    Tray.instance.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    container.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  MethodCall? showCall() {
    for (final call in calls.reversed) {
      if (call.method == 'show') {
        return call;
      }
    }
    return null;
  }

  Future<void> update(TrayState trayState, {AppTray? on}) {
    return (on ?? tray).update(
      trayState: trayState,
      traffic: const Traffic(),
      read: container.read,
    );
  }

  test(
    'SystemAction.updateTray builds the menu without reading itself',
    () async {
      globalState.container = container;
      trayPort = tray;
      addTearDown(() => trayPort = null);

      await container.read(systemActionProvider.notifier).updateTray();

      expect(showCall(), isNotNull);
      expect(_labels(showCall()), contains(currentAppLocalizations.exit));
    },
  );

  test('builds the stopped menu without the running-only toggles', () async {
    await update(_trayState());

    final labels = _labels(showCall());
    final l10n = currentAppLocalizations;
    expect(labels, contains(l10n.show));
    expect(labels, contains(l10n.start));
    expect(labels, contains(l10n.autoLaunch));
    expect(labels, contains(l10n.copyEnvVar));
    expect(labels, contains(l10n.exit));
    expect(labels, isNot(contains(l10n.tun)));
    expect(labels, isNot(contains(l10n.systemProxy)));
  });

  test('adds TUN and system proxy toggles once the core is running', () async {
    await update(_trayState(isStart: true));

    final labels = _labels(showCall());
    final l10n = currentAppLocalizations;
    expect(labels, contains(l10n.stop), reason: 'start flips to stop');
    expect(labels, contains(l10n.tun));
    expect(labels, contains(l10n.systemProxy));
  });

  group('safe mode', () {
    test('keeps the full menu', () async {
      await update(_trayState(isStart: true, safeMode: true));

      final labels = _labels(showCall());
      final l10n = currentAppLocalizations;
      expect(labels, contains(l10n.stop));
      expect(labels, contains(l10n.tun));
      expect(labels, contains(l10n.systemProxy));
      expect(labels, contains(l10n.copyEnvVar));
    });

    test('names the mode in the tooltip and ships the safe icon', () async {
      await update(_trayState(isStart: true, safeMode: true));

      final arguments = showCall()!.arguments as Map;
      final l10n = currentAppLocalizations;
      expect(arguments['toolTip'], '$appName (${l10n.safeMode})');
      final reps = ((arguments['icon'] as Map)['reps'] as List).cast<Map>();
      final base = reps.firstWhere((rep) => rep['scale'] == 1.0);
      expect(
        base['bytes'],
        base64Encode(
          File('assets/images/tray/macos/status_4.png').readAsBytesSync(),
        ),
      );
    });
  });

  test('offers every outbound mode as a menu entry', () async {
    await update(_trayState(mode: Mode.global));

    final checkedModes = _items(showCall())
        .where((item) => item['checked'] == true)
        .map((item) => item['label'])
        .toList();
    expect(checkedModes, contains(Intl.message(Mode.global.name)));
  });

  test('sends icon, tooltip and menu in a single show call', () async {
    await update(_trayState(isStart: true, tunEnable: true));

    final showCalls = calls.where((call) => call.method == 'show').toList();
    expect(showCalls, hasLength(1));

    final arguments = showCalls.single.arguments as Map;
    expect(
      arguments['toolTip'],
      contains('Core rule probe; OS entry unverified'),
    );
    expect(arguments['menu'], isNotEmpty);
    final icon = arguments['icon'] as Map;
    expect(icon['country'], '--');
    expect(icon['status'], 'tun');
    expect(icon['isTemplate'], isFalse);
  });

  test(
    'status distinguishes stopped, failed, no entry and rule success',
    () async {
      for (final (running, enabled, phase, expected) in [
        (false, true, ProbePhase.fresh, 'stopped'),
        (true, true, ProbePhase.failed, 'failed'),
        (true, false, ProbePhase.fresh, 'entry'),
        (true, true, ProbePhase.fresh, 'route'),
      ]) {
        container.dispose();
        container = ProviderContainer(
          overrides: [
            ipQualityProvider(
              '2.2.2.2',
            ).overrideWithValue(const AsyncLoading()),
            outboundIpProbeProvider.overrideWithBuild(
              (_, _) => RoutedProbeState({
                '': ProbeEntry(
                  phase: phase,
                  value: const IpInfo(ip: '2.2.2.2', countryCode: 'JP'),
                ),
              }),
            ),
          ],
        );
        await update(_trayState(isStart: running, systemProxy: enabled));
        final icon = (showCall()!.arguments as Map)['icon'] as Map;
        expect(icon['status'], expected);
        expect(
          icon['country'],
          running && phase == ProbePhase.fresh ? 'JP' : '--',
        );
      }
    },
  );

  test('quality changes text independently of the entry background', () async {
    const good = IpQuality(
      ip: '2.2.2.2',
      source: IpQualitySource.identMe,
      type: IpType.residential,
    );
    for (final (quality, phase, enabled, expected)
        in <(AsyncValue<IpQuality>, ProbePhase, bool, String)>[
          (const AsyncData(good), ProbePhase.fresh, true, 'route'),
          (
            AsyncData(good.copyWith(type: IpType.hosting)),
            ProbePhase.fresh,
            true,
            'route',
          ),
          (
            AsyncData(good.copyWith(isAbuser: true)),
            ProbePhase.fresh,
            true,
            'route',
          ),
          (
            AsyncData(good.copyWith(ip: '3.3.3.3')),
            ProbePhase.fresh,
            true,
            'route',
          ),
          (const AsyncLoading(), ProbePhase.fresh, true, 'route'),
          (
            AsyncError(StateError('failed'), StackTrace.empty),
            ProbePhase.fresh,
            true,
            'route',
          ),
          (const AsyncData(good), ProbePhase.probing, true, 'route'),
          (const AsyncData(good), ProbePhase.failed, true, 'failed'),
          (const AsyncData(good), ProbePhase.fresh, false, 'entry'),
        ]) {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          ipQualityProvider('2.2.2.2').overrideWithValue(quality),
          outboundIpProbeProvider.overrideWithBuild(
            (_, _) => RoutedProbeState({
              '': ProbeEntry(
                phase: phase,
                value: const IpInfo(ip: '2.2.2.2', countryCode: 'JP'),
              ),
            }),
          ),
        ],
      );
      await update(_trayState(isStart: true, systemProxy: enabled));
      expect(
        ((showCall()!.arguments as Map)['icon'] as Map)['status'],
        expected,
      );
      final value = quality.isLoading || quality.hasError
          ? null
          : quality.value;
      expect(
        ((showCall()!.arguments as Map)['icon'] as Map)['isHighQuality'],
        phase == ProbePhase.fresh &&
            value?.ip == '2.2.2.2' &&
            value?.level == IpQualityLevel.good,
      );
    }
  });

  test('TUN takes priority over system proxy for the background', () async {
    for (final (tun, proxy, expected) in [
      (true, true, 'tun'),
      (true, false, 'tun'),
      (false, true, 'route'),
      (false, false, 'entry'),
    ]) {
      await update(
        _trayState(isStart: true, tunEnable: tun, systemProxy: proxy),
      );
      final icon = (showCall()!.arguments as Map)['icon'] as Map;
      expect(icon['status'], expected);
      expect(icon['country'], '--');
      expect(icon['isHighQuality'], isFalse);
    }
  });

  test(
    'Flash badge keeps its entry colors with either monochrome preference',
    () async {
      for (final monochrome in [true, false]) {
        await update(
          _trayState(
            isStart: true,
            tunEnable: true,
            monochromeTrayIcon: monochrome,
          ),
        );
        final icon = (showCall()!.arguments as Map)['icon'] as Map;
        expect(icon['status'], 'tun');
        expect(icon['country'], '--');
        expect(
          _labels(showCall()),
          isNot(contains(currentAppLocalizations.monochromeIcon)),
        );
      }
    },
  );

  test('skips the platform call when the tray state is unchanged', () async {
    await update(_trayState(isStart: true));
    await update(_trayState(isStart: true));

    expect(calls.where((call) => call.method == 'show'), hasLength(1));
  });

  test('menu item ids are stable across identical rebuilds', () async {
    await update(_trayState());
    final first = _items(showCall()).map((item) => item['id']).toList();

    Tray.instance.resetForTesting();
    calls.clear();

    await update(_trayState());
    final second = _items(showCall()).map((item) => item['id']).toList();

    expect(second, first);
    expect(first.first, 1024);
  });

  test('group submenus carry their proxies as nested items', () async {
    await update(
      _trayState(
        groups: [
          const Group(
            name: 'Proxy',
            type: GroupType.Selector,
            all: [Proxy(name: 'A', type: 'Direct')],
          ),
        ],
      ),
    );

    final submenu = _items(
      showCall(),
    ).firstWhere((item) => item['type'] == 'submenu');
    expect(submenu['label'], 'Proxy');
    final children = (submenu['items'] as List).cast<Map<Object?, Object?>>();
    expect(children.map((item) => item['label']), contains('A'));
  });

  test('shows each bound hotkey dimmed beside its entry', () async {
    await update(
      _trayState(
        isStart: true,
        hotKeys: {
          HotAction.view: _bind(HotAction.view, PhysicalKeyboardKey.keyV),
          HotAction.globalMode: _bind(
            HotAction.globalMode,
            PhysicalKeyboardKey.keyG,
          ),
          HotAction.tun: _bind(HotAction.tun, PhysicalKeyboardKey.keyT),
        },
      ),
    );

    final l10n = currentAppLocalizations;
    final call = showCall();
    expect(_item(call, l10n.show)['detail'], '⌃⇧V');
    expect(_item(call, Mode.global.label)['detail'], '⌃⇧G');
    expect(_item(call, l10n.tun)['detail'], '⌃⇧T');
    expect(_item(call, l10n.exit), isNot(contains('detail')));
    expect(_item(call, Mode.rule.label), isNot(contains('detail')));
  });

  test(
    'group submenus show the delay of the selection and of each proxy',
    () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          selectedProxyNameProvider('Proxy').overrideWithValue('A'),
          trayDelaysProvider.overrideWithValue({
            'Proxy': {'A': 120, 'B': -1, 'C': -2},
          }),
        ],
      );
      const group = Group(
        name: 'Proxy',
        type: GroupType.Selector,
        all: [
          Proxy(name: 'A', type: 'Direct'),
          Proxy(name: 'B', type: 'Direct'),
          Proxy(name: 'C', type: 'Direct'),
          Proxy(name: 'D', type: 'Direct'),
        ],
      );
      await update(_trayState(groups: [group]));

      final submenu = _item(showCall(), 'Proxy');
      expect(submenu['detail'], '120');
      final children = (submenu['items'] as List).cast<Map<Object?, Object?>>();
      expect(children.map((item) => item['detail']), [
        '120',
        currentAppLocalizations.timeout,
        currentAppLocalizations.delayFailed,
        null,
      ]);
    },
  );

  test('a delay test entry follows the groups', () async {
    await update(
      _trayState(
        groups: [_proxyGroup],
        hotKeys: {
          HotAction.delayTest: _bind(
            HotAction.delayTest,
            PhysicalKeyboardKey.keyD,
          ),
        },
      ),
    );

    final items = _items(showCall());
    final index = items.indexWhere((item) => item['type'] == 'submenu');
    expect(items[index + 1]['label'], HotAction.delayTest.label);
    expect(items[index + 1]['detail'], '⌃⇧D');
  });

  group('a platform that is not macOS', () {
    late AppTray windows;

    setUp(() {
      windows = AppTray.forPlatform(isMacOS: false, isWindows: true);
    });

    test('gets a plain icon, no group submenus and no speed toggle', () async {
      await update(
        _trayState(
          isStart: true,
          groups: [
            const Group(
              name: 'Proxy',
              type: GroupType.Selector,
              all: [Proxy(name: 'A', type: 'Direct')],
            ),
          ],
        ),
        on: windows,
      );

      final arguments = showCall()!.arguments as Map;
      expect((arguments['icon'] as Map)['isTemplate'], isFalse);
      expect(
        _items(showCall()).where((item) => item['type'] == 'submenu'),
        isEmpty,
      );
      expect(
        _labels(showCall()),
        isNot(contains(currentAppLocalizations.speedStatistics)),
      );
      expect(
        _labels(showCall()),
        isNot(contains(currentAppLocalizations.monochromeIcon)),
      );
      expect(_labels(showCall()), isNot(contains(HotAction.delayTest.label)));
    });

    test('joins modifiers with + in the hotkey hints', () async {
      await update(
        _trayState(
          hotKeys: {
            HotAction.view: _bind(HotAction.view, PhysicalKeyboardKey.keyV),
          },
        ),
        on: windows,
      );

      expect(
        _item(showCall(), currentAppLocalizations.show)['detail'],
        'Ctrl+Shift+V',
      );
    });

    test('never pushes a tray title', () async {
      await windows.updateTitle(showTrayTitle: true, traffic: const Traffic());

      expect(calls.where((call) => call.method == 'setTitle'), isEmpty);
    });
  });
}
