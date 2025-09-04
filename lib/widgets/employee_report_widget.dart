import 'package:flutter/material.dart';
import 'package:ponto/models/user_model.dart';
import 'package:ponto/models/daily_summary_model.dart';
import 'package:ponto/services/user_service.dart';

class EmployeeReportWidget extends StatefulWidget {
  final UserModel employee;
  final DateTime selectedDate;
  final String reportType;

  const EmployeeReportWidget({
    super.key,
    required this.employee,
    required this.selectedDate,
    required this.reportType,
  });

  @override
  State<EmployeeReportWidget> createState() => _EmployeeReportWidgetState();
}

class _EmployeeReportWidgetState extends State<EmployeeReportWidget> {
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  @override
  void didUpdateWidget(EmployeeReportWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employee.id != widget.employee.id ||
        oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.reportType != widget.reportType) {
      _loadReportData();
    }
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.reportType == 'monthly') {
        final monthlyReport = await UserService.getUserMonthlyReport(
          userId: widget.employee.id,
          year: widget.selectedDate.year,
          month: widget.selectedDate.month,
        );
        setState(() {
          _reportData = monthlyReport;
          _isLoading = false;
        });
      } else {
        final startDate = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
        );
        final endDate = startDate.add(const Duration(days: 1));
        
        final summaries = await UserService.getUserDailySummaries(
          userId: widget.employee.id,
          startDate: startDate,
          endDate: endDate,
        );

        setState(() {
          _reportData = {
            'summaries': summaries,
            'total_hours': summaries.isNotEmpty ? summaries.first.totalHours : 0.0,
          };
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar relatório: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildMonthlyReport() {
    if (_reportData == null) return const SizedBox.shrink();

    final totalHours = _reportData!['total_hours'] as double;
    final totalOvertimeHours = _reportData!['total_overtime_hours'] as double;
    final daysWorked = _reportData!['days_worked'] as int;
    final daysMissed = _reportData!['days_missed'] as int;
    final daysInMonth = _reportData!['days_in_month'] as int;
    final summaries = _reportData!['summaries'] as List<DailySummaryModel>;

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total de Horas',
                    '${totalHours.toStringAsFixed(1)}h',
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Horas Extras',
                    '${totalOvertimeHours.toStringAsFixed(1)}h',
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Dias Trabalhados',
                    '$daysWorked',
                    Icons.work,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Faltas',
                    '$daysMissed',
                    Icons.event_busy,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Daily Breakdown
            Text(
              'Detalhes Diários',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            if (summaries.isEmpty)
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
                      'Nenhum registro encontrado para este mês',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...summaries.map((summary) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(summary.status).withValues(alpha: 0.2),
                    child: Icon(
                      _getStatusIcon(summary.status),
                      color: _getStatusColor(summary.status),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '${summary.workDate.day.toString().padLeft(2, '0')}/${summary.workDate.month.toString().padLeft(2, '0')}',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Horas: ${summary.formattedTotalHours}'),
                      if (summary.overtimeHours > 0)
                        Text('Extras: ${summary.overtimeHours.toStringAsFixed(1)}h'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(summary.status.displayName),
                      if (summary.clockIn != null)
                        Text(
                          '${summary.clockIn!.hour.toString().padLeft(2, '0')}:${summary.clockIn!.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  isThreeLine: summary.overtimeHours > 0,
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReport() {
    if (_reportData == null) return const SizedBox.shrink();

    final summaries = _reportData!['summaries'] as List<DailySummaryModel>;
    final summary = summaries.isNotEmpty ? summaries.first : null;

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary == null) ...[
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
                    Expanded(
                      child: Text(
                        'Nenhum registro encontrado para esta data',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getStatusColor(summary.status).withValues(alpha: 0.2),
                        child: Icon(
                          _getStatusIcon(summary.status),
                          color: _getStatusColor(summary.status),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.status.displayName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(summary.status),
                              ),
                            ),
                            Text(
                              'Total: ${summary.formattedTotalHours}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Time Entries
              Text(
                'Horários do Dia',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _buildTimeEntry(
                'Entrada',
                summary.clockIn,
                Icons.login,
                Colors.green,
              ),

              _buildTimeEntry(
                'Saída Almoço',
                summary.lunchOut,
                Icons.restaurant,
                Colors.orange,
              ),

              _buildTimeEntry(
                'Volta Almoço',
                summary.lunchIn,
                Icons.work,
                Colors.blue,
              ),

              _buildTimeEntry(
                'Saída',
                summary.clockOut,
                Icons.logout,
                Colors.red,
              ),

              const SizedBox(height: 16),

              // Summary Statistics
              if (summary.totalHours > 0) ...[
                Text(
                  'Estatísticas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Horas Trabalhadas',
                        summary.formattedTotalHours,
                        Icons.access_time,
                        Colors.blue,
                      ),
                    ),
                    if (summary.lunchDurationMinutes > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Almoço',
                          summary.formattedLunchDuration,
                          Icons.restaurant,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),

                if (summary.overtimeHours > 0) ...[
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    'Horas Extras',
                    '${summary.overtimeHours.toStringAsFixed(1)}h',
                    Icons.schedule,
                    Colors.purple,
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeEntry(String label, DateTime? time, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label),
        trailing: Text(
          time != null 
              ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
              : '---',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: time != null ? color : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DayStatus status) {
    switch (status) {
      case DayStatus.complete:
        return Colors.green;
      case DayStatus.incomplete:
        return Colors.orange;
      case DayStatus.missing:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(DayStatus status) {
    switch (status) {
      case DayStatus.complete:
        return Icons.check_circle;
      case DayStatus.incomplete:
        return Icons.schedule;
      case DayStatus.missing:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return widget.reportType == 'monthly' 
        ? _buildMonthlyReport() 
        : _buildDailyReport();
  }
}