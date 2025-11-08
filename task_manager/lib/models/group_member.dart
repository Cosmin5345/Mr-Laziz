class GroupMember {
  final String id; // UUID
  final String groupId; // UUID
  final String userId; // UUID
  final String role; // 'leader' sau 'member'
  final DateTime? joinedAt;

  // Informații opționale despre user (pentru afișare)
  final String? username;
  final String? email;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    this.joinedAt,
    this.username,
    this.email,
  });

  bool get isLeader => role == 'leader';
  bool get isMember => role == 'member';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      username: json['username'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt?.toIso8601String(),
      'username': username,
      'email': email,
    };
  }

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? role,
    DateTime? joinedAt,
    String? username,
    String? email,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      username: username ?? this.username,
      email: email ?? this.email,
    );
  }
}
