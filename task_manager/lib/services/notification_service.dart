import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as models;

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obține toate notificările utilizatorului curent
  Future<List<models.Notification>> getNotifications() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => models.Notification.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  /// Obține doar notificările necitite
  Future<List<models.Notification>> getUnreadNotifications() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => models.Notification.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load unread notifications: $e');
    }
  }

  /// Numărul de notificări necitite
  Future<int> getUnreadCount() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Marchează o notificare ca citită
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase.rpc(
        'mark_notification_read',
        params: {'p_notification_id': notificationId},
      );
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Marchează toate notificările ca citite
  Future<void> markAllAsRead() async {
    try {
      await _supabase.rpc('mark_all_notifications_read');
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Șterge o notificare
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Șterge toate notificările
  Future<void> deleteAllNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('notifications').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  /// Stream pentru ascultarea notificărilor în real-time
  Stream<List<models.Notification>> get notificationsStream {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (data) =>
              data.map((json) => models.Notification.fromJson(json)).toList(),
        );
  }

  /// Stream pentru numărul de notificări necitite în real-time
  Stream<int> get unreadCountStream {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('is_read', false)
        .map((data) => data.length);
  }
}
