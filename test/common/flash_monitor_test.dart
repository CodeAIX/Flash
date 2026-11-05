import 'dart:async';
import 'package:fl_clash/providers/ip_quality.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/common/flash_monitor.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocalizations.load(const Locale('en'));
  });

  test(
    'quality refresh survives the tray temporarily releasing its listener',
    () async {
      var calls = 0;
      final answer = Completer<IpQuality>();
      const quality = IpQuality(
        ip: '2.2.2.2',
        source: IpQualitySource.identMe,
        type: IpType.residential,
      );
      final container = ProviderContainer(
        overrides: [
          ipQualityProvider('2.2.2.2').overrideWith((ref) async {
            calls++;
            return calls == 1 ? quality : answer.future;
          }),
        ],
      );
      addTearDown(container.dispose);
      final ui = container.listen(ipQualityProvider('2.2.2.2'), (_, _) {});
      await container.read(ipQualityProvider('2.2.2.2').future);
      final refresh = refreshFlashQuality(container.read, '2.2.2.2');
      ui.close();
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
      answer.complete(quality);
      await refresh;
    },
  );

  test(
    'missing target remains explicit instead of reverting to rules',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(flashMonitorTargetProvider.notifier)
          .select('Removed');
      expect(container.read(flashMonitorTargetProvider), 'Removed');
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
