import 'dart:async';

import 'tracking_sync_processor.dart';

class TrackingSyncCoordinator {
  TrackingSyncCoordinator({
    required TrackingSyncProcessor processor,
    Duration interval = const Duration(seconds: 30),
    TrackingSyncDiagnosticLog? diagnosticLog,
  }) : _processor = processor,
       _interval = interval,
       _diagnosticLog = diagnosticLog;

  final TrackingSyncProcessor _processor;
  final Duration _interval;
  final TrackingSyncDiagnosticLog? _diagnosticLog;
  Timer? _timer;
  bool _isRunning = false;

  void start() {
    if (_timer != null) {
      return;
    }

    _diagnosticLog?.call('Tracking sync coordinator started');
    unawaited(trigger());
    _timer = Timer.periodic(_interval, (_) {
      unawaited(trigger());
    });
  }

  Future<void> trigger() async {
    if (_isRunning) {
      return;
    }

    _isRunning = true;
    _diagnosticLog?.call('Tracking sync cycle triggered');
    try {
      await _processor.processDue();
    } catch (_) {
      // Publishing must never interrupt local offline-first app usage.
    } finally {
      _isRunning = false;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
