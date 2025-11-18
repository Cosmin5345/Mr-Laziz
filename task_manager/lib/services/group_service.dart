import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/user.dart' as app_user;
import 'dart:math';

class GroupService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Group>> getUserGroups() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final membershipResponse = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final groupIds = (membershipResponse as List)
          .map((m) => m['group_id'] as String)
          .toList();

      if (groupIds.isEmpty) return [];

      final groupsResponse = await _supabase
          .from('groups')
          .select()
          .inFilter('id', groupIds)
          .order('created_at', ascending: false);

      return (groupsResponse as List)
          .map((json) => Group.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load groups: $e');
    }
  }

  Future<Group> createGroup(String name, String? description) async {
    try {
      final session = _supabase.auth.currentSession;
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null || session == null) {
        throw Exception('User not authenticated');
      }

      final inviteCode = await _generateUniqueInviteCode();

      final response = await _supabase.rpc(
        'create_group_with_leader',
        params: {
          'p_name': name,
          'p_description': description,
          'p_invite_code': inviteCode,
        },
      );

      return Group.fromJson(response[0]);
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  /// Actualizează un grup (doar leader-ul)
  Future<void> updateGroup(
    String groupId,
    String name,
    String? description,
  ) async {
    try {
      await _supabase
          .from('groups')
          .update({'name': name, 'description': description})
          .eq('id', groupId);
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  /// Șterge un grup (doar leader-ul)
  Future<void> deleteGroup(String groupId) async {
    try {
      await _supabase.from('groups').delete().eq('id', groupId);
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  Future<Group> joinGroupByCode(String inviteCode) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase.rpc(
        'join_group_by_invite_code',
        params: {'p_invite_code': inviteCode.trim().toUpperCase()},
      );

      return Group.fromJson(response[0]);
    } catch (e) {
      if (e.toString().contains('Invalid invite code')) {
        throw Exception('Invalid invite code. Please check and try again.');
      }
      if (e.toString().contains('already a member')) {
        throw Exception('You are already a member of this group');
      }

      throw Exception('Failed to join group: $e');
    }
  }

  /// Părăsește un grup
  Future<void> leaveGroup(String groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Verifică dacă utilizatorul este leader
      final member = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .single();

      final groupMember = GroupMember.fromJson(member);

      if (groupMember.isLeader) {
        // Verifică dacă mai sunt alți membri
        final members = await getGroupMembers(groupId);
        if (members.length > 1) {
          throw Exception('Transfer leadership before leaving the group');
        }
        // Dacă e singurul membru, șterge grupul
        await deleteGroup(groupId);
      } else {
        // Șterge membership-ul
        await _supabase
            .from('group_members')
            .delete()
            .eq('group_id', groupId)
            .eq('user_id', userId);
      }
    } catch (e) {
      throw Exception('Failed to leave group: $e');
    }
  }

  /// Obține membrii unui grup
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('''
            *,
            users!inner(username, email)
          ''')
          .eq('group_id', groupId)
          .order('role', ascending: true) // Leaders first
          .order('joined_at', ascending: true);

      return (response as List).map((json) {
        final member = GroupMember.fromJson(json);
        // Adaugă informațiile despre user
        if (json['users'] != null) {
          final userData = json['users'] as Map<String, dynamic>;
          return member.copyWith(
            username: userData['username'] as String?,
            email: userData['email'] as String?,
          );
        }
        return member;
      }).toList();
    } catch (e) {
      throw Exception('Failed to load group members: $e');
    }
  }

  /// Transferă leadership către un alt membru
  Future<void> transferLeadership(String groupId, String newLeaderId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Verifică că utilizatorul curent este leader
      final currentMember = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', currentUserId)
          .single();

      if (GroupMember.fromJson(currentMember).role != 'leader') {
        throw Exception('Only the leader can transfer leadership');
      }

      // Actualizează rolurile în tranzacție (simulat cu două update-uri)
      // Setează noul leader
      await _supabase
          .from('group_members')
          .update({'role': 'leader'})
          .eq('group_id', groupId)
          .eq('user_id', newLeaderId);

      // Setează vechiul leader ca membru
      await _supabase
          .from('group_members')
          .update({'role': 'member'})
          .eq('group_id', groupId)
          .eq('user_id', currentUserId);
    } catch (e) {
      throw Exception('Failed to transfer leadership: $e');
    }
  }

  /// Elimină un membru din grup (doar leader-ul)
  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  // ===== HELPERS =====

  /// Verifică dacă utilizatorul curent este leader al unui grup
  Future<bool> isGroupLeader(String groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final member = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (member == null) return false;

      return GroupMember.fromJson(member).isLeader;
    } catch (e) {
      return false;
    }
  }

  /// Obține ID-ul liderului unui grup
  Future<String?> getGroupLeaderId(String groupId) async {
    try {
      final leader = await _supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId)
          .eq('role', 'leader')
          .maybeSingle();

      return leader?['user_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Obține userii dintr-un grup (pentru assignment), excluzând user-ul curent
  Future<List<app_user.User>> getGroupMembersForAssignment(
    String groupId,
  ) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Folosește funcția RPC care bypass-uiește RLS
      final response = await _supabase.rpc(
        'get_group_members_for_assignment',
        params: {'p_group_id': groupId},
      );

      if ((response as List).isEmpty) {
        return [];
      }

      // Convertește răspunsul, exclude user-ul curent și elimină duplicate-uri
      final seenIds = <String>{};
      final users = <app_user.User>[];

      for (final json in response) {
        final userId = json['user_id'] as String;

        // Skip user-ul curent și duplicate-urile
        if (userId == currentUserId || seenIds.contains(userId)) {
          continue;
        }

        seenIds.add(userId);
        users.add(
          app_user.User(
            id: userId,
            email: json['email'] as String,
            fullName: json['full_name'] as String?,
          ),
        );
      }

      return users;
    } catch (e) {
      rethrow;
    }
  }

  /// Generează un cod de invitație unic
  Future<String> _generateUniqueInviteCode() async {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    const codeLength = 6;
    final random = Random();

    while (true) {
      // Generează cod
      final code = List.generate(
        codeLength,
        (index) => characters[random.nextInt(characters.length)],
      ).join();

      // Verifică unicitatea
      final existing = await _supabase
          .from('groups')
          .select('id')
          .eq('invite_code', code)
          .maybeSingle();

      if (existing == null) {
        return code;
      }
      // Dacă codul există, încearcă din nou
    }
  }

  /// Regenerează codul de invitație pentru un grup (doar leader-ul)
  Future<String> regenerateInviteCode(String groupId) async {
    try {
      final newCode = await _generateUniqueInviteCode();

      await _supabase
          .from('groups')
          .update({'invite_code': newCode})
          .eq('id', groupId);

      return newCode;
    } catch (e) {
      throw Exception('Failed to regenerate invite code: $e');
    }
  }
}
