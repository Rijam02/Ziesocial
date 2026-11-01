import 'package:flutter/foundation.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/core/network.dart';
import 'package:ziesocial/model/profile_model.dart';
import 'package:ziesocial/model/user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  ProfileViewModel(this._apiClient);

  // Cache profiles keyed by userId so different users do not overwrite each other
  final Map<int, ProfileModel> _profiles = {};
  final Set<int> _loadingUserIds = {};
  final Map<int, String?> _errorMessages = {};
  ProfileModel? _lastProfile;

  ProfileModel? get profile => _lastProfile;
  ProfileModel? getProfile(int userId) => _profiles[userId];
  bool isUserLoading(int userId) => _loadingUserIds.contains(userId);
  String? getErrorMessage(int userId) => _errorMessages[userId];

  bool get isLoading => _loadingUserIds.isNotEmpty;
  String? get errorMessage => _errorMessages.values.firstWhere(
        (msg) => msg != null,
        orElse: () => null,
      );

  void clear() {
    _profiles.clear();
    _loadingUserIds.clear();
    _errorMessages.clear();
    _lastProfile = null;
    notifyListeners();
  }

  Future<void> fetchProfile(int userId, {int? viewerId}) async {
    _loadingUserIds.add(userId);
    _errorMessages[userId] = null;
    notifyListeners();

    try {
      var url = '${ApiConstants.userProfile}?user_id=$userId';
      if (viewerId != null) {
        url += '&viewer_id=$viewerId';
      }

      final response = await _apiClient.get(url);
      final profileModel = ProfileModel.fromJson(response);
      _profiles[userId] = profileModel;
      _lastProfile = profileModel;
    } catch (e) {
      _errorMessages[userId] = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loadingUserIds.remove(userId);
      notifyListeners();
    }
  }

  // Toggle Follow with immediate UI update
  Future<bool> toggleFollow({
    required int targetUserId,
    required int followerId,
  }) async {
    final targetProfile = _profiles[targetUserId];
    if (targetProfile == null) return false;

    final currentIsFollowing = targetProfile.isFollowing;
    final int currentFollowers = targetProfile.followersCount;
    final bool newIsFollowing = !currentIsFollowing;
    final int newFollowers = newIsFollowing
        ? currentFollowers + 1
        : (currentFollowers > 0 ? currentFollowers - 1 : 0);

    // Optimistic local update on target user
    _profiles[targetUserId] = targetProfile.copyWith(
      isFollowing: newIsFollowing,
      followersCount: newFollowers,
    );

    // Optimistically update follower's following count if cached
    final followerProfile = _profiles[followerId];
    if (followerProfile != null) {
      final currentFollowing = followerProfile.followingCount;
      final newFollowing = newIsFollowing
          ? currentFollowing + 1
          : (currentFollowing > 0 ? currentFollowing - 1 : 0);
      _profiles[followerId] = followerProfile.copyWith(
        followingCount: newFollowing,
      );
    }
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.toggleFollow,
        body: {
          'follower_id': followerId,
          'following_id': targetUserId,
        },
      );

      final int serverFollowers = response['followers_count'] is int
          ? response['followers_count'] as int
          : newFollowers;
      final bool serverIsFollowing = response['is_following'] == true;

      if (_profiles.containsKey(targetUserId)) {
        _profiles[targetUserId] = _profiles[targetUserId]!.copyWith(
          followersCount: serverFollowers,
          isFollowing: serverIsFollowing,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      // Revert if error
      if (_profiles.containsKey(targetUserId)) {
        _profiles[targetUserId] = targetProfile.copyWith(
          isFollowing: currentIsFollowing,
          followersCount: currentFollowers,
        );
      }
      if (followerProfile != null && _profiles.containsKey(followerId)) {
        _profiles[followerId] = followerProfile;
      }
      notifyListeners();
      return false;
    }
  }

  // Remove post from profile grid if deleted
  Future<bool> deletePost({
    required int postId,
    required int userId,
  }) async {
    final targetProfile = _profiles[userId];
    if (targetProfile == null) return false;

    final updatedPosts = targetProfile.posts.where((p) => p.id != postId).toList();
    final updatedPostsCount = targetProfile.postsCount > 0 ? targetProfile.postsCount - 1 : 0;

    _profiles[userId] = targetProfile.copyWith(
      posts: updatedPosts,
      postsCount: updatedPostsCount,
    );
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.deletePost,
        body: {
          'post_id': postId,
          'user_id': userId,
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update profile info
  Future<UserModel?> updateProfile({
    required int userId,
    required String name,
    required String bio,
    String? avatarPath,
  }) async {
    _loadingUserIds.add(userId);
    notifyListeners();

    try {
      Map<String, dynamic> response;
      if (avatarPath != null && avatarPath.isNotEmpty) {
        response = await _apiClient.upload(
          ApiConstants.updateProfile,
          filePath: avatarPath,
          fieldName: 'avatar',
          fields: {
            'user_id': userId.toString(),
            'name': name,
            'bio': bio,
          },
        );
      } else {
        response = await _apiClient.post(
          ApiConstants.updateProfile,
          body: {
            'user_id': userId,
            'name': name,
            'bio': bio,
          },
        );
      }

      if (response['user'] != null) {
        final updatedUser = UserModel.fromJson(
          response['user'] as Map<String, dynamic>,
        );
        final currentProfile = _profiles[userId];
        if (currentProfile != null) {
          _profiles[userId] = currentProfile.copyWith(user: updatedUser);
        }
        return updatedUser;
      }
      return null;
    } catch (e) {
      _errorMessages[userId] = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _loadingUserIds.remove(userId);
      notifyListeners();
    }
  }
}
