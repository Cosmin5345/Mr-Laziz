class Task {
  final int id;
  final String title;
  final String? description;
  final String status;
  final int createdByUserId;
  final String? createdByUsername;
  final int? assignedToUserId;
  final String? assignedToUsername;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.createdByUserId,
    this.createdByUsername,
    this.assignedToUserId,
    this.assignedToUsername,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      createdByUserId: json['createdByUserId'] as int,
      createdByUsername: json['createdByUsername'] as String?,
      assignedToUserId: json['assignedToUserId'] as int?,
      assignedToUsername: json['assignedToUsername'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'createdByUserId': createdByUserId,
      'assignedToUserId': assignedToUserId,
    };
  }
}
