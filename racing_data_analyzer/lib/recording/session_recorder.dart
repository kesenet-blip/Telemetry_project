import '../database/app_database.dart';
import '../models/telemetry_data.dart';
import 'lap_detector.dart';

class SessionRecorder {
  SessionRecorder({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  final LapDetector _lapDetector = LapDetector();

  int? _sessionId;
  DateTime? _sessionStartedAt;

  int? _activeLapId;
  int? _activeLapNumber;

  String? _source;
  String? _track;
  String? _vehicle;
  String? _vehicleModel;
  int? _vehicleId;

  int? get sessionId => _sessionId;

  DateTime? get sessionStartedAt => _sessionStartedAt;

  int? get activeLapId => _activeLapId;

  int? get activeLapNumber => _activeLapNumber;

  bool get hasActiveSession => _sessionId != null;

  bool get hasActiveLap => _activeLapId != null;

  Future<int?> processTelemetry(TelemetryData telemetry) async {
    if (!_isUsableFrame(telemetry)) {
      return null;
    }

    //
    // SESSION
    //

    if (_sessionId == null) {
      await _startSession(telemetry);
    } else if (!belongsToCurrentSession(telemetry)) {
      await endSession();
      await _startSession(telemetry);
    }

    final sessionId = _sessionId;

    if (sessionId == null) {
      return null;
    }

    //
    // LAP DETECTION
    //

    final completedLap = _lapDetector.processTelemetry(telemetry);

    //
    // Első aktív kör létrehozása
    //

    if (_activeLapId == null &&
        _lapDetector.hasActiveLap &&
        _lapDetector.currentLapNumber != null &&
        _lapDetector.currentLapStartedAt != null) {
      await _startLap(
        sessionId: sessionId,
        lapNumber: _lapDetector.currentLapNumber!,
        startedAt: _lapDetector.currentLapStartedAt!,
      );
    }

    //
    // Körváltás
    //

    if (completedLap != null) {
      await _completeLap(completedLap);

      //
      // A LapDetector a lezárás után már
      // elindította az új aktuális kört.
      //

      final newLapNumber = _lapDetector.currentLapNumber;

      final newLapStartedAt = _lapDetector.currentLapStartedAt;

      if (newLapNumber != null && newLapStartedAt != null) {
        await _startLap(
          sessionId: sessionId,
          lapNumber: newLapNumber,
          startedAt: newLapStartedAt,
        );
      }
    }

    return sessionId;
  }

  bool _isUsableFrame(TelemetryData telemetry) {
    if (telemetry.timestamp == null) {
      return false;
    }

    if (telemetry.source.trim().isEmpty) {
      return false;
    }

    if (telemetry.vehicle.trim().isEmpty) {
      return false;
    }

    if (telemetry.track.trim().isEmpty) {
      return false;
    }

    return true;
  }

  Future<void> _startSession(TelemetryData telemetry) async {
    final timestamp = telemetry.timestamp;

    if (timestamp == null) {
      return;
    }

    final startedAt = timestamp.toUtc();

    final id = await _database.insertSession(
      startedAt: startedAt,
      source: telemetry.source,
      track: telemetry.track,
      vehicle: telemetry.vehicle,
      vehicleModel: telemetry.vehicleModel,
      vehicleId: telemetry.vehicleId,
    );

    _sessionId = id;
    _sessionStartedAt = startedAt;

    _source = telemetry.source;
    _track = telemetry.track;
    _vehicle = telemetry.vehicle;
    _vehicleModel = telemetry.vehicleModel;
    _vehicleId = telemetry.vehicleId;

    _activeLapId = null;
    _activeLapNumber = null;

    _lapDetector.reset();
  }

  Future<void> _startLap({
    required int sessionId,
    required int lapNumber,
    required DateTime startedAt,
  }) async {
    //
    // Ugyanazt a kört nem nyitjuk meg még egyszer.
    //

    if (_activeLapNumber == lapNumber && _activeLapId != null) {
      return;
    }

    final lapId = await _database.insertLap(
      sessionId: sessionId,
      lapNumber: lapNumber,
      startedAt: startedAt,
    );

    //
    // ConflictAlgorithm.ignore esetén SQLite
    // adhat 0-t, ha a kör már létezett.
    //
    // Normál adatfolyamnál ennek nem kell
    // előfordulnia.
    //

    if (lapId <= 0) {
      _activeLapId = null;
      _activeLapNumber = lapNumber;
      return;
    }

    _activeLapId = lapId;
    _activeLapNumber = lapNumber;
  }

  Future<void> _completeLap(CompletedLap completedLap) async {
    final lapId = _activeLapId;

    //
    // Csak azt a DB-kört zárjuk le,
    // amelyet valóban aktív körként követünk.
    //

    if (lapId == null || _activeLapNumber != completedLap.lapNumber) {
      return;
    }

    await _database.completeLap(
      lapId: lapId,
      endedAt: completedLap.endedAt,
      lapTimeSeconds: completedLap.lapTimeSeconds,
      sector1TimeSeconds: completedLap.sector1TimeSeconds,
      sector2TimeSeconds: completedLap.sector2TimeSeconds,
      sector3TimeSeconds: completedLap.sector3TimeSeconds,
      valid: completedLap.valid,
      isBest: completedLap.isBest,
    );

    _activeLapId = null;
    _activeLapNumber = null;
  }

  Future<void> endSession({DateTime? endedAt}) async {
    final id = _sessionId;

    if (id == null) {
      _lapDetector.reset();
      _clearLap();
      return;
    }

    await _database.endSession(
      sessionId: id,
      endedAt: (endedAt ?? DateTime.now()).toUtc(),
    );

    _lapDetector.reset();

    _clearLap();
    _clearSession();
  }

  void _clearLap() {
    _activeLapId = null;
    _activeLapNumber = null;
  }

  void _clearSession() {
    _sessionId = null;
    _sessionStartedAt = null;

    _source = null;
    _track = null;
    _vehicle = null;
    _vehicleModel = null;
    _vehicleId = null;
  }

  bool belongsToCurrentSession(TelemetryData telemetry) {
    if (_sessionId == null) {
      return false;
    }

    return telemetry.source == _source &&
        telemetry.track == _track &&
        telemetry.vehicle == _vehicle &&
        telemetry.vehicleModel == _vehicleModel &&
        telemetry.vehicleId == _vehicleId;
  }
}
