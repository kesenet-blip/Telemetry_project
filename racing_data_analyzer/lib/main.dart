import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase.instance.initialize();

  final tables = await AppDatabase.instance.tableNames();

  debugPrint('SQLite database: ${AppDatabase.instance.databasePath}');
  debugPrint('SQLite tables: ${tables.join(', ')}');

  final sessionCount = await AppDatabase.instance.sessionCount();

  debugPrint('SQLite sessions: $sessionCount');

  final lapCount = await AppDatabase.instance.lapCount();

  debugPrint('SQLite laps: $lapCount');

  runApp(const ProviderScope(child: RacingDataAnalyzerApp()));
}
