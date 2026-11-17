import '../models/telemetry_data.dart';

abstract interface class TelemetrySource {
  bool get isRunning;

  void start({
    required void Function(TelemetryData data) onData,
  });

  void stop();

  void dispose();
}