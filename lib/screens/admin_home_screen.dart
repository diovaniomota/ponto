import 'package:flutter/material.dart';
import 'package:ponto/models/user_model.dart';
import 'package:ponto/services/user_service.dart';
import 'package:ponto/screens/login_screen.dart';
import 'package:ponto/screens/manage_employees_screen.dart';
import 'package:ponto/screens/reports_screen.dart';
import 'package:ponto/supabase/supabase_config.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  UserModel? _currentUser;
  List<UserModel> _employees = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user == null || !user.isAdmin) {
        _redirectToLogin();
        return;
      }

      final employees = await UserService.getAllUsers();

      setState(() {
        _currentUser = user;
        _employees = employees;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _signOut() async {
    try {
      await SupabaseAuth.signOut();
      _redirectToLogin();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer logout: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildDashboard() {
    final activeEmployees = _employees.where((e) => e.isActive).length;
    final totalEmployees = _employees.length;
    final adminCount = _employees.where((e) => e.isAdmin).length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo, Administrador!',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Gerencie funcionários e visualize relatórios',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Funcionários Ativos',
                    '$activeEmployees',
                    Icons.people,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total de Funcionários',
                    '$totalEmployees',
                    Icons.group,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Administradores',
                    '$adminCount',
                    Icons.admin_panel_settings,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Funcionários Comuns',
                    '${totalEmployees - adminCount}',
                    Icons.person,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Ações Rápidas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildActionCard(
              'Gerenciar Funcionários',
              'Adicionar, editar ou remover funcionários',
              Icons.people_alt,
              Colors.blue,
              () => setState(() => _selectedIndex = 1),
            ),

            const SizedBox(height: 12),

            _buildActionCard(
              'Relatórios',
              'Visualizar relatórios de ponto e produtividade',
              Icons.analytics,
              Colors.green,
              () => setState(() => _selectedIndex = 2),
            ),

            const SizedBox(height: 32),

            // Recent Employees
            if (_employees.isNotEmpty) ...[
              Text(
                'Funcionários Recentes',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ..._employees
                  .take(5)
                  .map(
                    (employee) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: employee.isActive
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          child: Icon(
                            employee.isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            color: employee.isActive
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        title: Text(employee.fullName),
                        subtitle: Text(
                          '${employee.employeeId} • ${employee.department ?? 'Sem departamento'}',
                        ),
                        trailing: Icon(
                          employee.isActive ? Icons.check_circle : Icons.cancel,
                          color: employee.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          ManageEmployeesScreen(onEmployeesChanged: _loadData),
          const ReportsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Funcionários',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Relatórios',
          ),
        ],
      ),
    );
  }
}
