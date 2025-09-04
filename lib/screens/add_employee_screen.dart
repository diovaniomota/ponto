import 'package:flutter/material.dart';
import 'package:ponto/services/user_service.dart';
import 'package:ponto/supabase/supabase_config.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();
  final _hourlyWageController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'employee';
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _hourlyWageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // First create the auth user
      final authResponse = await SupabaseAuth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        userData: {
          'full_name': _fullNameController.text.trim(),
          'employee_id': _employeeIdController.text.trim(),
          'role': _selectedRole,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Erro ao criar usuário de autenticação');
      }

      // Then create the user profile
      await UserService.createUser(
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
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionário criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar funcionário: $error'),
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
        title: const Text('Adicionar Funcionário'),
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
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a senha';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
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

              const SizedBox(height: 32),

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
                  onPressed: _isLoading ? null : _saveEmployee,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Criar Funcionário'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}