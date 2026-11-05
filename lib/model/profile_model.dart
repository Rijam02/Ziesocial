import 'package:ziesocial/model/post_model.dart';
import 'package:ziesocial/model/user_model.dart';

class HighlightItemModel {
  final int id;
  final int? postId;
  final String image;
  final String caption;
  final String createDate;

  HighlightItemModel({
    required this.id,
    this.postId,
    required this.image,
    required this.caption,
    required this.createDate,
  });

  factory HighlightItemModel.fromJson(Map<String, dynamic> json) {
    return HighlightItemModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      postId: json['post_id'] != null
          ? (json['post_id'] is int
              ? json['post_id'] as int
              : int.tryParse(json['post_id'].toString()))
          : null,
      image: json['image']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      createDate: json['create_date']?.toString() ?? '',
    );
  }
}

class HighlightModel {
  final int id;
  final int userId;
  final String title;
  final String coverImage;
  final String createDate;
  final List<HighlightItemModel> items;

  HighlightModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.coverImage,
    required this.createDate,
    required this.items,
  });

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .map((e) => HighlightItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    String cover = json['cover_image']?.toString() ?? '';
    if (parsedItems.isNotEmpty && parsedItems.first.image.isNotEmpty) {
      cover = parsedItems.first.image;
    }

    return HighlightModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      coverImage: cover,
      createDate: json['create_date']?.toString() ?? '',
      items: parsedItems,
    );
  }

  HighlightModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? coverImage,
    String? createDate,
    List<HighlightItemModel>? items,
  }) {
    return HighlightModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      coverImage: coverImage ?? this.coverImage,
      createDate: createDate ?? this.createDate,
      items: items ?? this.items,
    );
  }
}

class StoryViewerModel {
  final int userId;
  final String username;
  final String name;
  final String avatar;
  final String viewDate;
  final String viewTime;

  StoryViewerModel({
    required this.userId,
    required this.username,
    required this.name,
    required this.avatar,
    required this.viewDate,
    this.viewTime = '',
  });

  factory StoryViewerModel.fromJson(Map<String, dynamic> json) {
    final rawViewDate = json['view_date']?.toString() ?? '';
    final rawViewTime = json['view_time']?.toString() ?? '';

    return StoryViewerModel(
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      viewDate: rawViewDate,
      viewTime: rawViewTime.isNotEmpty
          ? rawViewTime
          : _formatFallbackViewTime(rawViewDate),
    );
  }

  static String _formatFallbackViewTime(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return dateStr;
      final diff = DateTime.now().difference(parsed);
      if (diff.inSeconds < 60 && !diff.isNegative) {
        return 'Baru saja';
      }
      if (diff.inMinutes < 60 && !diff.isNegative) {
        return '${diff.inMinutes} menit yang lalu';
      }
      final hh = parsed.hour.toString().padLeft(2, '0');
      final mm = parsed.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) {
      return dateStr;
    }
  }
}

class StoryItemModel {
  final int id;
  final int userId;
  final String image;
  final String caption;
  final String createDate;
  final bool isViewed;
  final List<StoryViewerModel> viewers;

  StoryItemModel({
    required this.id,
    required this.userId,
    required this.image,
    required this.caption,
    required this.createDate,
    required this.isViewed,
    required this.viewers,
  });

  factory StoryItemModel.fromJson(Map<String, dynamic> json) {
    final rawViewers = json['viewers'] as List<dynamic>? ?? [];
    return StoryItemModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      image: json['image']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      createDate: json['create_date']?.toString() ?? '',
      isViewed: json['is_viewed'] == true ||
          json['is_viewed'] == 1 ||
          json['is_viewed'] == '1',
      viewers: rawViewers
          .map((e) => StoryViewerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  StoryItemModel copyWith({
    bool? isViewed,
    List<StoryViewerModel>? viewers,
  }) {
    return StoryItemModel(
      id: id,
      userId: userId,
      image: image,
      caption: caption,
      createDate: createDate,
      isViewed: isViewed ?? this.isViewed,
      viewers: viewers ?? this.viewers,
    );
  }
}

class StoryGroupModel {
  final int userId;
  final String username;
  final String name;
  final String avatar;
  final bool isOwn;
  final bool hasStory;
  final bool hasUnseenStory;
  final List<StoryItemModel> stories;

  StoryGroupModel({
    required this.userId,
    required this.username,
    required this.name,
    required this.avatar,
    required this.isOwn,
    required this.hasStory,
    required this.hasUnseenStory,
    required this.stories,
  });

  factory StoryGroupModel.fromJson(Map<String, dynamic> json) {
    final rawStories = json['stories'] as List<dynamic>? ?? [];
    final parsedStories = rawStories
        .map((e) => StoryItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return StoryGroupModel(
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      isOwn: json['is_own'] == true || json['is_own'] == 1,
      hasStory: json['has_story'] == true ||
          json['has_story'] == 1 ||
          parsedStories.isNotEmpty,
      hasUnseenStory: json['has_unseen_story'] == true ||
          json['has_unseen_story'] == 1,
      stories: parsedStories,
    );
  }

  StoryGroupModel copyWith({
    bool? hasStory,
    bool? hasUnseenStory,
    List<StoryItemModel>? stories,
  }) {
    return StoryGroupModel(
      userId: userId,
      username: username,
      name: name,
      avatar: avatar,
      isOwn: isOwn,
      hasStory: hasStory ?? this.hasStory,
      hasUnseenStory: hasUnseenStory ?? this.hasUnseenStory,
      stories: stories ?? this.stories,
    );
  }
}

class ProfileModel {
  final UserModel user;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final List<PostModel> posts;
  final List<HighlightModel> highlights;

  ProfileModel({
    required this.user,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
    required this.posts,
    this.highlights = const [],
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final rawPosts = json['posts'] as List<dynamic>? ?? [];
    final rawHighlights = json['highlights'] as List<dynamic>? ?? [];
    return ProfileModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      postsCount: json['posts_count'] is int
          ? json['posts_count'] as int
          : int.tryParse(json['posts_count']?.toString() ?? '0') ?? 0,
      followersCount: json['followers_count'] is int
          ? json['followers_count'] as int
          : int.tryParse(json['followers_count']?.toString() ?? '0') ?? 0,
      followingCount: json['following_count'] is int
          ? json['following_count'] as int
          : int.tryParse(json['following_count']?.toString() ?? '0') ?? 0,
      isFollowing: json['is_following'] == true ||
          json['is_following'] == 1 ||
          json['is_following'] == '1',
      posts: rawPosts
          .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      highlights: rawHighlights
          .map((item) => HighlightModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  ProfileModel copyWith({
    UserModel? user,
    int? postsCount,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
    List<PostModel>? posts,
    List<HighlightModel>? highlights,
  }) {
    return ProfileModel(
      user: user ?? this.user,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      posts: posts ?? this.posts,
      highlights: highlights ?? this.highlights,
    );
  }
}
