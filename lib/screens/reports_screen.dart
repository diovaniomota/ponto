import 'package:flutter/material.dart';
import 'package:ponto/models/user_model.dart';
import 'package:ponto/models/daily_summary_model.dart';
import 'package:ponto/services/user_service.dart';
import 'package:ponto/widgets/employee_report_widget.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<UserModel> _employees = [];
  UserModel? _selectedEmployee;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _reportType = 'monthly'; // 'monthly' or 'daily'

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    
    try {
      final employees = await UserService.getAllUsers();
      final activeEmployees = employees.where((e) => e.isActive && e.isEmployee).toList();
      
      setState(() {
        _employees = activeEmployees;
        if (activeEmployees.isNotEmpty && _selectedEmployee == null) {
          _selectedEmployee = activeEmployees.first;
        }
        _isLoading = false;
      });
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

  Future<void> _selectDate() async {
    if (_reportType == 'monthly') {
      final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDatePickerMode: DatePickerMode.year,
      );
      if (date != null) {
        setState(() => _selectedDate = date);
      }
    } else {
      final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (date != null) {
        setState(() => _selectedDate = date);
      }
    }
  }

  String get _dateDisplayText {
    if (_reportType == 'monthly') {
      return '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}';
    } else {
      return '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum funcionário ativo encontrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Report Type Toggle
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'daily',
                            label: Text('Diário'),
                            icon: Icon(Icons.today),
                          ),
                          ButtonSegment(
                            value: 'monthly',
                            label: Text('Mensal'),
                            icon: Icon(Icons.calendar_month),
                          ),
                        ],
                        selected: {_reportType},
                        onSelectionChanged: (Set<String> selection) {
                          setState(() => _reportType = selection.first);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Employee Selector
                DropdownButtonFormField<UserModel>(
                  value: _selectedEmployee,
                  decoration: const InputDecoration(
                    labelText: 'Funcionário',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: _employees.map((employee) {
                    return DropdownMenuItem<UserModel>(
                      value: employee,
                      child: Text('${employee.fullName} (${employee.employeeId})'),
                    );
                  }).toList(),
                  onChanged: (UserModel? employee) {
                    setState(() => _selectedEmployee = employee);
                  },
                ),

                const SizedBox(height: 16),

                // Date Selector
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: _reportType == 'monthly' ? 'Mês/Ano' : 'Data',
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(_dateDisplayText),
                  ),
                ),
              ],
            ),
          ),

          // Report Content
          Expanded(
            child: _selectedEmployee != null
                ? EmployeeReportWidget(
                    employee: _selectedEmployee!,
                    selectedDate: _selectedDate,
                    reportType: _reportType,
                  )
                : const Center(
                    child: Text('Selecione um funcionário para visualizar o relatório'),
                  ),
          ),
        ],
      ),
    );
  }
}