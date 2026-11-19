import 'package:flutter/material.dart';

import '../../models/telemetry_data.dart';

class TelemetryDiagnosticsPanel extends StatelessWidget {
  const TelemetryDiagnosticsPanel({super.key, required this.telemetry});

  final TelemetryData telemetry;

  @override
  Widget build(BuildContext context) {
    final hasFrame = telemetry.timestamp != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  color: hasFrame ? Colors.greenAccent : Colors.white38,
                ),
                const SizedBox(width: 10),
                Text(
                  'Telemetry Diagnostics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _StatusIndicator(
                  active: hasFrame,
                  label: hasFrame ? 'DATA RECEIVED' : 'NO DATA',
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DiagnosticItem(
                  label: 'SOURCE',
                  value: telemetry.source.isEmpty ? '-' : telemetry.source,
                ),
                _DiagnosticItem(
                  label: 'VEHICLE ID',
                  value: hasFrame ? telemetry.vehicleId.toString() : '-',
                ),
                _DiagnosticItem(
                  label: 'LAST FRAME',
                  value: _formatTimestamp(telemetry.timestamp),
                ),
                _DiagnosticItem(
                  label: 'MAX RPM',
                  value: telemetry.maxRpm > 0
                      ? telemetry.maxRpm.toStringAsFixed(0)
                      : '-',
                ),
                _DiagnosticItem(
                  label: 'STEERING',
                  value: hasFrame
                      ? '${(telemetry.steering * 100).toStringAsFixed(1)} %'
                      : '-',
                ),
                _DiagnosticItem(
                  label: 'CLUTCH',
                  value: hasFrame
                      ? '${(telemetry.clutch * 100).toStringAsFixed(1)} %'
                      : '-',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) {
      return '-';
    }

    final local = timestamp.toLocal();

    return '${_twoDigits(local.hour)}:'
        '${_twoDigits(local.minute)}:'
        '${_twoDigits(local.second)}.'
        '${local.millisecond.toString().padLeft(3, '0')}';
  }

  static String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}

class _DiagnosticItem extends StatelessWidget {
  const _DiagnosticItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF171A20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.greenAccent : Colors.white38;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
