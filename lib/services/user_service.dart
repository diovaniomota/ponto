import 'package:ponto/models/user_model.dart';
import 'package:ponto/models/daily_summary_model.dart';
import 'package:ponto/supabase/supabase_config.dart';

class UserService {
  static Future<UserModel?> getCurrentUser() async {
    final user = SupabaseAuth.currentUser;
    if (user == null) return null;

    final result = await SupabaseService.selectSingle(
      'users',
      filters: {'id': user.id},
    );

    if (result == null) return null;
    return UserModel.fromJson(result);
  }

  static Future<List<UserModel>> getAllUsers() async {
    final result = await SupabaseService.select(
      'users',
      orderBy: 'full_name',
    );

    return result.map<UserModel>((json) => UserModel.fromJson(json)).toList();
  }

  static Future<UserModel> createUser({
    required String email,
    required String fullName,
    required String employeeId,
    required String role,
    String? department,
    String? position,
    double? hourlyWage,
  }) async {
    final userData = {
      'email': email,
      'full_name': fullName,
      'employee_id': employeeId,
      'role': role,
      'department': department,
      'position': position,
      'hourly_wage': hourlyWage,
      'is_active': true,
    };

    final result = await SupabaseService.insert('users', userData);
    return UserModel.fromJson(result.first);
  }

  static Future<UserModel> updateUser({
    required String userId,
    String? email,
    String? fullName,
    String? employeeId,
    String? role,
    String? department,
    String? position,
    double? hourlyWage,
    bool? isActive,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (email != null) updateData['email'] = email;
    if (fullName != null) updateData['full_name'] = fullName;
    if (employeeId != null) updateData['employee_id'] = employeeId;
    if (role != null) updateData['role'] = role;
    if (department != null) updateData['department'] = department;
    if (position != null) updateData['position'] = position;
    if (hourlyWage != null) updateData['hourly_wage'] = hourlyWage;
    if (isActive != null) updateData['is_active'] = isActive;

    final result = await SupabaseService.update(
      'users',
      updateData,
      filters: {'id': userId},
    );

    return UserModel.fromJson(result.first);
  }

  static Future<void> deleteUser(String userId) async {
    await SupabaseService.delete(
      'users',
      filters: {'id': userId},
    );
  }

  static Future<List<DailySummaryModel>> getUserDailySummaries({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    dynamic query = SupabaseConfig.client
        .from('daily_summaries')
        .select()
        .eq('user_id', userId)
        .gte('work_date', startDate.toIso8601String().split('T')[0])
        .lte('work_date', endDate.toIso8601String().split('T')[0])
        .order('work_date', ascending: false);

    final result = await query;
    return result.map<DailySummaryModel>((json) => DailySummaryModel.fromJson(json)).toList();
  }

  static Future<Map<String, dynamic>> getUserMonthlyReport({
    required String userId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final summaries = await getUserDailySummaries(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    double totalHours = 0;
    double totalOvertimeHours = 0;
    int daysWorked = 0;
    int daysMissed = 0;

    for (final summary in summaries) {
      totalHours += summary.totalHours;
      totalOvertimeHours += summary.overtimeHours;
      
      if (summary.status == DayStatus.complete) {
        daysWorked++;
      } else if (summary.status == DayStatus.missing) {
        daysMissed++;
      }
    }

    return {
      'total_hours': totalHours,
      'total_overtime_hours': totalOvertimeHours,
      'days_worked': daysWorked,
      'days_missed': daysMissed,
      'days_in_month': endDate.day,
      'summaries': summaries,
    };
  }

  static Future<UserModel?> getUserByEmployeeId(String employeeId) async {
    final result = await SupabaseService.selectSingle(
      'users',
      filters: {'employee_id': employeeId},
    );

    if (result == null) return null;
    return UserModel.fromJson(result);
  }
}