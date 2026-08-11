import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'flutter_system_events_platform_interface.dart';

/// A web implementation of the FlutterSystemEventsPlatform of the FlutterSystemEvents plugin.
class FlutterSystemEventsWeb extends FlutterSystemEventsPlatform {
  /// Constructs a FlutterSystemEventsWeb
  FlutterSystemEventsWeb();

  final _controller = StreamController<SystemEvent>.broadcast();
  final _subscriptions = <StreamSubscription<html.Event>>[];
  var _keyboardVisible = false;
  _NetworkSnapshot? _lastNetworkSnapshot;
  double? _viewportHeight;

  static void registerWith(Registrar registrar) {
    FlutterSystemEventsPlatform.instance = FlutterSystemEventsWeb();
  }

  @override
  Future<void> initialize({
    SystemEventsConfig config = const SystemEventsConfig.defaults(),
  }) async {
    await dispose();

    if (config.keyboard != null) {
      _viewportHeight = html.window.innerHeight?.toDouble();
      _subscriptions.add(html.window.onResize.listen((_) => _emitKeyboard()));
    }
    if (config.lifecycle != null) {
      _subscriptions
        ..add(html.document.onVisibilityChange.listen((_) => _emitLifecycle()))
        ..add(
          html.window.onFocus.listen(
            (_) => _addLifecycle(LifecycleState.resumed),
          ),
        )
        ..add(
          html.window.onBlur.listen(
            (_) => _addLifecycle(LifecycleState.inactive),
          ),
        )
        ..add(
          html.window.onBeforeUnload.listen(
            (_) => _addLifecycle(LifecycleState.detached),
          ),
        );
    }
    if (config.network != null) {
      _lastNetworkSnapshot = _NetworkSnapshot.fromEvent(_networkEvent());
      _subscriptions
        ..add(html.window.onOnline.listen((_) => _emitNetwork()))
        ..add(html.window.onOffline.listen((_) => _emitNetwork()));
    }
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _keyboardVisible = false;
    _lastNetworkSnapshot = null;
    _viewportHeight = null;
  }

  @override
  Stream<SystemEvent> get events => _controller.stream;

  @override
  Future<NetworkEvent> currentNetwork() async {
    return _networkEvent();
  }

  @override
  Future<ThermalEvent> currentThermal() async {
    throw UnsupportedError('currentThermal() is not supported on Web.');
  }

  void _emitKeyboard() {
    final currentHeight = html.window.innerHeight?.toDouble();
    final baseHeight = _viewportHeight;
    if (currentHeight == null || baseHeight == null) return;

    if (currentHeight > baseHeight) _viewportHeight = currentHeight;

    final height = (baseHeight - currentHeight)
        .clamp(0, double.infinity)
        .toDouble();
    final visible = height > baseHeight * 0.15;
    if (visible == _keyboardVisible) return;

    _keyboardVisible = visible;
    _controller.add(
      KeyboardEvent(visible: visible, height: visible ? height : 0),
    );
  }

  void _emitLifecycle() {
    _addLifecycle(
      html.document.hidden == true
          ? LifecycleState.paused
          : LifecycleState.resumed,
    );
  }

  void _addLifecycle(LifecycleState state) {
    _controller.add(LifecycleEvent(state: state));
  }

  void _emitNetwork() {
    final event = _networkEvent();
    final snapshot = _NetworkSnapshot.fromEvent(event);
    final lastSnapshot = _lastNetworkSnapshot;
    if (lastSnapshot == null) {
      _lastNetworkSnapshot = snapshot;
      return;
    }
    if (snapshot == lastSnapshot) return;
    _lastNetworkSnapshot = snapshot;
    _controller.add(event);
  }

  NetworkEvent _networkEvent() {
    final online = html.window.navigator.onLine == true;
    return NetworkEvent(
      online: online,
      networkType: online ? NetworkType.other : NetworkType.none,
    );
  }
}

final class _NetworkSnapshot {
  const _NetworkSnapshot({required this.online, required this.networkType});

  factory _NetworkSnapshot.fromEvent(NetworkEvent event) {
    return _NetworkSnapshot(
      online: event.online,
      networkType: event.networkType,
    );
  }

  final bool online;
  final NetworkType networkType;

  @override
  bool operator ==(Object other) {
    return other is _NetworkSnapshot &&
        other.online == online &&
        other.networkType == networkType;
  }

  @override
  int get hashCode => Object.hash(online, networkType);
}
