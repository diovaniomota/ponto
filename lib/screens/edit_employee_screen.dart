import 'package:flutter/material.dart';
import 'package:ponto/models/user_model.dart';
import 'package:ponto/services/user_service.dart';

class EditEmployeeScreen extends StatefulWidget {
  final UserModel employee;

  const EditEmployeeScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _departmentController;
  late final TextEditingController _positionController;
  late final TextEditingController _hourlyWageController;

  late String _selectedRole;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.employee.fullName);
    _emailController = TextEditingController(text: widget.employee.email);
    _employeeIdController = TextEditingController(text: widget.employee.employeeId);
    _departmentController = TextEditingController(text: widget.employee.department ?? '');
    _positionController = TextEditingController(text: widget.employee.position ?? '');
    _hourlyWageController = TextEditingController(
      text: widget.employee.hourlyWage?.toString() ?? '',
    );
    _selectedRole = widget.employee.role;
    _isActive = widget.employee.isActive;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _hourlyWageController.dispose();
    super.dispose();
  }

  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await UserService.updateUser(
        userId: widget.employee.id,
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
        role: _selectedRole,
        department: _departmentController.text.trim().isNotEmpty 
            ? _departmentController.text.trim() 
            : null,
        position: _positionController.text.trim().isNotEmpty 
            ? _positionController.text.trim() 
            : null,
        hourlyWage: _hourlyWageController.text.trim().isNotEmpty 
            ? double.tryParse(_hourlyWageController.text.trim()) 
            : null,
        isActive: _isActive,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionário atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar funcionário: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Funcionário'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informações Básicas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira o nome completo';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira o email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Por favor, insira um email válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _employeeIdController,
                decoration: const InputDecoration(
                  labelText: 'ID do Funcionário',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira o ID do funcionário';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Função',
                  prefixIcon: Icon(Icons.work),
                ),
                items: const [
                  DropdownMenuItem(value: 'employee', child: Text('Funcionário')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                ],
                onChanged: (value) {
                  setState(() => _selectedRole = value ?? 'employee');
                },
              ),

              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Funcionário Ativo'),
                subtitle: Text(_isActive ? 'Ativo' : 'Inativo'),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
              ),

              const SizedBox(height: 16),

              Text(
                'Informações Adicionais',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Departamento (Opcional)',
                  prefixIcon: Icon(Icons.business),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Cargo (Opcional)',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _hourlyWageController,
                decoration: const InputDecoration(
                  labelText: 'Salário por Hora (Opcional)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Por favor, insira um valor numérico válido';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateEmployee,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Atualizar Funcionário'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}