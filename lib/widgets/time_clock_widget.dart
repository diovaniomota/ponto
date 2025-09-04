import 'package:flutter/material.dart';
import 'package:ponto/models/time_entry_model.dart';

class TimeClockWidget extends StatelessWidget {
  final TimeEntryType? nextEntryType;
  final bool isLoading;
  final Function(TimeEntryType) onTimeEntry;

  const TimeClockWidget({
    super.key,
    required this.nextEntryType,
    required this.isLoading,
    required this.onTimeEntry,
  });

  Color _getButtonColor(BuildContext context) {
    if (nextEntryType == null) {
      return Theme.of(context).colorScheme.surfaceVariant;
    }
    
    switch (nextEntryType!) {
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

  IconData _getButtonIcon() {
    if (nextEntryType == null) return Icons.check_circle;
    
    switch (nextEntryType!) {
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

  String _getButtonText() {
    if (nextEntryType == null) return 'Dia Completo';
    return nextEntryType!.displayName;
  }

  String _getStatusMessage() {
    if (nextEntryType == null) {
      return 'Você completou seu expediente hoje! 🎉';
    }
    
    switch (nextEntryType!) {
      case TimeEntryType.clockIn:
        return 'Bem-vindo! Registre sua entrada para começar o dia.';
      case TimeEntryType.lunchOut:
        return 'Hora do almoço! Registre sua saída.';
      case TimeEntryType.lunchIn:
        return 'De volta do almoço? Registre seu retorno.';
      case TimeEntryType.clockOut:
        return 'Finalizando o dia? Registre sua saída.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getButtonColor(context).withValues(alpha: 0.1),
                border: Border.all(
                  color: _getButtonColor(context),
                  width: 3,
                ),
              ),
              child: Icon(
                _getButtonIcon(),
                size: 48,
                color: _getButtonColor(context),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              _getButtonText(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getButtonColor(context),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _getStatusMessage(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (nextEntryType != null && !isLoading) 
                    ? () => onTimeEntry(nextEntryType!)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonColor(context),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        nextEntryType != null ? 'Registrar ${nextEntryType!.displayName}' : 'Expediente Completo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}