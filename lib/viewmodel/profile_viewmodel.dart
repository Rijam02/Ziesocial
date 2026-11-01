import 'package:flutter/foundation.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/core/network.dart';
import 'package:ziesocial/model/profile_model.dart';
import 'package:ziesocial/model/user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  ProfileViewModel(this._apiClient);

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile(int userId, {int? viewerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var url = '${ApiConstants.userProfile}?user_id=$userId';
      if (viewerId != null) {
        url += '&viewer_id=$viewerId';
      }

      final response = await _apiClient.get(url);
      _profile = ProfileModel.fromJson(response);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle Follow with immediate UI update
  Future<bool> toggleFollow({
    required int targetUserId,
    required int followerId,
  }) async {
    if (_profile == null) return false;

    final currentIsFollowing = _profile!.isFollowing;
    final int currentFollowers = _profile!.followersCount;
    final bool newIsFollowing = !currentIsFollowing;
    final int newFollowers = newIsFollowing
        ? currentFollowers + 1
        : (currentFollowers > 0 ? currentFollowers - 1 : 0);

    // Optimistic local update
    _profile = _profile!.copyWith(
      isFollowing: newIsFollowing,
      followersCount: newFollowers,
    );
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

      _profile = _profile!.copyWith(
        followersCount: serverFollowers,
        isFollowing: serverIsFollowing,
      );
      notifyListeners();
      return true;
    } catch (e) {
      // Revert if error
      _profile = _profile!.copyWith(
        isFollowing: currentIsFollowing,
        followersCount: currentFollowers,
      );
      notifyListeners();
      return false;
    }
  }

  // Remove post from profile grid if deleted
  Future<bool> deletePost({
    required int postId,
    required int userId,
  }) async {
    if (_profile == null) return false;

    final updatedPosts = _profile!.posts.where((p) => p.id != postId).toList();
    final updatedPostsCount = _profile!.postsCount > 0 ? _profile!.postsCount - 1 : 0;

    _profile = _profile!.copyWith(
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
    _isLoading = true;
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
        if (_profile != null) {
          _profile = _profile!.copyWith(user: updatedUser);
        }
        return updatedUser;
      }
      return null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
