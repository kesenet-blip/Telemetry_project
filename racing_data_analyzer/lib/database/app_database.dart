import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const int schemaVersion = 1;
  static const String databaseFileName = 'racing_data_analyzer.db';

  Database? _database;
  String? _databasePath;

  Database get database {
    final db = _database;

    if (db == null) {
      throw StateError('Az adatbázis még nincs inicializálva.');
    }

    return db;
  }

  String? get databasePath => _databasePath;

  bool get isOpen => _database?.isOpen ?? false;

  Future<void> initialize() async {
    if (_database != null) {
      return;
    }

    sqfliteFfiInit();

    final supportDirectory = await getApplicationSupportDirectory();

    final databaseDirectory = Directory(
      path.join(supportDirectory.path, 'RacingDataAnalyzer'),
    );

    if (!databaseDirectory.existsSync()) {
      databaseDirectory.createSync(recursive: true);
    }

    _databasePath = path.join(databaseDirectory.path, databaseFileName);

    _database = await databaseFactoryFfi.openDatabase(
      _databasePath!,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: _configure,
        onCreate: _createSchema,
      ),
    );
  }

  Future<void> _configure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');

    await db.execute('PRAGMA journal_mode = WAL');

    await db.execute('PRAGMA synchronous = NORMAL');
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.transaction((txn) async {
      //
      // SESSIONS
      //

      await txn.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            started_at TEXT NOT NULL,
            ended_at TEXT,

            source TEXT NOT NULL,
            track TEXT NOT NULL,
            vehicle TEXT NOT NULL,
            vehicle_model TEXT NOT NULL,
            vehicle_id INTEGER NOT NULL,

            created_at TEXT NOT NULL
          )
        ''');

      //
      // LAPS
      //

      await txn.execute('''
          CREATE TABLE laps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            session_id INTEGER NOT NULL,
            lap_number INTEGER NOT NULL,

            started_at TEXT NOT NULL,
            ended_at TEXT,

            lap_time_seconds REAL,
            sector1_time_seconds REAL,
            sector2_time_seconds REAL,
            sector3_time_seconds REAL,

            valid INTEGER NOT NULL DEFAULT 1,
            is_best INTEGER NOT NULL DEFAULT 0,

            FOREIGN KEY (session_id)
              REFERENCES sessions(id)
              ON DELETE CASCADE,

            UNIQUE(session_id, lap_number)
          )
        ''');

      //
      // TELEMETRY SAMPLES
      //

      await txn.execute('''
          CREATE TABLE telemetry_samples (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            session_id INTEGER NOT NULL,
            lap_id INTEGER,

            timestamp TEXT NOT NULL,

            lap_number INTEGER NOT NULL,
            current_lap_time_seconds REAL,

            speed_kmh REAL NOT NULL,
            rpm INTEGER NOT NULL,
            max_rpm REAL NOT NULL,
            gear TEXT NOT NULL,

            throttle REAL NOT NULL,
            brake REAL NOT NULL,
            steering REAL NOT NULL,
            clutch REAL NOT NULL,

            fuel REAL NOT NULL,
            delta_best REAL NOT NULL,

            lap_invalidated INTEGER NOT NULL
              DEFAULT 0,

            FOREIGN KEY (session_id)
              REFERENCES sessions(id)
              ON DELETE CASCADE,

            FOREIGN KEY (lap_id)
              REFERENCES laps(id)
              ON DELETE SET NULL
          )
        ''');

      //
      // INDEXES
      //

      await txn.execute('''
          CREATE INDEX idx_laps_session
          ON laps(
            session_id,
            lap_number
          )
        ''');

      await txn.execute('''
          CREATE INDEX idx_samples_lap
          ON telemetry_samples(
            lap_id
          )
        ''');

      await txn.execute('''
          CREATE INDEX idx_samples_timestamp
          ON telemetry_samples(
            timestamp
          )
        ''');
    });
  }

  // ==========================================================
  // DIAGNOSTICS
  // ==========================================================

  Future<List<String>> tableNames() async {
    final result = await database.rawQuery('''
          SELECT name
          FROM sqlite_master
          WHERE type = 'table'
            AND name NOT LIKE 'sqlite_%'
          ORDER BY name
        ''');

    return result.map((row) => row['name'] as String).toList();
  }

  Future<int> sessionCount() async {
    final result = await database.rawQuery('''
      SELECT COUNT(*) AS count
      FROM sessions
      ''');

    if (result.isEmpty) {
      return 0;
    }

    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<int> lapCount() async {
    final result = await database.rawQuery('''
      SELECT COUNT(*) AS count
      FROM laps
      ''');

    if (result.isEmpty) {
      return 0;
    }

    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<List<Map<String, Object?>>> recentLaps({int limit = 100}) async {
    return database.rawQuery(
      '''
      SELECT
        laps.id,
        laps.session_id,
        laps.lap_number,
        laps.started_at,
        laps.ended_at,
        laps.lap_time_seconds,
        laps.sector1_time_seconds,
        laps.sector2_time_seconds,
        laps.sector3_time_seconds,
        laps.valid,
        laps.is_best,

        sessions.source,
        sessions.track,
        sessions.vehicle,
        sessions.vehicle_model

      FROM laps

      INNER JOIN sessions
        ON sessions.id = laps.session_id

      ORDER BY
        laps.id DESC

      LIMIT ?
      ''',
      [limit],
    );
  }

  Future<int> telemetrySampleCount() async {
    final result = await database.rawQuery('''
      SELECT COUNT(*) AS count
      FROM telemetry_samples
      ''');

    if (result.isEmpty) {
      return 0;
    }

    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  // ==========================================================
  // SESSION
  // ==========================================================

  Future<int> insertSession({
    required DateTime startedAt,
    required String source,
    required String track,
    required String vehicle,
    required String vehicleModel,
    required int vehicleId,
  }) async {
    return database.insert('sessions', {
      'started_at': startedAt.toUtc().toIso8601String(),

      'ended_at': null,

      'source': source,

      'track': track,

      'vehicle': vehicle,

      'vehicle_model': vehicleModel,

      'vehicle_id': vehicleId,

      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> endSession({
    required int sessionId,
    required DateTime endedAt,
  }) async {
    await database.update(
      'sessions',
      {'ended_at': endedAt.toUtc().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // ==========================================================
  // LAPS
  // ==========================================================

  Future<int> insertLap({
    required int sessionId,
    required int lapNumber,
    required DateTime startedAt,
  }) async {
    return database.insert('laps', {
      'session_id': sessionId,

      'lap_number': lapNumber,

      'started_at': startedAt.toUtc().toIso8601String(),

      'ended_at': null,

      'lap_time_seconds': null,

      'sector1_time_seconds': null,

      'sector2_time_seconds': null,

      'sector3_time_seconds': null,

      'valid': 1,

      'is_best': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> completeLap({
    required int lapId,
    required DateTime endedAt,
    required double lapTimeSeconds,
    double? sector1TimeSeconds,
    double? sector2TimeSeconds,
    double? sector3TimeSeconds,
    required bool valid,
    required bool isBest,
  }) async {
    await database.update(
      'laps',
      {
        'ended_at': endedAt.toUtc().toIso8601String(),

        'lap_time_seconds': lapTimeSeconds,

        'sector1_time_seconds': sector1TimeSeconds,

        'sector2_time_seconds': sector2TimeSeconds,

        'sector3_time_seconds': sector3TimeSeconds,

        'valid': valid ? 1 : 0,

        'is_best': isBest ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [lapId],
    );
  }

  // ==========================================================
  // TELEMETRY SAMPLES
  // ==========================================================

  Future<int> insertTelemetrySample({
    required int sessionId,
    int? lapId,

    required DateTime timestamp,

    required int lapNumber,
    double? currentLapTimeSeconds,

    required double speedKmh,

    required int rpm,
    required double maxRpm,

    required String gear,

    required double throttle,
    required double brake,
    required double steering,
    required double clutch,

    required double fuel,
    required double deltaBest,

    required bool lapInvalidated,
  }) async {
    return database.insert('telemetry_samples', {
      'session_id': sessionId,

      'lap_id': lapId,

      'timestamp': timestamp.toUtc().toIso8601String(),

      'lap_number': lapNumber,

      'current_lap_time_seconds': currentLapTimeSeconds,

      'speed_kmh': speedKmh,

      'rpm': rpm,

      'max_rpm': maxRpm,

      'gear': gear,

      'throttle': throttle,

      'brake': brake,

      'steering': steering,

      'clutch': clutch,

      'fuel': fuel,

      'delta_best': deltaBest,

      'lap_invalidated': lapInvalidated ? 1 : 0,
    });
  }

  // ==========================================================
  // CLOSE
  // ==========================================================

  Future<void> close() async {
    await _database?.close();

    _database = null;
    _databasePath = null;
  }
}
