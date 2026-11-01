class CommentModel {
  final int id;
  final int postId;
  final String text;
  final String createDate;
  final int userId;
  final String username;
  final String name;
  final String? avatar;

  CommentModel({
    required this.id,
    required this.postId,
    required this.text,
    required this.createDate,
    required this.userId,
    required this.username,
    required this.name,
    this.avatar,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      postId: json['post_id'] is int
          ? json['post_id'] as int
          : int.tryParse(json['post_id']?.toString() ?? '0') ?? 0,
      text: json['text']?.toString() ?? '',
      createDate: json['create_date']?.toString() ?? '',
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'text': text,
      'create_date': createDate,
      'user_id': userId,
      'username': username,
      'name': name,
      'avatar': avatar,
    };
  }
}
