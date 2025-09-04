import 'package:ponto/models/user_model.dart';
import 'package:ponto/models/daily_summary_model.dart';
import 'package:ponto/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  // ========== NOVOS MÉTODOS DE AUTENTICAÇÃO ==========

  static Future<UserModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      print('🔐 Tentando fazer login com email: $email');

      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ Login realizado com sucesso: ${response.user!.email}');

        // Buscar dados do usuário na tabela users
        final userData = await getCurrentUser();
        return userData;
      } else {
        print('❌ Login falhou: usuário é null');
        return null;
      }
    } on AuthException catch (e) {
      print('❌ Erro de autenticação: ${e.message}');
      print('📊 Código do erro: ${e.statusCode}');

      // Tratar diferentes tipos de erro
      switch (e.message) {
        case 'Invalid login credentials':
          throw Exception('Email ou senha incorretos');
        case 'Email not confirmed':
          throw Exception(
            'Email não confirmado. Verifique sua caixa de entrada',
          );
        case 'Too many requests':
          throw Exception(
            'Muitas tentativas. Tente novamente em alguns minutos',
          );
        default:
          throw Exception('Erro de autenticação: ${e.message}');
      }
    } catch (e) {
      print('💥 Erro geral no login: $e');
      throw Exception('Erro inesperado durante o login');
    }
  }

  static Future<void> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
      print('👋 Logout realizado com sucesso');
    } catch (e) {
      print('❌ Erro no logout: $e');
      throw Exception('Erro ao fazer logout');
    }
  }

  static Future<bool> testConnection() async {
    try {
      print('🔍 Testando conexão com Supabase...');

      final response = await SupabaseConfig.client
          .from('users')
          .select('count')
          .limit(1);

      print('✅ Conexão com Supabase OK');
      return true;
    } catch (e) {
      print('❌ Erro de conexão com Supabase: $e');
      return false;
    }
  }

  // ========== MÉTODO getCurrentUser ATUALIZADO ==========

  static Future<UserModel?> getCurrentUser() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        print('👤 Nenhum usuário logado');
        return null;
      }

      print('👤 Usuário autenticado encontrado: ${user.email}');

      final result = await SupabaseService.selectSingle(
        'users',
        filters: {'id': user.id},
      );

      if (result == null) {
        print('⚠️ Usuário autenticado mas não encontrado na tabela users');
        // Tentar criar o perfil
        await _createUserProfileIfNeeded(user);
        // Recarregar após criar
        return getCurrentUser();
      }

      // DEBUG: Mostra exatamente quais dados vieram do banco
      print('🔍 DADOS DO BANCO:');
      print('ID: ${result['id']}');
      print('Email: ${result['email']}');
      print('Full Name: ${result['full_name']}');
      print('Employee ID: ${result['employee_id']}');
      print('Role: ${result['role']}');
      print('Department: ${result['department']}');
      print('Position: ${result['position']}');
      print('Hourly Wage: ${result['hourly_wage']}');
      print('Is Active: ${result['is_active']}');
      print('Created At: ${result['created_at']}');
      print('Updated At: ${result['updated_at']}');

      // CORREÇÃO: Adicionar valores padrão para campos null
      final safeResult = Map<String, dynamic>.from(result);

      if (safeResult['employee_id'] == null) {
        safeResult['employee_id'] = 'ADMIN001';
        print(
          '⚠️ Employee ID era null, definido como: ${safeResult['employee_id']}',
        );
        await SupabaseService.update(
          'users',
          {'employee_id': safeResult['employee_id']},
          filters: {'id': user.id},
        );
      }

      if (safeResult['role'] == null) {
        safeResult['role'] = 'admin';
        print('⚠️ Role era null, definido como: ${safeResult['role']}');
        await SupabaseService.update(
          'users',
          {'role': safeResult['role']},
          filters: {'id': user.id},
        );
      }

      if (safeResult['is_active'] == null) {
        safeResult['is_active'] = true;
        print(
          '⚠️ Is Active era null, definido como: ${safeResult['is_active']}',
        );
        await SupabaseService.update(
          'users',
          {'is_active': safeResult['is_active']},
          filters: {'id': user.id},
        );
      }

      print('🔧 DADOS CORRIGIDOS: $safeResult');

      final userModel = UserModel.fromJson(safeResult);
      print('✅ Dados do usuário carregados: ${userModel.fullName}');
      return userModel;
    } catch (e) {
      print('❌ Erro ao obter usuário atual: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  static Future<void> _createUserProfileIfNeeded(User user) async {
    try {
      final existingUser = await SupabaseService.selectSingle(
        'users',
        filters: {'id': user.id},
      );
      if (existingUser == null) {
        print('🔧 Criando perfil para usuário: ${user.email}');
        await SupabaseService.insert('users', {
          'id': user.id,
          'email': user.email ?? '',
          'full_name': user.userMetadata?['full_name'] ?? 'Usuário',
          'employee_id': 'ADMIN001',
          'role': 'admin',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('✅ Perfil criado com sucesso');
      }
    } catch (e) {
      print('❌ Erro ao criar perfil: $e');
      throw Exception('Falha ao criar perfil: $e');
    }
  }

  // ========== MÉTODOS EXISTENTES ==========

  static Future<List<UserModel>> getAllUsers() async {
    final result = await SupabaseService.select('users', orderBy: 'full_name');

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
    await SupabaseService.delete('users', filters: {'id': userId});
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
    return result
        .map<DailySummaryModel>((json) => DailySummaryModel.fromJson(json))
        .toList();
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
