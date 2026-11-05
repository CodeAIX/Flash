import 'package:fl_clash/common/flash_monitor.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray/tray.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocalizations.load(const Locale('en'));
  });

  test('nested automatic group and concrete node select only the monitor', () {
    final picks = <String>[];
    final menu = flashMonitorMenu(
      const [
        Group(
          name: 'Manual',
          type: GroupType.Selector,
          now: 'Auto',
          all: [Proxy(name: 'Auto', type: 'URLTest')],
        ),
        Group(
          name: 'Auto',
          type: GroupType.URLTest,
          now: 'Japan',
          all: [
            Proxy(name: 'Japan', type: 'SS'),
            Proxy(name: 'Manual', type: 'Selector'),
          ],
        ),
      ],
      'Auto',
      picks.add,
    );
    final manual = menu.whereType<TrayMenuSubmenu>().first;
    final auto = manual.items.whereType<TrayMenuSubmenu>().first;
    final group = auto.items.whereType<TrayMenuCheckbox>().first;
    expect(group.checked, isTrue);
    group.onSelected!();
    auto.items.whereType<TrayMenuCheckbox>().last.onSelected!();
    expect(picks, ['Auto', 'Japan']);
    expect(auto.items.whereType<TrayMenuSubmenu>().single.items, hasLength(1));
  });

  test(
    'missing target stays selected and unavailable instead of falling back',
    () {
      final menu = flashMonitorMenu([], 'Removed', (_) {});
      final unavailable = menu.whereType<TrayMenuCheckbox>().last;
      expect(unavailable.checked, isTrue);
      expect(unavailable.enabled, isFalse);
      expect(unavailable.label, contains('Removed'));
    },
  );

  test(
    'selection survives restart and last selection wins persistence',
    () async {
      final first = ProviderContainer();
      await first.read(flashMonitorTargetProvider.notifier).select('Manual');
      await first.read(flashMonitorTargetProvider.notifier).select('Auto');
      expect(first.read(flashMonitorTargetProvider), 'Auto');
      first.dispose();
      final second = ProviderContainer();
      addTearDown(second.dispose);
      second.read(flashMonitorTargetProvider);
      await Future<void>.delayed(Duration.zero);
      expect(second.read(flashMonitorTargetProvider), 'Auto');
    },
  );
}
