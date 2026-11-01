class UserModel {
  final String id;
  final String username;
  final String email;
  final String name;
  final String avatar;
  final String bio;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.avatar,
    required this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'avatar': avatar,
      'bio': bio,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? name,
    String? avatar,
    String? bio,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
    );
  }
}