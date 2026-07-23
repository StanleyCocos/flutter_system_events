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
      _subscriptions
        ..add(html.window.onOnline.listen((_) => _emitNetwork()))
        ..add(html.window.onOffline.listen((_) => _emitNetwork()));
      _emitNetwork();
    }
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _keyboardVisible = false;
    _viewportHeight = null;
  }

  @override
  Stream<SystemEvent> get events => _controller.stream;

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
    final online = html.window.navigator.onLine == true;
    _controller.add(
      NetworkEvent(
        online: online,
        networkType: online ? NetworkType.other : NetworkType.none,
      ),
    );
  }
}
