import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/telemetry_provider.dart';
import '../../widgets/app_sidebar.dart';
import '../dashboard/bridge_connection_panel.dart';
import 'telemetry_diagnostics_panel.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    return Scaffold(
      body: Row(
        children: [
          const AppSidebar(selectedPage: 'settings'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Application and telemetry connection settings',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Telemetry Connection',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect the dashboard to the LMU Telemetry Bridge.',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),

                  BridgeConnectionPanel(
                    initialHost: '127.0.0.1',
                    initialPort: 8181,
                    onConnect: (settings) {
                      ref
                          .read(telemetryProvider.notifier)
                          .startLiveMode(
                            host: settings.host,
                            port: settings.port,
                          );
                    },
                  ),

                  const SizedBox(height: 24),

                  TelemetryDiagnosticsPanel(telemetry: telemetry),

                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white54),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Local bridge: 127.0.0.1:8181\n'
                              'Remote bridge: enter the IPv4 address '
                              'of the PC running LmuTelemetryBridge.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
