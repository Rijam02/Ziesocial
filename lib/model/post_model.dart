class AuthorModel {
  final int id;
  final String username;
  final String name;
  final String? avatar;

  AuthorModel({
    required this.id,
    required this.username,
    required this.name,
    this.avatar,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'avatar': avatar,
    };
  }
}

class PostModel {
  final int id;
  final String caption;
  final String? image;
  final String createDate;
  final String updatedDate;
  final AuthorModel? author;
  final int likeCount;
  final int commentCount;
  final bool isLiked;

  PostModel({
    required this.id,
    required this.caption,
    this.image,
    required this.createDate,
    required this.updatedDate,
    this.author,
    required this.likeCount,
    required this.commentCount,
    this.isLiked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      caption: json['caption']?.toString() ?? '',
      image: json['image'] as String?,
      createDate: json['create_date']?.toString() ?? '',
      updatedDate: json['updated_date']?.toString() ?? '',
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? AuthorModel.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      likeCount: json['like_count'] is int
          ? json['like_count'] as int
          : int.tryParse(json['like_count']?.toString() ?? '0') ?? 0,
      commentCount: json['comment_count'] is int
          ? json['comment_count'] as int
          : int.tryParse(json['comment_count']?.toString() ?? '0') ?? 0,
      isLiked: json['is_liked'] == true ||
          json['is_liked'] == 1 ||
          json['is_liked'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'image': image,
      'create_date': createDate,
      'updated_date': updatedDate,
      'author': author?.toJson(),
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_liked': isLiked,
    };
  }

  PostModel copyWith({
    int? id,
    String? caption,
    String? image,
    String? createDate,
    String? updatedDate,
    AuthorModel? author,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
  }) {
    return PostModel(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      image: image ?? this.image,
      createDate: createDate ?? this.createDate,
      updatedDate: updatedDate ?? this.updatedDate,
      author: author ?? this.author,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
