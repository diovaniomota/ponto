import 'package:flutter/material.dart';
import 'package:ponto/models/time_entry_model.dart';

class TodaySummaryWidget extends StatelessWidget {
  final List<TimeEntryModel> entries;
  final VoidCallback? onRefresh;

  const TodaySummaryWidget({
    super.key,
    required this.entries,
    this.onRefresh,
  });

  Duration? _calculateWorkDuration() {
    TimeEntryModel? clockIn, clockOut;
    
    for (final entry in entries) {
      if (entry.entryType == TimeEntryType.clockIn) {
        clockIn = entry;
      } else if (entry.entryType == TimeEntryType.clockOut) {
        clockOut = entry;
      }
    }

    if (clockIn != null && clockOut != null) {
      return clockOut.timestamp.difference(clockIn.timestamp);
    } else if (clockIn != null) {
      return DateTime.now().difference(clockIn.timestamp);
    }
    
    return null;
  }

  Duration? _calculateLunchDuration() {
    TimeEntryModel? lunchOut, lunchIn;
    
    for (final entry in entries) {
      if (entry.entryType == TimeEntryType.lunchOut) {
        lunchOut = entry;
      } else if (entry.entryType == TimeEntryType.lunchIn) {
        lunchIn = entry;
      }
    }

    if (lunchOut != null && lunchIn != null) {
      return lunchIn.timestamp.difference(lunchOut.timestamp);
    } else if (lunchOut != null) {
      return DateTime.now().difference(lunchOut.timestamp);
    }
    
    return null;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }

  Color _getEntryColor(TimeEntryType type) {
    switch (type) {
      case TimeEntryType.clockIn:
        return Colors.green;
      case TimeEntryType.lunchOut:
        return Colors.orange;
      case TimeEntryType.lunchIn:
        return Colors.blue;
      case TimeEntryType.clockOut:
        return Colors.red;
    }
  }

  IconData _getEntryIcon(TimeEntryType type) {
    switch (type) {
      case TimeEntryType.clockIn:
        return Icons.login;
      case TimeEntryType.lunchOut:
        return Icons.restaurant;
      case TimeEntryType.lunchIn:
        return Icons.work;
      case TimeEntryType.clockOut:
        return Icons.logout;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workDuration = _calculateWorkDuration();
    final lunchDuration = _calculateLunchDuration();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Resumo de Hoje',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Work Duration
            if (workDuration != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tempo trabalhado: ${_formatDuration(workDuration)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            if (workDuration != null) const SizedBox(height: 8),

            // Lunch Duration
            if (lunchDuration != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.restaurant, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tempo de almoço: ${_formatDuration(lunchDuration)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            if (lunchDuration != null) const SizedBox(height: 16),
            if (workDuration != null && lunchDuration == null) const SizedBox(height: 16),

            // Entries List
            if (entries.isNotEmpty) ...[
              Text(
                'Registros de Hoje',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getEntryColor(entry.entryType).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getEntryIcon(entry.entryType),
                        size: 16,
                        color: _getEntryColor(entry.entryType),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.entryType.displayName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            entry.formattedTime,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nenhum registro hoje',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}