import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../widgets/app_sidebar.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() =>
      _SessionsPageState();
}

class _SessionsPageState
    extends State<SessionsPage> {
  late Future<List<Map<String, Object?>>> _lapsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _lapsFuture = AppDatabase.instance.recentLaps(
      limit: 100,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _refresh();
    });

    await _lapsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AppSidebar(
            selectedPage: 'sessions',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sessions & Laps',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Recorded lap data from SQLite',
                              style: TextStyle(
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(
                          Icons.refresh,
                        ),
                        label: const Text(
                          'Refresh',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: FutureBuilder<
                        List<Map<String, Object?>>>(
                      future: _lapsFuture,
                      builder: (
                        context,
                        snapshot,
                      ) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child:
                                CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return _ErrorPanel(
                            error: snapshot.error,
                            onRetry: _reload,
                          );
                        }

                        final laps =
                            snapshot.data ??
                                const [];

                        if (laps.isEmpty) {
                          return const _EmptyPanel();
                        }

                        return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _SummaryBar(
                              laps: laps,
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Expanded(
                              child: Card(
                                clipBehavior:
                                    Clip.antiAlias,
                                child:
                                    SingleChildScrollView(
                                  child:
                                      SingleChildScrollView(
                                    scrollDirection:
                                        Axis.horizontal,
                                    child: DataTable(
                                      showBottomBorder:
                                          true,
                                      columns: const [
                                        DataColumn(
                                          label: Text(
                                            'Session',
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Lap',
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Lap Time',
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'S1',
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'S2',
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'S3',
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Valid',
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Best',
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Track',
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Vehicle',
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Source',
                                          ),
                                        ),
                                      ],
                                      rows: laps
                                          .map(
                                            _buildRow,
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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

  DataRow _buildRow(
    Map<String, Object?> lap,
  ) {
    final isBest =
        _asBool(lap['is_best']);

    final valid =
        _asBool(lap['valid']);

    return DataRow(
      color: isBest
          ? WidgetStatePropertyAll(
              Colors.greenAccent.withValues(
                alpha: 0.06,
              ),
            )
          : null,
      cells: [
        DataCell(
          Text(
            '${lap['session_id'] ?? '-'}',
          ),
        ),
        DataCell(
          Text(
            '${lap['lap_number'] ?? '-'}',
          ),
        ),
        DataCell(
          Text(
            _formatLapTime(
              lap['lap_time_seconds'],
            ),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isBest
                  ? Colors.greenAccent
                  : Colors.white,
            ),
          ),
        ),
        DataCell(
          Text(
            _formatLapTime(
              lap['sector1_time_seconds'],
            ),
          ),
        ),
        DataCell(
          Text(
            _formatLapTime(
              lap['sector2_time_seconds'],
            ),
          ),
        ),
        DataCell(
          Text(
            _formatLapTime(
              lap['sector3_time_seconds'],
            ),
          ),
        ),
        DataCell(
          Icon(
            valid
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            color: valid
                ? Colors.greenAccent
                : Colors.redAccent,
            size: 20,
          ),
        ),
        DataCell(
          isBest
              ? const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20,
                )
              : const SizedBox.shrink(),
        ),
        DataCell(
          Text(
            '${lap['track'] ?? '-'}',
          ),
        ),
        DataCell(
          Text(
            '${lap['vehicle'] ?? '-'}',
          ),
        ),
        DataCell(
          Text(
            '${lap['source'] ?? '-'}',
          ),
        ),
      ],
    );
  }

  static bool _asBool(
    Object? value,
  ) {
    if (value is int) {
      return value != 0;
    }

    if (value is bool) {
      return value;
    }

    return false;
  }

  static String _formatLapTime(
    Object? value,
  ) {
    if (value is! num) {
      return '-';
    }

    final seconds = value.toDouble();

    if (!seconds.isFinite ||
        seconds <= 0) {
      return '-';
    }

    final minutes =
        seconds ~/ 60;

    final remainingSeconds =
        seconds - minutes * 60;

    return '$minutes:'
        '${remainingSeconds.toStringAsFixed(3).padLeft(6, '0')}';
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.laps,
  });

  final List<Map<String, Object?>> laps;

  @override
  Widget build(BuildContext context) {
    final completed =
        laps.where(
          (lap) =>
              lap['lap_time_seconds']
                  is num,
        );

    double? bestLap;

    for (final lap in completed) {
      final value =
          (lap['lap_time_seconds'] as num)
              .toDouble();

      if (value <= 0) {
        continue;
      }

      if (bestLap == null ||
          value < bestLap) {
        bestLap = value;
      }
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryItem(
          label: 'Stored laps',
          value: '${laps.length}',
        ),
        _SummaryItem(
          label: 'Completed',
          value: '${completed.length}',
        ),
        _SummaryItem(
          label: 'Best lap',
          value:
              _SessionsPageState
                  ._formatLapTime(
            bestLap,
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF17191D),
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding:
              const EdgeInsets.all(32),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 48,
                color: Colors.white38,
              ),
              const SizedBox(height: 16),
              Text(
                'No recorded laps yet',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Run TEST or connect to the LMU Bridge '
                'to create lap records.',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to read lap data',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: const TextStyle(
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}