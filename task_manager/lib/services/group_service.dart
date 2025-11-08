import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/user.dart' as app_user;
import 'dart:math';

class GroupService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===== CRUD GRUPURI =====

  /// Obține toate grupurile utilizatorului curent
  Future<List<Group>> getUserGroups() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      print('Getting groups for user: $userId');

      // Obține ID-urile grupurilor din care face parte utilizatorul
      final membershipResponse = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      print('Memberships found: ${membershipResponse.length}');
      print('Membership data: $membershipResponse');

      final groupIds = (membershipResponse as List)
          .map((m) => m['group_id'] as String)
          .toList();

      if (groupIds.isEmpty) {
        print('No groups found for user');
        return [];
      }

      print('Group IDs: $groupIds');

      // Obține detaliile grupurilor
      final groupsResponse = await _supabase
          .from('groups')
          .select()
          .inFilter('id', groupIds)
          .order('created_at', ascending: false);

      print('Groups response: $groupsResponse');

      return (groupsResponse as List)
          .map((json) => Group.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading groups: $e');
      throw Exception('Failed to load groups: $e');
    }
  }

  /// Creează un grup nou folosind funcția database
  Future<Group> createGroup(String name, String? description) async {
    try {
      // Verifică sesiunea curentă
      final session = _supabase.auth.currentSession;
      final userId = _supabase.auth.currentUser?.id;

      print('=== CREATE GROUP DEBUG ===');
      print('User ID: $userId');
      print('Session exists: ${session != null}');
      print('Access Token exists: ${session?.accessToken != null}');

      if (userId == null) {
        throw Exception('User not authenticated - no user ID');
      }

      if (session == null) {
        throw Exception('User not authenticated - no session');
      }

      print('Creating group: $name for user: $userId');

      // Generează un cod de invitație unic
      final inviteCode = await _generateUniqueInviteCode();
      print('Generated invite code: $inviteCode');

      // Folosește funcția database create_group_with_leader care gestionează
      // atât crearea grupului cât și adăugarea liderului într-o singură tranzacție
      final response = await _supabase.rpc(
        'create_group_with_leader',
        params: {
          'p_name': name,
          'p_description': description,
          'p_invite_code': inviteCode,
        },
      );

      print('Group created successfully: ${response[0]['id']}');
      return Group.fromJson(response[0]);
    } catch (e) {
      print('Error creating group: $e');
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

  // ===== MEMBERSHIP =====

  /// Alătură-te unui grup folosind codul de invitație
  Future<Group> joinGroupByCode(String inviteCode) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      print('=== JOIN GROUP DEBUG ===');
      print('User ID: $userId');
      print('Invite Code: ${inviteCode.toUpperCase()}');

      // Folosește funcția database join_group_by_invite_code
      // care gestionează verificarea, validarea și adăugarea utilizatorului
      final response = await _supabase.rpc(
        'join_group_by_invite_code',
        params: {'p_invite_code': inviteCode.trim().toUpperCase()},
      );

      print('Successfully joined group!');
      print('Response: $response');

      return Group.fromJson(response[0]);
    } catch (e) {
      print('Error joining group: $e');

      // Mesaje de eroare mai prietenoase
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
      print('Error getting group leader: $e');
      return null;
    }
  }

  /// Obține userii dintr-un grup (pentru assignment), excluzând liderul
  Future<List<app_user.User>> getGroupMembersForAssignment(
    String groupId,
  ) async {
    try {
      // Obține ID-ul liderului
      final leaderId = await getGroupLeaderId(groupId);
      print('=== ASSIGNMENT DEBUG ===');
      print('Group ID: $groupId');
      print('Leader ID: $leaderId');

      // Obține toți membrii grupului (doar user_id-uri)
      final membersResponse = await _supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);

      print('Members response: $membersResponse');

      final memberIds = (membersResponse as List)
          .map((m) => m['user_id'] as String)
          .where((id) => id != leaderId) // Exclude liderul
          .toList();

      print('Member IDs (without leader): $memberIds');

      if (memberIds.isEmpty) {
        print('No members to assign (excluding leader)');
        return [];
      }

      // Obține informațiile despre useri
      final usersResponse = await _supabase
          .from('users')
          .select('id, email, full_name')
          .inFilter('id', memberIds);

      print('Users response: $usersResponse');

      final users = (usersResponse as List).map((json) {
        final user = app_user.User(
          id: json['id'] as String,
          email: json['email'] as String,
          fullName: json['full_name'] as String?,
        );
        print('Member: ${user.email} (ID: ${user.id})');
        return user;
      }).toList();

      print('Total assignable users: ${users.length}');
      print('======================');
      return users;
    } catch (e) {
      print('Error getting group members for assignment: $e');
      throw Exception('Failed to load group members: $e');
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
