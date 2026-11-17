import 'package:flutter/material.dart';

class TelemetryCard extends StatelessWidget {
  const TelemetryCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.accentColor,
    this.active = false,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;

  final Color? accentColor;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color =
        accentColor ?? Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF171A20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.06),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active
                      ? color
                      : Colors.white54,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                if (active)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active
                          ? color
                          : Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 6),

                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 4,
                    ),
                    child: Text(
                      unit,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}