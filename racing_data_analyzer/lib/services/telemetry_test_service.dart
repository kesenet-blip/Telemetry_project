import 'dart:async';

import '../models/telemetry_data.dart';
import 'telemetry_source.dart';

class TelemetryTestService implements TelemetrySource {
  Timer? _timer;
  double _time = 0;

  @override
  bool get isRunning => _timer != null;

  @override
  void start({required void Function(TelemetryData data) onData}) {
    if (_timer != null) {
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _time += 0.1;

      final phase = (_time % 10) / 10;

      final speed = 80 + (phase * 160);
      final rpm = 4000 + (phase * 4500).round();

      final gear = switch (speed) {
        < 100 => '3',
        < 140 => '4',
        < 190 => '5',
        _ => '6',
      };

      final throttle = phase < 0.8 ? 0.85 : 0.25;
      final brake = phase < 0.8 ? 0.0 : 0.65;
      final delta = (phase - 0.5) * 0.4;

      onData(
        TelemetryData(
          timestamp: DateTime.now().toUtc(),
          source: 'flutter-test',
          vehicleId: 1,
          speed: speed,
          rpm: rpm,
          maxRpm: 9000,
          gear: gear,
          throttle: throttle,
          brake: brake,
          steering: 0.25,
          clutch: 0.0,
          delta: delta,

          vehicle: 'Test Hypercar',
          vehicleModel: 'Test Model',
          track: 'Test Circuit',

          lap: 3,
          sector: 2,
          currentLapTimeSeconds: 72.345,
          lastLapTimeSeconds: 207.842,
          bestLapTimeSeconds: 205.327,
          sector1TimeSeconds: 64.812,
          sector2TimeSeconds: 74.221,
          sector3TimeSeconds: 68.809,

          fuel: 47.5,
          fuelCapacity: 90.0,

          tc: 4,
          tcMax: 10,
          tcActive: throttle > 0.8,

          abs: 3,
          absMax: 8,
          absActive: brake > 0.5,

          stateOfCharge: 0.72,
          regenKw: brake * 180.0,
          virtualEnergy: 47.2,

          lapInvalidated: false,

          gapAhead: 1.842,
          gapBehind: 2.117,

          activeVehicles: 37,
        ),
      );
    });
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
    _time = 0;
  }

  @override
  void dispose() {
    stop();
  }
}
