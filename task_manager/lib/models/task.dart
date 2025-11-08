class Task {
  final String id; // Schimbat din int în String pentru UUID
  final String title;
  final String? description;
  final String status;
  final String? groupId; // UUID as String - ADĂUGAT
  final String? createdBy; // UUID as String
  final String? createdByUsername;
  final String? assignedTo; // UUID as String
  final String? assignedToUsername;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.groupId, // ADĂUGAT
    this.createdBy,
    this.createdByUsername,
    this.assignedTo,
    this.assignedToUsername,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String, // Schimbat din int în String
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      groupId: json['group_id'] as String?, // ADĂUGAT
      createdBy: json['created_by'] as String?,
      createdByUsername: json['created_by_username'] as String?,
      assignedTo: json['assigned_to'] as String?,
      assignedToUsername: json['assigned_to_username'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'group_id': groupId, // ADĂUGAT
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
