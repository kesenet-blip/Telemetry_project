import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/telemetry_data.dart';
import '../recording/session_recorder.dart';
import '../services/telemetry_source.dart';
import '../services/telemetry_test_service.dart';
import '../services/telemetry_websocket_service.dart';

class TelemetryNotifier extends Notifier<TelemetryData> {
  final SessionRecorder _sessionRecorder = SessionRecorder();

  TelemetrySource? _source;

  Future<void> _recordingQueue = Future<void>.value();

  @override
  TelemetryData build() {
    ref.onDispose(() {
      _source?.dispose();
      _source = null;

      _enqueueSessionEnd();
    });

    return const TelemetryData.empty();
  }

  void startTestMode() {
    _startSource(TelemetryTestService());
  }

  void startLiveMode({String host = '127.0.0.1', int port = 8181}) {
    final url = 'ws://$host:$port/telemetry';

    _startSource(TelemetryWebSocketService(url: url));
  }

  void _startSource(TelemetrySource source) {
    _source?.dispose();
    _source = null;

    // Az előző adatforráshoz tartozó session lezárása.
    // A soros queue biztosítja, hogy az új frame-ek csak
    // a lezárás után kerüljenek feldolgozásra.
    _enqueueSessionEnd();

    _source = source;

    source.start(
      onData: (data) {
        state = data;
        _enqueueTelemetry(data);
      },
    );
  }

  void _enqueueTelemetry(TelemetryData telemetry) {
    _recordingQueue = _recordingQueue
        .then((_) async {
          await _sessionRecorder.processTelemetry(telemetry);
        })
        .onError((Object error, StackTrace stackTrace) {
          debugPrint('Session recording error: $error');

          debugPrintStack(stackTrace: stackTrace);
        });
  }

  void _enqueueSessionEnd() {
    _recordingQueue = _recordingQueue
        .then((_) async {
          await _sessionRecorder.endSession();
        })
        .onError((Object error, StackTrace stackTrace) {
          debugPrint('Session closing error: $error');

          debugPrintStack(stackTrace: stackTrace);
        });
  }

  void stop() {
    _source?.stop();
    _source?.dispose();
    _source = null;

    _enqueueSessionEnd();

    state = const TelemetryData.empty();
  }

  void stopTestMode() {
    stop();
  }

  void stopLiveMode() {
    stop();
  }

  void reset() {
    state = const TelemetryData.empty();
  }
}

final telemetryProvider = NotifierProvider<TelemetryNotifier, TelemetryData>(
  TelemetryNotifier.new,
);
