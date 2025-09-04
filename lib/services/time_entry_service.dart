import 'package:ponto/models/time_entry_model.dart';
import 'package:ponto/models/daily_summary_model.dart';
import 'package:ponto/supabase/supabase_config.dart';

class TimeEntryService {
  static Future<TimeEntryModel> clockIn({
    required String userId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final data = {
      'user_id': userId,
      'entry_type': TimeEntryType.clockIn.value,
      'location_lat': latitude,
      'location_lng': longitude,
      'notes': notes,
    };

    final result = await SupabaseService.insert('time_entries', data);
    return TimeEntryModel.fromJson(result.first);
  }

  static Future<TimeEntryModel> lunchOut({
    required String userId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final data = {
      'user_id': userId,
      'entry_type': TimeEntryType.lunchOut.value,
      'location_lat': latitude,
      'location_lng': longitude,
      'notes': notes,
    };

    final result = await SupabaseService.insert('time_entries', data);
    return TimeEntryModel.fromJson(result.first);
  }

  static Future<TimeEntryModel> lunchIn({
    required String userId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final data = {
      'user_id': userId,
      'entry_type': TimeEntryType.lunchIn.value,
      'location_lat': latitude,
      'location_lng': longitude,
      'notes': notes,
    };

    final result = await SupabaseService.insert('time_entries', data);
    return TimeEntryModel.fromJson(result.first);
  }

  static Future<TimeEntryModel> clockOut({
    required String userId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final data = {
      'user_id': userId,
      'entry_type': TimeEntryType.clockOut.value,
      'location_lat': latitude,
      'location_lng': longitude,
      'notes': notes,
    };

    final result = await SupabaseService.insert('time_entries', data);
    await _updateDailySummary(userId);
    return TimeEntryModel.fromJson(result.first);
  }

  static Future<List<TimeEntryModel>> getTodayEntries(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    dynamic query = SupabaseConfig.client
        .from('time_entries')
        .select()
        .eq('user_id', userId)
        .gte('timestamp', startOfDay.toIso8601String())
        .lt('timestamp', endOfDay.toIso8601String())
        .order('timestamp');

    final result = await query;
    return result.map<TimeEntryModel>((json) => TimeEntryModel.fromJson(json)).toList();
  }

  static Future<List<TimeEntryModel>> getEntriesForDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    dynamic query = SupabaseConfig.client
        .from('time_entries')
        .select()
        .eq('user_id', userId)
        .gte('timestamp', startOfDay.toIso8601String())
        .lt('timestamp', endOfDay.toIso8601String())
        .order('timestamp');

    final result = await query;
    return result.map<TimeEntryModel>((json) => TimeEntryModel.fromJson(json)).toList();
  }

  static Future<TimeEntryModel?> getLastEntry(String userId) async {
    dynamic query = SupabaseConfig.client
        .from('time_entries')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .limit(1);

    final result = await query;
    if (result.isEmpty) return null;
    return TimeEntryModel.fromJson(result.first);
  }

  static Future<void> _updateDailySummary(String userId) async {
    final today = DateTime.now();
    final todayEntries = await getEntriesForDate(userId, today);
    
    if (todayEntries.isEmpty) return;

    DateTime? clockIn, lunchOut, lunchIn, clockOut;
    
    for (final entry in todayEntries) {
      switch (entry.entryType) {
        case TimeEntryType.clockIn:
          clockIn = entry.timestamp;
          break;
        case TimeEntryType.lunchOut:
          lunchOut = entry.timestamp;
          break;
        case TimeEntryType.lunchIn:
          lunchIn = entry.timestamp;
          break;
        case TimeEntryType.clockOut:
          clockOut = entry.timestamp;
          break;
      }
    }

    double totalHours = 0;
    int lunchDurationMinutes = 0;

    if (clockIn != null && clockOut != null) {
      final workDuration = clockOut.difference(clockIn);
      totalHours = workDuration.inMinutes / 60.0;

      if (lunchOut != null && lunchIn != null) {
        final lunchDuration = lunchIn.difference(lunchOut);
        lunchDurationMinutes = lunchDuration.inMinutes;
        totalHours -= lunchDurationMinutes / 60.0;
      }
    }

    final overtimeHours = totalHours > 8 ? totalHours - 8 : 0;
    final status = clockOut != null ? DayStatus.complete : DayStatus.incomplete;

    final workDate = DateTime(today.year, today.month, today.day);
    
    final summaryData = {
      'user_id': userId,
      'work_date': workDate.toIso8601String().split('T')[0],
      'clock_in': clockIn?.toIso8601String(),
      'lunch_out': lunchOut?.toIso8601String(),
      'lunch_in': lunchIn?.toIso8601String(),
      'clock_out': clockOut?.toIso8601String(),
      'total_hours': totalHours,
      'lunch_duration_minutes': lunchDurationMinutes,
      'overtime_hours': overtimeHours,
      'status': status.value,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Try to update existing record, if not exists, insert new one
    dynamic query = SupabaseConfig.client
        .from('daily_summaries')
        .select('id')
        .eq('user_id', userId)
        .eq('work_date', workDate.toIso8601String().split('T')[0]);
    
    final existing = await query;
    
    if (existing.isNotEmpty) {
      await SupabaseService.update(
        'daily_summaries',
        summaryData,
        filters: {
          'user_id': userId,
          'work_date': workDate.toIso8601String().split('T')[0],
        },
      );
    } else {
      summaryData['created_at'] = DateTime.now().toIso8601String();
      await SupabaseService.insert('daily_summaries', summaryData);
    }
  }
}