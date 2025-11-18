import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/group_service.dart';
import 'services/preferences_service.dart';
import 'models/group.dart';
import 'config/supabase_config.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
  final PreferencesService _preferencesService = PreferencesService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  Group? _defaultGroup;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      try {
        final lastGroupId = await _preferencesService.getLastGroupId();
        Group? group;

        if (lastGroupId != null) {
          final groupService = GroupService();
          final groups = await groupService.getUserGroups();
          try {
            group = groups.firstWhere((g) => g.id == lastGroupId);
          } catch (e) {
            group = groups.isNotEmpty ? groups.first : null;
          }
        }

        group ??= await _loadOrCreateDefaultGroup();

        setState(() {
          _isAuthenticated = true;
          _defaultGroup = group;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
      return;
    }

    final token = await _authService.getToken();
    setState(() {
      _isAuthenticated = token != null && session != null;
      _isLoading = false;
    });
  }

  Future<Group?> _loadOrCreateDefaultGroup() async {
    try {
      final groupService = GroupService();
      var groups = await groupService.getUserGroups();

      if (groups.isEmpty) {
        final user = Supabase.instance.client.auth.currentUser;
        final groupName = user?.userMetadata?['first_name'] != null
            ? "${user!.userMetadata!['first_name']}'s Workspace"
            : "My Workspace";

        final newGroup = await groupService.createGroup(groupName, null);
        return newGroup;
      }

      return groups.first;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isAuthenticated && _defaultGroup != null) {
      return HomeScreen(group: _defaultGroup!);
    }

    return const AuthScreen();
  }
}
