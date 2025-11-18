import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user.dart' as app_user;
import '../../services/user_service.dart';
import '../../screens/notifications_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class ProfileDrawerModern extends StatefulWidget {
  final int totalTasks;
  final int completedTasks;
  final VoidCallback onSignOut;

  const ProfileDrawerModern({
    super.key,
    required this.totalTasks,
    required this.completedTasks,
    required this.onSignOut,
  });

  @override
  State<ProfileDrawerModern> createState() => _ProfileDrawerModernState();
}

class _ProfileDrawerModernState extends State<ProfileDrawerModern> {
  final UserService _userService = UserService();
  final _supabase = Supabase.instance.client;

  app_user.User? _currentUser;
  bool _isLoading = true;
  bool _isEditMode = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      // Încearcă să încarce profilul din tabela users
      final user = await _userService.getCurrentUserProfile();

      if (user != null) {
        // Profil găsit în tabela users
        setState(() {
          _currentUser = user;
          _firstNameController.text = user.firstName ?? '';
          _lastNameController.text = user.lastName ?? '';
          _phoneController.text = user.phone ?? '';
          _locationController.text = user.location ?? '';
          _bioController.text = user.bio ?? '';
          _isLoading = false;
        });
      } else {
        // Nu există profil în users, folosește datele din Auth
        final authUser = _supabase.auth.currentUser;
        if (authUser != null) {
          // Creează un obiect User temporar din datele Auth
          final firstName = authUser.userMetadata?['first_name'] as String?;
          final lastName = authUser.userMetadata?['last_name'] as String?;

          setState(() {
            _currentUser = app_user.User(
              id: authUser.id,
              email: authUser.email ?? '',
              firstName: firstName,
              lastName: lastName,
              createdAt: DateTime.now(),
            );
            _firstNameController.text = firstName ?? '';
            _lastNameController.text = lastName ?? '';
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    try {
      final updatedUser = app_user.User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        bio: _bioController.text.trim(),
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
      );

      await _userService.updateUserProfile(
        userId: _currentUser!.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        bio: _bioController.text.trim(),
      );

      setState(() {
        _currentUser = updatedUser;
        _isEditMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    }
  }

  String get _displayName {
    if (_currentUser == null) return 'User';
    final firstName = _currentUser!.firstName ?? '';
    final lastName = _currentUser!.lastName ?? '';
    if (firstName.isEmpty && lastName.isEmpty) return 'User';
    return '$firstName $lastName'.trim();
  }

  String get _initials {
    if (_currentUser == null) return 'U';
    final firstName = _currentUser!.firstName ?? '';
    final lastName = _currentUser!.lastName ?? '';

    if (firstName.isEmpty && lastName.isEmpty) return 'U';

    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';

    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final pendingTasks = widget.totalTasks - widget.completedTasks;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildAvatar(),
                      const SizedBox(height: 16),
                      if (!_isEditMode) ...[
                        _buildProfileInfo(),
                        const SizedBox(height: 24),
                        _buildStatistics(pendingTasks),
                        const SizedBox(height: 24),
                        _buildMenuItems(),
                      ] else ...[
                        _buildEditForm(),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              Row(
                children: [
                  if (!_isEditMode)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => setState(() => _isEditMode = true),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.indigo50,
                        foregroundColor: AppColors.indigo600,
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isEditMode
                ? 'Edit your profile information'
                : 'Your account information',
            style: const TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.indigo500, AppColors.blue500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo500.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            fontSize: 36,
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Text(
          _displayName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _currentUser?.email ?? 'No email',
          style: const TextStyle(fontSize: 14, color: AppColors.gray500),
        ),
        if (_currentUser?.phone != null && _currentUser!.phone!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone, size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text(
                _currentUser!.phone!,
                style: const TextStyle(fontSize: 13, color: AppColors.gray600),
              ),
            ],
          ),
        ],
        if (_currentUser?.location != null &&
            _currentUser!.location!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text(
                _currentUser!.location!,
                style: const TextStyle(fontSize: 13, color: AppColors.gray600),
              ),
            ],
          ),
        ],
        if (_currentUser?.bio != null && _currentUser!.bio!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _currentUser!.bio!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatistics(int pendingTasks) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.indigo50,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.totalTasks}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.indigo600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.completedTasks}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Done',
                  style: TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.orange100,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                Text(
                  '$pendingTasks',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pending',
                  style: TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () {
            Navigator.of(context).pop(); // Close drawer
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () {
            // TODO: Navigate to settings
          },
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.help_outline,
          label: 'Help & Support',
          onTap: () {
            // TODO: Navigate to help
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.gray600),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: AppColors.gray900),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.gray400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildTextField(
          controller: _firstNameController,
          label: 'First Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _lastNameController,
          label: 'Last Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone',
          icon: Icons.phone_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _locationController,
          label: 'Location',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _bioController,
          label: 'Bio',
          icon: Icons.notes_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _isEditMode = false);
                  _loadUserProfile(); // Reset form
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.gray300),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo600,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.gray50,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: ElevatedButton(
        onPressed: widget.onSignOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red500,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
