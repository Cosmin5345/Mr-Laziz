import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/preferences_service.dart';
import '../utils/password_validator.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _preferencesService = PreferencesService();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupFirstNameController = TextEditingController();
  final _signupLastNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();

  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _passwordValidation;
  bool _showPasswordRequirements = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupFirstNameController.dispose();
    _signupLastNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_loginEmailController.text.isEmpty ||
        _loginPasswordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );

      // Salvează starea de login
      if (response.user != null) {
        await _preferencesService.saveLoginState(
          true,
          response.user!.id,
          response.user!.email,
        );
      }

      if (mounted) {
        // Load or create a default group
        final group = await _loadOrCreateDefaultGroup();
        setState(() => _isLoading = false);

        if (group != null) {
          // Salvează ultimul grup deschis
          await _preferencesService.saveLastGroup(group.id, group.name);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(group: group)),
          );
        } else {
          _showError('Could not load workspace');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  Future<void> _handleSignup() async {
    if (_signupFirstNameController.text.isEmpty ||
        _signupLastNameController.text.isEmpty ||
        _signupEmailController.text.isEmpty ||
        _signupPasswordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    // Validează parola
    final passwordValidation = PasswordValidator.validate(
      _signupPasswordController.text,
    );
    if (!passwordValidation['isValid']) {
      final errors = passwordValidation['errors'] as List<String>;
      _showError('Password requirements:\n${errors.join('\n')}');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _supabase.auth.signUp(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text,
        data: {
          'first_name': _signupFirstNameController.text.trim(),
          'last_name': _signupLastNameController.text.trim(),
        },
      );

      // Salvează starea de login
      if (response.user != null) {
        await _preferencesService.saveLoginState(
          true,
          response.user!.id,
          response.user!.email,
        );
      }

      if (mounted) {
        // Load or create a default group
        final group = await _loadOrCreateDefaultGroup();
        setState(() => _isLoading = false);

        if (group != null) {
          // Salvează ultimul grup deschis
          await _preferencesService.saveLastGroup(group.id, group.name);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(group: group)),
          );
        } else {
          _showError('Could not create workspace');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  void _handleGoogleAuth() async {
    setState(() => _isLoading = true);
    // Simulate Google auth
    final group = await _loadOrCreateDefaultGroup();
    setState(() => _isLoading = false);

    if (group != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(group: group)),
      );
    }
  }

  Future<Group?> _loadOrCreateDefaultGroup() async {
    try {
      final groupService = GroupService();
      var groups = await groupService.getUserGroups();

      if (groups.isEmpty) {
        // Create a default group for the user
        final user = _supabase.auth.currentUser;
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildAuthCard(),
                      const SizedBox(height: 32),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEDE9FE), // violet-100
            Color(0xFFFAE8FF), // fuchsia-50
            Color(0xFFCFFAFE), // cyan-100
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated blob 1
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA78BFA).withValues(alpha: 0.4),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Animated blob 2
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withValues(alpha: 0.4),
                    const Color(0xFFDB2777).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Grid overlay
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B5CF6), // violet-500
                Color(0xFF9333EA), // purple-600
                Color(0xFFD946EF), // fuchsia-500
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF7C3AED), // violet-600
              Color(0xFF9333EA), // purple-600
              Color(0xFFD946EF), // fuchsia-600
            ],
          ).createShader(bounds),
          child: const Text(
            'TaskFlow',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your productivity companion',
          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildAuthCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                _buildTabBar(),
                const SizedBox(height: 32),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildLoginForm(), _buildSignupForm()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEDE9FE), // violet-100
            Color(0xFFFAE8FF), // fuchsia-100
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        labelColor: const Color(0xFF1F2937),
        unselectedLabelColor: const Color(0xFF6B7280),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Log In'),
          Tab(text: 'Sign Up'),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'Email',
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            hint: 'your@email.com',
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Password',
            controller: _loginPasswordController,
            obscureText: true,
            hint: '••••••••',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 14, color: Color(0xFF8B5CF6)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildGradientButton(
            text: 'Log In',
            onPressed: _isLoading ? null : _handleLogin,
          ),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildGoogleButton(),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'First Name',
            controller: _signupFirstNameController,
            hint: 'John',
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Last Name',
            controller: _signupLastNameController,
            hint: 'Doe',
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Email',
            controller: _signupEmailController,
            keyboardType: TextInputType.emailAddress,
            hint: 'your@email.com',
          ),
          const SizedBox(height: 20),
          _buildPasswordField(),
          const SizedBox(height: 24),
          _buildGradientButton(
            text: 'Sign Up',
            onPressed: _isLoading ? null : _handleSignup,
          ),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildGoogleButton(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _signupPasswordController,
              obscureText: !_showPasswordRequirements,
              onChanged: (value) {
                setState(() {
                  _passwordValidation = PasswordValidator.validate(value);
                });
              },
              onTap: () {
                setState(() {
                  _showPasswordRequirements = true;
                });
              },
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B5CF6),
                    width: 2,
                  ),
                ),
                suffixIcon: _signupPasswordController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          _showPasswordRequirements
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF9CA3AF),
                        ),
                        onPressed: () {
                          setState(() {
                            _showPasswordRequirements =
                                !_showPasswordRequirements;
                          });
                        },
                      )
                    : null,
              ),
            ),
            if (_passwordValidation != null &&
                _signupPasswordController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPasswordStrengthIndicator(_passwordValidation!),
              const SizedBox(height: 12),
              _buildPasswordRequirements(_passwordValidation!),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPasswordStrengthIndicator(Map<String, dynamic> validation) {
    final strength = validation['strength'] as int;
    final message = PasswordValidator.getStrengthMessage(strength);
    final colorHex = PasswordValidator.getStrengthColor(strength);
    final color = Color(
      int.parse(colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Password Strength',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: strength / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements(Map<String, dynamic> validation) {
    final errors = validation['errors'] as List<String>;
    final isValid = validation['isValid'] as bool;

    if (isValid) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Password meets all requirements!',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF065F46),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password must contain:',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF991B1B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...errors.map(
            (error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({required String text, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF8B5CF6), // violet-500
                Color(0xFF9333EA), // purple-600
                Color(0xFFD946EF), // fuchsia-500
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _handleGoogleAuth,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/favicon.ico',
              width: 20,
              height: 20,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.g_mobiledata, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              _tabController.index == 0
                  ? 'Sign in with Google'
                  : 'Sign up with Google',
              style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.02)
      ..strokeWidth = 1;

    const spacing = 60.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
