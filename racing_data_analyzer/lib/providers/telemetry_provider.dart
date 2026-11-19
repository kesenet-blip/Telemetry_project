import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/telemetry_data.dart';
import '../services/telemetry_source.dart';
import '../services/telemetry_test_service.dart';
import '../services/telemetry_websocket_service.dart';

class TelemetryNotifier extends Notifier<TelemetryData> {
  TelemetrySource? _source;

  @override
  TelemetryData build() {
    ref.onDispose(() {
      _source?.dispose();
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
    _source = source;

    source.start(
      onData: (data) {
        state = data;
      },
    );
  }

  void stop() {
    _source?.stop();
    _source = null;
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
