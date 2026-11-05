import 'app_localizations.dart';
import 'dart:async';

import 'package:fl_clash/common/service_probe.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray/tray.dart';

final flashMonitorTargetProvider = NotifierProvider<FlashMonitorTarget, String>(
  FlashMonitorTarget.new,
);

class FlashMonitorTarget extends Notifier<String> {
  static const preferenceKey = 'flash.monitorTarget';
  int _revision = 0;
  Future<void> _writes = Future.value();

  @override
  String build() {
    unawaited(_restore());
    return routedOutbound;
  }

  Future<void> _restore() async {
    try {
      final store = await SharedPreferences.getInstance();
      if (ref.mounted && _revision == 0) {
        state = store.getString(preferenceKey) ?? routedOutbound;
      }
    } catch (_) {
      // A missing preference store must not prevent tray startup.
    }
  }

  Future<void> select(String target) {
    _revision++;
    state = target;
    return _writes = _writes
        .then((_) async {
          final store = await SharedPreferences.getInstance();
          await store.setString(preferenceKey, target);
        })
        .catchError((Object error) {});
  }
}

List<TrayMenuItem> flashMonitorMenu(
  List<Group> groups,
  String selected,
  void Function(String) select,
) {
  final localizations = currentAppLocalizations;
  final byName = {for (final group in groups) group.name: group};
  final expanded = <String>{};
  final names = <String>{
    for (final group in groups) ...[
      group.name,
      for (final proxy in group.all) proxy.name,
    ],
  };
  TrayMenuCheckbox choice(String name, String label) => TrayMenuCheckbox(
    label: label,
    checked: selected == name,
    onSelected: () => select(name),
  );
  TrayMenuItem target(String name) {
    final group = byName[name];
    if (group == null) return choice(name, name);
    return TrayMenuSubmenu(
      label: name,
      items: [
        choice(name, '${localizations.flashMonitorGroup}: ${group.now ?? "—"}'),
        if (expanded.add(name)) ...[
          const TrayMenuSeparator(),
          for (final proxy in group.all) target(proxy.name),
        ],
      ],
    );
  }

  return [
    choice(routedOutbound, localizations.flashMonitorRules),
    if (selected.isNotEmpty && !names.contains(selected))
      TrayMenuCheckbox(
        label: '$selected (${localizations.flashMonitorUnavailable})',
        checked: true,
        enabled: false,
      ),
    const TrayMenuSeparator(),
    for (final group in [
      ...groups.where(
        (group) => group.type == GroupType.Selector && group.name != 'GLOBAL',
      ),
      ...groups.where(
        (group) => group.type != GroupType.Selector || group.name == 'GLOBAL',
      ),
    ])
      if (!expanded.contains(group.name)) target(group.name),
  ];
}
