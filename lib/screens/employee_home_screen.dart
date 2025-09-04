import 'package:flutter/material.dart';
import 'package:ponto/models/user_model.dart';
import 'package:ponto/models/time_entry_model.dart';
import 'package:ponto/services/user_service.dart';
import 'package:ponto/services/time_entry_service.dart';
import 'package:ponto/screens/login_screen.dart';
import 'package:ponto/supabase/supabase_config.dart';
import 'package:ponto/widgets/time_clock_widget.dart';
import 'package:ponto/widgets/today_summary_widget.dart';
import 'dart:async';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  UserModel? _currentUser;
  List<TimeEntryModel> _todayEntries = [];
  bool _isLoading = true;
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  Future<void> _loadData() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user == null) {
        _redirectToLogin();
        return;
      }

      final todayEntries = await TimeEntryService.getTodayEntries(user.id);

      setState(() {
        _currentUser = user;
        _todayEntries = todayEntries;
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

  Future<void> _registerTimeEntry(TimeEntryType type) async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      TimeEntryModel newEntry;
      
      switch (type) {
        case TimeEntryType.clockIn:
          newEntry = await TimeEntryService.clockIn(userId: _currentUser!.id);
          break;
        case TimeEntryType.lunchOut:
          newEntry = await TimeEntryService.lunchOut(userId: _currentUser!.id);
          break;
        case TimeEntryType.lunchIn:
          newEntry = await TimeEntryService.lunchIn(userId: _currentUser!.id);
          break;
        case TimeEntryType.clockOut:
          newEntry = await TimeEntryService.clockOut(userId: _currentUser!.id);
          break;
      }

      setState(() {
        _todayEntries.add(newEntry);
        _todayEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.displayName} registrado com sucesso!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar ponto: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  TimeEntryType? _getNextEntryType() {
    if (_todayEntries.isEmpty) return TimeEntryType.clockIn;

    final lastEntry = _todayEntries.last;
    switch (lastEntry.entryType) {
      case TimeEntryType.clockIn:
        return TimeEntryType.lunchOut;
      case TimeEntryType.lunchOut:
        return TimeEntryType.lunchIn;
      case TimeEntryType.lunchIn:
        return TimeEntryType.clockOut;
      case TimeEntryType.clockOut:
        return null; // Dia completo
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final nextEntryType = _getNextEntryType();

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${_currentUser?.fullName ?? 'Funcionário'}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Time Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_currentTime.day.toString().padLeft(2, '0')}/${_currentTime.month.toString().padLeft(2, '0')}/${_currentTime.year}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Time Clock Widget
              TimeClockWidget(
                nextEntryType: nextEntryType,
                isLoading: _isLoading,
                onTimeEntry: _registerTimeEntry,
              ),

              const SizedBox(height: 24),

              // Today's Summary
              TodaySummaryWidget(
                entries: _todayEntries,
                onRefresh: _loadData,
              ),

              const SizedBox(height: 24),

              // Employee Info Card
              if (_currentUser != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Informações do Funcionário',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('ID:', _currentUser!.employeeId),
                        _buildInfoRow('Nome:', _currentUser!.fullName),
                        _buildInfoRow('Email:', _currentUser!.email),
                        if (_currentUser!.department != null)
                          _buildInfoRow('Departamento:', _currentUser!.department!),
                        if (_currentUser!.position != null)
                          _buildInfoRow('Cargo:', _currentUser!.position!),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}