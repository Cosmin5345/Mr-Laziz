import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obține profilul utilizatorului curent
  Future<app_user.User?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return app_user.User(
        id: response['id'] as String,
        email: response['email'] as String,
        fullName: response['full_name'] as String?,
        firstName: response['first_name'] as String?,
        lastName: response['last_name'] as String?,
        phone: response['phone'] as String?,
        location: response['location'] as String?,
        bio: response['bio'] as String?,
        createdAt: response['created_at'] != null
            ? DateTime.parse(response['created_at'] as String)
            : null,
        updatedAt: response['updated_at'] != null
            ? DateTime.parse(response['updated_at'] as String)
            : null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Actualizează profilul utilizatorului
  Future<bool> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? location,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (firstName != null) {
        updates['first_name'] = firstName;
      }

      if (lastName != null) {
        updates['last_name'] = lastName;
      }

      // Actualizează full_name automat când avem first_name sau last_name
      if (firstName != null || lastName != null) {
        final first = firstName ?? '';
        final last = lastName ?? '';
        updates['full_name'] = '$first $last'.trim();
      }

      if (email != null) {
        updates['email'] = email;
      }

      if (phone != null) {
        updates['phone'] = phone;
      }

      if (location != null) {
        updates['location'] = location;
      }

      if (bio != null) {
        updates['bio'] = bio;
      }

      await _supabase.from('users').update(updates).eq('id', userId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Actualizează email-ul în Supabase Auth
  Future<bool> updateAuthEmail(String newEmail) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(email: newEmail));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Actualizează parola utilizatorului
  Future<bool> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verifică dacă utilizatorul este autentificat
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Obține ID-ul utilizatorului curent
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Obține email-ul utilizatorului curent
  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }
}
