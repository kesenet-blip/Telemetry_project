import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/telemetry_provider.dart';
import '../../widgets/app_sidebar.dart';
import 'widgets/telemetry_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);

    final vehicleName = telemetry.vehicle.isEmpty
        ? 'No vehicle'
        : telemetry.vehicle;

    final vehicleModel = telemetry.vehicleModel.isEmpty
        ? ''
        : telemetry.vehicleModel;

    final trackName = telemetry.track.isEmpty
        ? 'No track loaded'
        : telemetry.track;

    final fuelPercent = telemetry.fuelCapacity > 0
        ? telemetry.fuel / telemetry.fuelCapacity
        : 0.0;

    return Scaffold(
      body: Row(
        children: [
          const AppSidebar(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //
                  // HEADER
                  //
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              vehicleModel.isEmpty
                                  ? vehicleName
                                  : '$vehicleName • $vehicleModel',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              trackName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),

                      //
                      // SESSION INFO
                      //
                      _InfoBadge(
                        label: 'LAP',
                        value: telemetry.lap.toString(),
                      ),

                      const SizedBox(width: 10),

                      _InfoBadge(
                        label: 'SECTOR',
                        value: telemetry.sector > 0
                            ? telemetry.sector.toString()
                            : '-',
                      ),

                      const SizedBox(width: 10),

                      _InfoBadge(
                        label: 'CARS',
                        value: telemetry.activeVehicles.toString(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  //
                  // SOURCE CONTROL
                  //
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          ref
                              .read(telemetryProvider.notifier)
                              .startTestMode();
                        },
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('START TEST'),
                      ),

                      FilledButton.icon(
                        onPressed: () {
                          ref
                              .read(telemetryProvider.notifier)
                              .startLiveMode();
                        },
                        icon: const Icon(Icons.sensors),
                        label: const Text('LIVE LMU'),
                      ),

                      OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(telemetryProvider.notifier)
                              .stop();
                        },
                        icon: const Icon(Icons.stop),
                        label: const Text('STOP'),
                      ),

                      TextButton.icon(
                        onPressed: () {
                          ref
                              .read(telemetryProvider.notifier)
                              .reset();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('RESET'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  //
                  // PRIMARY TELEMETRY
                  //
                  Row(
                    children: [
                      TelemetryCard(
                        title: 'Speed',
                        value: telemetry.speed.toStringAsFixed(0),
                        unit: 'km/h',
                        icon: Icons.speed,
                      ),

                      const SizedBox(width: 16),

                      TelemetryCard(
                        title: 'RPM',
                        value: telemetry.rpm.toString(),
                        unit: 'rpm',
                        icon: Icons.rotate_right,
                      ),

                      const SizedBox(width: 16),

                      TelemetryCard(
                        title: 'Gear',
                        value: telemetry.gear,
                        unit: '',
                        icon: Icons.settings,
                      ),

                      const SizedBox(width: 16),

                      TelemetryCard(
                        title: 'Delta',
                        value: _formatDelta(telemetry.delta),
                        unit: 's',
                        icon: Icons.compare_arrows,
                        accentColor: telemetry.delta <= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        active: telemetry.delta != 0,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  //
                  // DRIVER INPUT
                  //
                  Row(
                    children: [
                      TelemetryCard(
                        title: 'Throttle',
                        value:
                            '${(telemetry.throttle * 100).toStringAsFixed(0)}',
                        unit: '%',
                        icon: Icons.trending_up,
                        accentColor: Colors.greenAccent,
                        active: telemetry.throttle > 0.05,
                      ),

                      const SizedBox(width: 16),

                      TelemetryCard(
                        title: 'Brake',
                        value:
                            '${(telemetry.brake * 100).toStringAsFixed(0)}',
                        unit: '%',
                        icon: Icons.compress,
                        accentColor: Colors.redAccent,
                        active: telemetry.brake > 0.05,
                      ),

                      const SizedBox(width: 16),

                      TelemetryCard(
                        title: 'TC',
                        value: '${telemetry.tc}/${telemetry.tcMax}',
                        unit: '',
                        icon: Icons.control_camera,
                        accentColor: Colors.orangeAccent,
                        active: telemetry.tcActive,
                      ),

                      const SizedBox(width: 16),

                      TelemetryCard(
                        title: 'ABS',
                        value: '${telemetry.abs}/${telemetry.absMax}',
                        unit: '',
                        icon: Icons.tire_repair,
                        accentColor: Colors.amberAccent,
                        active: telemetry.absActive,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  //
                  // ENERGY / FUEL
                  //
                  Row(
                    children: [
                      TelemetryCard(
                        title: 'Fuel',
                        value: telemetry.fuel.toStringAsFixed(1),
                        unit: 'L',
                        icon: Icons.local_gas_station,
                        accentColor:
                            fuelPercent < 0.15
                                ? Colors.redAccent
                                : null,
                        active: telemetry.fuelCapacity > 0 &&
                            fuelPercent < 0.15,
                      ),

                      const SizedBox(width: 16),

                      TelemetryCard(
                        title: 'Fuel Level',
                        value: telemetry.fuelCapacity > 0
                            ? (fuelPercent * 100).toStringAsFixed(0)
                            : '-',
                        unit: telemetry.fuelCapacity > 0 ? '%' : '',
                        icon: Icons.battery_4_bar,
                      ),

                      const SizedBox(width: 16),

                      TelemetryCard(
                        title: 'State of Charge',
                        value: (telemetry.stateOfCharge * 100)
                            .toStringAsFixed(0),
                        unit: '%',
                        icon: Icons.battery_charging_full,
                        accentColor: Colors.cyanAccent,
                      ),

                      const SizedBox(width: 16),

                      TelemetryCard(
                        title: 'Regen',
                        value: telemetry.regenKw.toStringAsFixed(1),
                        unit: 'kW',
                        icon: Icons.energy_savings_leaf,
                        accentColor: Colors.cyanAccent,
                        active: telemetry.regenKw.abs() > 0.1,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  //
                  // RACE / TRAFFIC DATA
                  //
                  Row(
                    children: [
                      TelemetryCard(
                        title: 'Gap Ahead',
                        value: telemetry.gapAhead.toStringAsFixed(3),
                        unit: 's',
                        icon: Icons.arrow_upward,
                      ),

                      const SizedBox(width: 16),

                      TelemetryCard(
                        title: 'Gap Behind',
                        value: telemetry.gapBehind.toStringAsFixed(3),
                        unit: 's',
                        icon: Icons.arrow_downward,
                      ),

                      const SizedBox(width: 16),

                      TelemetryCard(
                        title: 'Virtual Energy',
                        value: telemetry.virtualEnergy
                            .toStringAsFixed(2),
                        unit: '',
                        icon: Icons.bolt,
                      ),

                      const SizedBox(width: 16),

                      TelemetryCard(
                        title: 'Lap Status',
                        value: telemetry.lapInvalidated
                            ? 'INVALID'
                            : 'VALID',
                        unit: '',
                        icon: telemetry.lapInvalidated
                            ? Icons.warning_amber
                            : Icons.check_circle_outline,
                        accentColor: telemetry.lapInvalidated
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        active: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDelta(double delta) {
    if (delta > 0) {
      return '+${delta.toStringAsFixed(3)}';
    }

    return delta.toStringAsFixed(3);
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF171A20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}