class User {
  final String id; // UUID as String
  final String username;
  final String? email;
  final DateTime? createdAt;

  User({required this.id, required this.username, this.email, this.createdAt});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
