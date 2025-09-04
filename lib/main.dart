import 'package:flutter/material.dart';
import 'package:ponto/theme.dart';
import 'package:ponto/supabase/supabase_config.dart';
import 'package:ponto/screens/login_screen.dart';
import 'package:ponto/screens/employee_home_screen.dart';
import 'package:ponto/screens/admin_home_screen.dart';
import 'package:ponto/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PontoApp',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  Widget? _homeScreen;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      
      if (currentUser != null) {
        setState(() {
          _homeScreen = currentUser.isAdmin 
              ? const AdminHomeScreen()
              : const EmployeeHomeScreen();
          _isLoading = false;
        });
      } else {
        setState(() {
          _homeScreen = const LoginScreen();
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _homeScreen = const LoginScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 80,
                  color: Colors.white,
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'PontoApp',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _homeScreen ?? const LoginScreen();
  }
}