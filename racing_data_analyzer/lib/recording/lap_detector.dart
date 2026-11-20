import '../models/telemetry_data.dart';

class CompletedLap {
  const CompletedLap({
    required this.lapNumber,
    required this.startedAt,
    required this.endedAt,
    required this.lapTimeSeconds,
    required this.sector1TimeSeconds,
    required this.sector2TimeSeconds,
    required this.sector3TimeSeconds,
    required this.valid,
    required this.isBest,
  });

  final int lapNumber;

  final DateTime startedAt;
  final DateTime endedAt;

  final double lapTimeSeconds;

  final double? sector1TimeSeconds;
  final double? sector2TimeSeconds;
  final double? sector3TimeSeconds;

  final bool valid;
  final bool isBest;

  @override
  String toString() {
    return 'CompletedLap('
        'lap=$lapNumber, '
        'time=$lapTimeSeconds, '
        'valid=$valid, '
        'best=$isBest'
        ')';
  }
}

class LapDetector {
  int? _currentLapNumber;
  DateTime? _currentLapStartedAt;

  bool _currentLapInvalidated = false;

  double? _bestCompletedLapTime;

  int? get currentLapNumber => _currentLapNumber;

  DateTime? get currentLapStartedAt => _currentLapStartedAt;

  bool get hasActiveLap => _currentLapNumber != null;

  /// Egy telemetry frame feldolgozása.
  ///
  /// null:
  ///   nincs most lezárt kör.
  ///
  /// CompletedLap:
  ///   körváltást érzékeltünk és az előző kör
  ///   lezárható.
  CompletedLap? processTelemetry(TelemetryData telemetry) {
    final timestamp = telemetry.timestamp;

    if (timestamp == null) {
      return null;
    }

    final lapNumber = telemetry.lap;

    // Menükben vagy még érvényes körszám nélkül
    // nem indítunk kört.
    if (lapNumber <= 0) {
      return null;
    }

    if (_currentLapNumber == null) {
      _startLap(telemetry, timestamp);

      return null;
    }

    // Ugyanaz a kör.
    if (lapNumber == _currentLapNumber) {
      if (telemetry.lapInvalidated) {
        _currentLapInvalidated = true;
      }

      return null;
    }

    // Visszafelé ugró körszám általában új session,
    // restart vagy más állapotváltás.
    // Nem gyártunk belőle hamis lezárt kört.
    if (lapNumber < _currentLapNumber!) {
      reset();

      _startLap(telemetry, timestamp);

      return null;
    }

    // Csak pontosan +1 körváltást tekintünk
    // normál célvonal-átlépésnek.
    if (lapNumber != _currentLapNumber! + 1) {
      reset();

      _startLap(telemetry, timestamp);

      return null;
    }

    final completedLap = _completeCurrentLap(telemetry, timestamp);

    _startLap(telemetry, timestamp);

    return completedLap;
  }

  void _startLap(TelemetryData telemetry, DateTime timestamp) {
    _currentLapNumber = telemetry.lap;

    final currentLapTime = telemetry.currentLapTimeSeconds;

    // Ha ismerjük az aktuális köridőt,
    // visszaszámoljuk a valódi körkezdetet.
    //
    // Ez pontosabb, mintha egyszerűen az első
    // beérkező frame timestampjét használnánk.
    if (currentLapTime != null && currentLapTime >= 0) {
      _currentLapStartedAt = timestamp.subtract(
        Duration(microseconds: (currentLapTime * 1000000).round()),
      );
    } else {
      _currentLapStartedAt = timestamp;
    }

    _currentLapInvalidated = telemetry.lapInvalidated;
  }

  CompletedLap? _completeCurrentLap(
    TelemetryData telemetry,
    DateTime timestamp,
  ) {
    final previousLapNumber = _currentLapNumber;

    final startedAt = _currentLapStartedAt;

    if (previousLapNumber == null || startedAt == null) {
      return null;
    }

    // Körváltás után az LMU scoring LastLapTime
    // mezője az éppen befejezett kör idejét adja.
    final lapTime = telemetry.lastLapTimeSeconds;

    if (!_validLapTime(lapTime)) {
      return null;
    }

    final sector1 = _validSectorTime(telemetry.sector1TimeSeconds);

    final sector2 = _validSectorTime(telemetry.sector2TimeSeconds);

    final sector3 = _validSectorTime(telemetry.sector3TimeSeconds);

    final valid = !_currentLapInvalidated;

    var isBest = false;

    if (valid) {
      final previousBest = _bestCompletedLapTime;

      if (previousBest == null || lapTime! < previousBest) {
        _bestCompletedLapTime = lapTime;

        isBest = true;
      }
    }

    return CompletedLap(
      lapNumber: previousLapNumber,
      startedAt: startedAt,
      endedAt: timestamp,
      lapTimeSeconds: lapTime!,
      sector1TimeSeconds: sector1,
      sector2TimeSeconds: sector2,
      sector3TimeSeconds: sector3,
      valid: valid,
      isBest: isBest,
    );
  }

  bool _validLapTime(double? value) {
    if (value == null) {
      return false;
    }

    return value > 0 && value < 3600 && value.isFinite;
  }

  double? _validSectorTime(double? value) {
    if (value == null) {
      return null;
    }

    if (value <= 0 || value >= 1800 || !value.isFinite) {
      return null;
    }

    return value;
  }

  /// Új session, restart vagy manuális STOP
  /// esetén hívjuk.
  void reset() {
    _currentLapNumber = null;
    _currentLapStartedAt = null;
    _currentLapInvalidated = false;
    _bestCompletedLapTime = null;
  }
}
