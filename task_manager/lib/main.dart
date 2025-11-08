import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/group_selection_screen.dart';
import 'services/auth_service.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inițializează Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const TaskBoardApp());
}

class TaskBoardApp extends StatelessWidget {
  const TaskBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Board',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Verifică dacă există o sesiune activă în Supabase
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Sesiune activă deja
      setState(() {
        _isAuthenticated = true;
        _isLoading = false;
      });
      return;
    }

    // Dacă nu există sesiune activă, verifică dacă avem token salvat local
    final token = await _authService.getToken();
    setState(() {
      _isAuthenticated = token != null && session != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Dacă e autentificat → Group Selection (nu direct la Task Board)
    return _isAuthenticated ? const GroupSelectionScreen() : const AuthScreen();
  }
}
