class NotificationModel {
  final String id;
  final String type; // 'follow', 'like', 'comment'
  final int actorId;
  final String actorUsername;
  final String actorName;
  final String actorAvatar;
  final int? postId;
  final String? postImage;
  final String? postCaption;
  final String? commentText;
  final bool isFollowingBack;
  final String createDate;

  NotificationModel({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorUsername,
    required this.actorName,
    required this.actorAvatar,
    this.postId,
    this.postImage,
    this.postCaption,
    this.commentText,
    required this.isFollowingBack,
    required this.createDate,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'like',
      actorId: json['actor_id'] is int
          ? json['actor_id'] as int
          : int.tryParse(json['actor_id']?.toString() ?? '0') ?? 0,
      actorUsername: json['actor_username']?.toString() ?? '',
      actorName: json['actor_name']?.toString() ?? '',
      actorAvatar: json['actor_avatar']?.toString() ?? '',
      postId: json['post_id'] != null
          ? (json['post_id'] is int
              ? json['post_id'] as int
              : int.tryParse(json['post_id'].toString()))
          : null,
      postImage: json['post_image']?.toString(),
      postCaption: json['post_caption']?.toString(),
      commentText: json['comment_text']?.toString(),
      isFollowingBack: json['is_following_back'] == true ||
          json['is_following_back'] == 1 ||
          json['is_following_back'] == '1',
      createDate: json['create_date']?.toString() ?? '',
    );
  }

  DateTime? get createdAt => DateTime.tryParse(createDate);

  /// Aktivitas hanya bertahan maksimal 7 hari
  bool get isExpired {
    final dt = createdAt;
    if (dt == null) return false;
    return DateTime.now().difference(dt).inDays >= 7;
  }

  String get relativeTime {
    final dt = createdAt;
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} j';
    } else {
      return '${diff.inDays} h';
    }
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    int? actorId,
    String? actorUsername,
    String? actorName,
    String? actorAvatar,
    int? postId,
    String? postImage,
    String? postCaption,
    String? commentText,
    bool? isFollowingBack,
    String? createDate,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      actorId: actorId ?? this.actorId,
      actorUsername: actorUsername ?? this.actorUsername,
      actorName: actorName ?? this.actorName,
      actorAvatar: actorAvatar ?? this.actorAvatar,
      postId: postId ?? this.postId,
      postImage: postImage ?? this.postImage,
      postCaption: postCaption ?? this.postCaption,
      commentText: commentText ?? this.commentText,
      isFollowingBack: isFollowingBack ?? this.isFollowingBack,
      createDate: createDate ?? this.createDate,
    );
  }
}

