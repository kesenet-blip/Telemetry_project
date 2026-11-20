import 'package:flutter/material.dart';

import 'features/dashboard/dashboard_page.dart';
import 'features/sessions/sessions_page.dart';
import 'features/settings/settings_page.dart';

class RacingDataAnalyzerApp extends StatelessWidget {
  const RacingDataAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Racing Data Analyzer',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101114),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardPage(),

        '/sessions': (context) => const SessionsPage(),

        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
