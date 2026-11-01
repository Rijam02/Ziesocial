import 'package:ziesocial/model/post_model.dart';
import 'package:ziesocial/model/user_model.dart';

class ProfileModel {
  final UserModel user;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final List<PostModel> posts;

  ProfileModel({
    required this.user,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
    required this.posts,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final rawPosts = json['posts'] as List<dynamic>? ?? [];
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
    );
  }

  ProfileModel copyWith({
    UserModel? user,
    int? postsCount,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
    List<PostModel>? posts,
  }) {
    return ProfileModel(
      user: user ?? this.user,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      posts: posts ?? this.posts,
    );
  }
}
