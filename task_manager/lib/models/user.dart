class User {
  final String id; // UUID as String
  final String email;
  final String? fullName;
  final DateTime? createdAt;

  User({required this.id, required this.email, this.fullName, this.createdAt});

  // Getter pentru a folosi ca username (backward compatibility)
  String get username => fullName ?? email.split('@').first;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
