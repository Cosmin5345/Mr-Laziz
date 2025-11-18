class Task {
  final String id; // UUID as String
  final String title;
  final String? description;
  final String status;
  final String? groupId; // UUID as String
  final String? createdBy; // UUID as String
  final String? createdByUsername;
  final String? assignedTo; // UUID as String
  final String? assignedToUsername;
  final DateTime? deadline;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? priority; // ADĂUGAT pentru UI
  final bool completed; // ADĂUGAT pentru UI
  final String? type; // ADĂUGAT pentru UI
  final List<String>? tags; // ADĂUGAT pentru UI

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.groupId,
    this.createdBy,
    this.createdByUsername,
    this.assignedTo,
    this.assignedToUsername,
    this.deadline,
    this.createdAt,
    this.updatedAt,
    this.priority,
    bool? completed,
    this.type,
    this.tags,
  }) : completed = completed ?? (status == 'done' || status == 'Done');

  // Helper getter pentru compatibilitate cu widget-uri
  String? get dueDate {
    if (deadline == null) return null;
    return '${deadline!.day}/${deadline!.month}/${deadline!.year}';
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      groupId: json['group_id'] as String?,
      createdBy: json['created_by'] as String?,
      createdByUsername: json['created_by_username'] as String?,
      assignedTo: json['assigned_to'] as String?,
      assignedToUsername: json['assigned_to_username'] as String?,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      priority: json['priority'] as String? ?? 'low',
      completed: json['completed'] as bool?,
      type: json['type'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'group_id': groupId,
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'priority': priority,
      'completed': completed,
      'type': type,
      'tags': tags,
    };
  }
}
