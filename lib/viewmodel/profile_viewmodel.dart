import 'package:flutter/foundation.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/core/network.dart';
import 'package:ziesocial/model/notification_model.dart';
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

  List<UserModel> _searchedUsers = [];
  bool _isSearching = false;

  List<NotificationModel> _notifications = [];
  bool _isLoadingNotifications = false;

  ProfileModel? get profile => _lastProfile;
  ProfileModel? getProfile(int userId) => _profiles[userId];
  bool isUserLoading(int userId) => _loadingUserIds.contains(userId);
  String? getErrorMessage(int userId) => _errorMessages[userId];
  List<UserModel> get searchedUsers => _searchedUsers;
  bool get isSearching => _isSearching;

  /// Mengembalikan daftar aktivitas yang belum kedaluwarsa (maksimal 7 hari)
  List<NotificationModel> get notifications =>
      _notifications.where((n) => !n.isExpired).toList();
  bool get isLoadingNotifications => _isLoadingNotifications;

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
    _searchedUsers = [];
    _isSearching = false;
    _notifications = [];
    _isLoadingNotifications = false;
    notifyListeners();
  }

  Future<void> fetchNotifications(int userId, {bool silent = false}) async {
    if (userId <= 0) return;

    if (!silent) {
      _isLoadingNotifications = true;
      notifyListeners();
    }

    try {
      final response = await _apiClient.get(
        '${ApiConstants.readNotifications}?user_id=$userId',
      );
      if (response['data'] is List) {
        final loaded = (response['data'] as List)
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .where((n) => !n.isExpired)
            .toList();
        _notifications = loaded;
      }
    } catch (_) {
      // Keep existing notifications if silent refresh fails
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _searchedUsers = [];
      _isSearching = false;
      notifyListeners();
      return [];
    }

    _isSearching = true;
    notifyListeners();

    try {
      final encodedQuery = Uri.encodeQueryComponent(trimmed);
      final response = await _apiClient.get(
        '${ApiConstants.searchUsers}?q=$encodedQuery',
      );
      if (response['data'] is List) {
        _searchedUsers = (response['data'] as List)
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _searchedUsers = [];
      }
      return _searchedUsers;
    } catch (_) {
      _searchedUsers = [];
      return [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> fetchFollowList({
    required int userId,
    required String type,
    int? viewerId,
  }) async {
    try {
      var url = '${ApiConstants.followList}?user_id=$userId&type=$type';
      if (viewerId != null && viewerId > 0) {
        url += '&viewer_id=$viewerId';
      }
      final response = await _apiClient.get(url);
      if (response['data'] is List) {
        return List<Map<String, dynamic>>.from(
          (response['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
      return [];
    } catch (_) {
      return [];
    }
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

  // Toggle Follow with immediate UI update (works both from ProfileView and ActivityView)
  Future<bool> toggleFollow({
    required int targetUserId,
    required int followerId,
  }) async {
    final targetProfile = _profiles[targetUserId];
    final previousNotifications = List<NotificationModel>.from(_notifications);

    // Determine current follow status from profile cache or notification list
    bool currentIsFollowing = false;
    if (targetProfile != null) {
      currentIsFollowing = targetProfile.isFollowing;
    } else {
      final matchingNotif = _notifications
          .where((n) => n.actorId == targetUserId)
          .firstOrNull;
      if (matchingNotif != null) {
        currentIsFollowing = matchingNotif.isFollowingBack;
      }
    }

    final bool newIsFollowing = !currentIsFollowing;
    final int currentFollowers = targetProfile?.followersCount ?? 0;
    final int newFollowers = newIsFollowing
        ? currentFollowers + 1
        : (currentFollowers > 0 ? currentFollowers - 1 : 0);

    // 1. Optimistic local update on target user profile if cached
    if (targetProfile != null) {
      _profiles[targetUserId] = targetProfile.copyWith(
        isFollowing: newIsFollowing,
        followersCount: newFollowers,
      );
    }

    // 2. Optimistic update on notifications list ("Ikuti balik" -> "Mengikuti")
    _notifications = _notifications.map((n) {
      if (n.actorId == targetUserId) {
        return n.copyWith(isFollowingBack: newIsFollowing);
      }
      return n;
    }).toList();

    // 3. Optimistically update follower's following count if cached
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

      final bool serverIsFollowing = response['is_following'] == true;
      final int serverFollowers = response['followers_count'] is int
          ? response['followers_count'] as int
          : newFollowers;

      if (_profiles.containsKey(targetUserId)) {
        _profiles[targetUserId] = _profiles[targetUserId]!.copyWith(
          followersCount: serverFollowers,
          isFollowing: serverIsFollowing,
        );
      }

      _notifications = _notifications.map((n) {
        if (n.actorId == targetUserId) {
          return n.copyWith(isFollowingBack: serverIsFollowing);
        }
        return n;
      }).toList();

      notifyListeners();
      return true;
    } catch (e) {
      // Revert if error
      if (targetProfile != null && _profiles.containsKey(targetUserId)) {
        _profiles[targetUserId] = targetProfile;
      }
      if (followerProfile != null && _profiles.containsKey(followerId)) {
        _profiles[followerId] = followerProfile;
      }
      _notifications = previousNotifications;
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

  // Delete account permanently along with all user data
  Future<bool> deleteAccount(int userId) async {
    if (userId <= 0) return false;
    _loadingUserIds.add(userId);
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.deleteAccount,
        body: {
          'user_id': userId,
        },
      );
      clear();
      return true;
    } catch (e) {
      _errorMessages[userId] = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loadingUserIds.remove(userId);
      notifyListeners();
    }
  }
}
