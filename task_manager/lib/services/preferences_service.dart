import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _lastGroupIdKey = 'last_group_id';
  static const String _lastGroupNameKey = 'last_group_name';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  // Save last opened group
  Future<void> saveLastGroup(String groupId, String groupName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastGroupIdKey, groupId);
    await prefs.setString(_lastGroupNameKey, groupName);
  }

  // Get last opened group ID
  Future<String?> getLastGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastGroupIdKey);
  }

  // Get last opened group name
  Future<String?> getLastGroupName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastGroupNameKey);
  }

  // Save login state
  Future<void> saveLoginState(
    bool isLoggedIn,
    String? userId,
    String? email,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }
    if (email != null) {
      await prefs.setString(_userEmailKey, email);
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get saved user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Get saved user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Clear all preferences (logout)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Clear only group data
  Future<void> clearGroupData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastGroupIdKey);
    await prefs.remove(_lastGroupNameKey);
  }
}
