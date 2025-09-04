import 'package:flutter/material.dart';
import 'package:ponto/models/user_model.dart';
import 'package:ponto/services/user_service.dart';
import 'package:ponto/screens/add_employee_screen.dart';
import 'package:ponto/screens/edit_employee_screen.dart';

class ManageEmployeesScreen extends StatefulWidget {
  final VoidCallback? onEmployeesChanged;

  const ManageEmployeesScreen({
    super.key,
    this.onEmployeesChanged,
  });

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  List<UserModel> _employees = [];
  List<UserModel> _filteredEmployees = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    
    try {
      final employees = await UserService.getAllUsers();
      setState(() {
        _employees = employees;
        _filteredEmployees = employees;
        _isLoading = false;
      });
      _filterEmployees();
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar funcionários: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _filterEmployees() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredEmployees = _employees.where((employee) {
        final matchesSearch = employee.fullName.toLowerCase().contains(query) ||
            employee.employeeId.toLowerCase().contains(query) ||
            employee.email.toLowerCase().contains(query);

        final matchesFilter = _selectedFilter == 'all' ||
            (_selectedFilter == 'active' && employee.isActive) ||
            (_selectedFilter == 'inactive' && !employee.isActive) ||
            (_selectedFilter == 'admin' && employee.isAdmin) ||
            (_selectedFilter == 'employee' && employee.isEmployee);

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _deleteEmployee(UserModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o funcionário ${employee.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserService.deleteUser(employee.id);
        await _loadEmployees();
        widget.onEmployeesChanged?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funcionário excluído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir funcionário: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleEmployeeStatus(UserModel employee) async {
    try {
      await UserService.updateUser(
        userId: employee.id,
        isActive: !employee.isActive,
      );
      await _loadEmployees();
      widget.onEmployeesChanged?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              employee.isActive 
                  ? 'Funcionário desativado com sucesso!'
                  : 'Funcionário ativado com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar status: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar funcionários...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterEmployees();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Ativos', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Inativos', 'inactive'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Admins', 'admin'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Funcionários', 'employee'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Employees List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum funcionário encontrado',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEmployees,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = _filteredEmployees[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: employee.isActive 
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  child: Icon(
                                    employee.isAdmin ? Icons.admin_panel_settings : Icons.person,
                                    color: employee.isActive ? Colors.green : Colors.grey,
                                  ),
                                ),
                                title: Text(employee.fullName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID: ${employee.employeeId}'),
                                    Text('${employee.email} • ${employee.role}'),
                                    if (employee.department != null)
                                      Text('Depto: ${employee.department}'),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    switch (value) {
                                      case 'edit':
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditEmployeeScreen(employee: employee),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadEmployees();
                                          widget.onEmployeesChanged?.call();
                                        }
                                        break;
                                      case 'toggle_status':
                                        await _toggleEmployeeStatus(employee);
                                        break;
                                      case 'delete':
                                        await _deleteEmployee(employee);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit),
                                        title: Text('Editar'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle_status',
                                      child: ListTile(
                                        leading: Icon(
                                          employee.isActive ? Icons.block : Icons.check_circle,
                                        ),
                                        title: Text(
                                          employee.isActive ? 'Desativar' : 'Ativar',
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete, color: Colors.red),
                                        title: Text('Excluir', style: TextStyle(color: Colors.red)),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEmployeeScreen(),
            ),
          );
          if (result == true) {
            _loadEmployees();
            widget.onEmployeesChanged?.call();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
        _filterEmployees();
      },
    );
  }
}