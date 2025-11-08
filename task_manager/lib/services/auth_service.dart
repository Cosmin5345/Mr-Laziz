import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Verifică dacă utilizatorul este autentificat
  Future<bool> isAuthenticated() async {
    final session = _supabase.auth.currentSession;
    return session != null;
  }

  // Obține utilizatorul curent
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Future<Map<String, dynamic>> register(
    String username,
    String password,
  ) async {
    try {
      // Supabase folosește email pentru autentificare
      // Vom folosi username ca email (poți modifica dacă dorești email real)
      final email = username.contains('@')
          ? username
          : '$username@taskboard.app';

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user != null) {
        // Salvează token-ul
        if (response.session?.accessToken != null) {
          await saveToken(response.session!.accessToken);
        }
        return {'success': true, 'message': 'Registration successful'};
      } else {
        return {'success': false, 'message': 'Registration failed'};
      }
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Convertește username în email dacă nu este deja
      final email = username.contains('@')
          ? username
          : '$username@taskboard.app';

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        await saveToken(response.session!.accessToken);
        return {'success': true, 'message': 'Login successful'};
      } else {
        return {'success': false, 'message': 'Invalid credentials'};
      }
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      await deleteToken();
    } catch (e) {
      // Log error dar continuă cu ștergerea token-ului local
      await deleteToken();
    }
  }
}
