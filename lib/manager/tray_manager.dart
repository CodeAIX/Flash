import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/tray.dart';
import 'package:fl_clash/common/window.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/providers/outbound_ip.dart';
import 'package:fl_clash/providers/ip_quality.dart';
import 'package:fl_clash/providers/routed_probe.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/route_state.dart';
import 'package:fl_clash/common/service_probe.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray/tray.dart';

class TrayManager extends ConsumerStatefulWidget {
  final Widget child;

  const TrayManager({super.key, required this.child});

  @override
  ConsumerState<TrayManager> createState() => _TrayManagerState();
}

class _TrayManagerState extends ConsumerState<TrayManager> {
  StreamSubscription<TrayEvent>? _subscription;
  Timer? _flashTimer;
  ProviderSubscription<AsyncValue<IpQuality>>? _qualitySubscription;
  String? _qualityIp;
  bool _flashWatching = false;
  OutboundIpProbe? _flashProbe;
  RouteTracker? _flashRoute;
  bool _isUpdating = false;
  bool _hasPendingUpdate = false;

  @override
  void initState() {
    super.initState();
    _subscription = Tray.instance.events.listen(_handleTrayEvent);
    ref.listenManual(trayStateProvider, (prev, next) {
      if (prev != next) {
        _requestUpdate();
      }
    });
    ref.listenManual(loadedLocaleProvider, (prev, next) {
      if (prev != null && prev != next) {
        _requestUpdate();
      }
    });
    if (system.isMacOS &&
        const bool.fromEnvironment('FLASH_STATUS_ICON', defaultValue: true)) {
      scheduleMicrotask(_syncFlashWatch);
      ref.listenManual(
        trayStateProvider,
        (_, _) => scheduleMicrotask(_syncFlashWatch),
      );
      ref.listenManual(outboundIpProbeProvider, (_, _) {
        scheduleMicrotask(_syncFlashQuality);
        _requestUpdate();
      });
    }
    if (system.isMacOS) {
      ref.listenManual(trayDelaysProvider, (prev, next) {
        if (!const DeepCollectionEquality().equals(prev, next)) {
          _requestUpdate();
        }
      });
      ref.listenManual(trayTitleStateProvider, (prev, next) {
        if (prev != next) {
          _reportFailure(
            appTray?.updateTitle(
              showTrayTitle: next.showTrayTitle,
              traffic: next.traffic,
            ),
          );
        }
      });
    }
  }

  void _syncFlashWatch() {
    if (!mounted) return;
    final tray = ref.read(trayStateProvider);
    _syncFlashQuality();
    final wanted = !tray.safeMode && tray.isStart && !tray.suspended;
    if (wanted == _flashWatching) return;
    _flashWatching = wanted;
    if (wanted) {
      _flashRoute = ref.read(routeTrackerProvider.notifier);
      _flashProbe = ref.read(outboundIpProbeProvider.notifier);
      _flashRoute!.attachBackground();
      _flashProbe!.watch(routedOutbound);
      _flashTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        ref.read(outboundIpProbeProvider.notifier).refresh([routedOutbound]);
      });
    } else {
      _flashTimer?.cancel();
      _flashProbe?.unwatch(routedOutbound);
      _flashRoute?.detachBackground();
      _flashProbe = null;
      _flashRoute = null;
    }
  }

  void _syncFlashQuality() {
    if (!mounted) return;
    final tray = ref.read(trayStateProvider);
    final entry = ref.read(outboundIpProbeProvider).entryOf(routedOutbound);
    final ip =
        !tray.safeMode &&
            tray.isStart &&
            !tray.suspended &&
            entry.phase == ProbePhase.fresh
        ? entry.value?.ip
        : null;
    if (ip == _qualityIp) return;
    _qualitySubscription?.close();
    _qualitySubscription = null;
    _qualityIp = ip;
    if (ip != null) {
      _qualitySubscription = ref.listenManual(
        ipQualityProvider(ip),
        (_, _) => _requestUpdate(),
      );
    }
  }

  /// A delay test changes the menu per proxy, so updates in flight coalesce.
  void _requestUpdate() {
    if (_isUpdating) {
      _hasPendingUpdate = true;
      return;
    }
    _isUpdating = true;
    _reportFailure(_drainUpdates());
  }

  Future<void> _drainUpdates() async {
    try {
      do {
        _hasPendingUpdate = false;
        await ref.read(systemActionProvider.notifier).updateTray();
      } while (_hasPendingUpdate && mounted);
    } finally {
      _isUpdating = false;
      if (_hasPendingUpdate && mounted) {
        _requestUpdate();
      }
    }
  }

  void _reportFailure(Future<void>? operation) {
    if (operation == null) {
      return;
    }
    unawaited(
      operation.onError<Object>((error, stackTrace) {
        commonPrint.log(
          'Tray operation failed: ${compactError(error)}',
          logLevel: LogLevel.error,
        );
      }),
    );
  }

  void _handleTrayEvent(TrayEvent event) {
    switch (event) {
      case TrayIconActivated():
        window?.show();
      case TrayMenuRequested():
        _reportFailure(Tray.instance.openMenu());
      case TrayMenuItemSelected():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _qualitySubscription?.close();
    _flashTimer?.cancel();
    if (_flashWatching) {
      _flashProbe?.unwatch(routedOutbound);
      _flashRoute?.detachBackground();
      _flashProbe = null;
      _flashRoute = null;
    }
    _subscription?.cancel();
    super.dispose();
  }
}
