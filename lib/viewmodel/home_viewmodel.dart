import 'package:flutter/foundation.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/core/network.dart';
import 'package:ziesocial/model/post_model.dart';
import 'package:ziesocial/model/profile_model.dart';

class HomeViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  HomeViewModel(this._apiClient);

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  StoryGroupModel? _myStoryGroup;
  List<StoryGroupModel> _storyGroups = [];
  bool _isUploadingStory = false;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StoryGroupModel? get myStoryGroup => _myStoryGroup;
  List<StoryGroupModel> get storyGroups => _storyGroups;
  bool get isUploadingStory => _isUploadingStory;

  StoryGroupModel? getStoryGroupForUser(int userId) {
    if (_myStoryGroup != null && _myStoryGroup!.userId == userId) {
      return _myStoryGroup;
    }
    for (final g in _storyGroups) {
      if (g.userId == userId) return g;
    }
    return null;
  }

  bool hasUnseenStoryForUser(int userId) {
    final g = getStoryGroupForUser(userId);
    if (g == null) return false;
    return g.hasStory && g.hasUnseenStory;
  }

  bool hasActiveStoryForUser(int userId) {
    final g = getStoryGroupForUser(userId);
    if (g == null) return false;
    return g.hasStory;
  }

  Future<void> fetchStories({int? viewerId}) async {
    try {
      final url = viewerId != null
          ? '${ApiConstants.readStories}?viewer_id=$viewerId'
          : ApiConstants.readStories;
      final response = await _apiClient.get(url);

      if (response['my_story'] is Map<String, dynamic>) {
        _myStoryGroup = StoryGroupModel.fromJson(
          response['my_story'] as Map<String, dynamic>,
        );
      } else {
        _myStoryGroup = null;
      }

      if (response['data'] is List) {
        _storyGroups = (response['data'] as List)
            .map((e) => StoryGroupModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _storyGroups = [];
      }
      notifyListeners();
    } catch (_) {
      // Keep existing stories if network error occurs
    }
  }

  Future<bool> createStory({
    required int userId,
    required String imagePath,
    Uint8List? imageBytes,
    String? fileName,
    String caption = '',
  }) async {
    _isUploadingStory = true;
    notifyListeners();

    try {
      await _apiClient.upload(
        ApiConstants.createStory,
        filePath: imagePath,
        fieldName: 'image',
        fileBytes: imageBytes,
        fileName: fileName,
        fields: {
          'user_id': userId.toString(),
          'caption': caption,
        },
      );
      await fetchStories(viewerId: userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isUploadingStory = false;
      notifyListeners();
    }
  }

  Future<bool> deleteStory({
    required int storyId,
    required int userId,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.deleteStory,
        body: {
          'story_id': storyId,
          'user_id': userId,
        },
      );
      await fetchStories(viewerId: userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> markStoryViewed({
    required int viewerId,
    int? storyId,
    int? targetUserId,
  }) async {
    if (viewerId <= 0) return;

    // Optimistic update: hilangkan border setelah dilihat
    if (targetUserId != null) {
      if (_myStoryGroup != null && _myStoryGroup!.userId == targetUserId) {
        final updatedStories = _myStoryGroup!.stories
            .map((s) => (storyId == null || s.id == storyId)
                ? s.copyWith(isViewed: true)
                : s)
            .toList();
        final anyUnseen = updatedStories.any((s) => !s.isViewed);
        _myStoryGroup = _myStoryGroup!.copyWith(
          stories: updatedStories,
          hasUnseenStory: anyUnseen,
        );
      } else {
        _storyGroups = _storyGroups.map((g) {
          if (g.userId == targetUserId) {
            final updatedStories = g.stories
                .map((s) => (storyId == null || s.id == storyId)
                    ? s.copyWith(isViewed: true)
                    : s)
                .toList();
            final anyUnseen = updatedStories.any((s) => !s.isViewed);
            return g.copyWith(
              stories: updatedStories,
              hasUnseenStory: anyUnseen,
            );
          }
          return g;
        }).toList();
      }
      notifyListeners();
    }

    try {
      await _apiClient.post(
        ApiConstants.viewStory,
        body: {
          'viewer_id': viewerId,
          if (storyId != null) 'story_id': storyId,
          if (targetUserId != null) 'target_user_id': targetUserId,
        },
      );
      await fetchStories(viewerId: viewerId);
    } catch (_) {}
  }

  Future<void> fetchPosts({int? viewerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Muat stories bersamaan dengan beranda
    fetchStories(viewerId: viewerId);

    try {
      final url = viewerId != null
          ? '${ApiConstants.readPosts}?viewer_id=$viewerId'
          : ApiConstants.readPosts;
      final response = await _apiClient.get(url);
      final dynamic rawData = response['data'];

      if (rawData is List) {
        _posts = rawData
            .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _posts = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle Like with optimistic UI update
  Future<bool> toggleLike(int postId, int userId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return false;

    final currentPost = _posts[index];
    final bool willLike = !currentPost.isLiked;
    final int newCount = willLike
        ? currentPost.likeCount + 1
        : (currentPost.likeCount > 0 ? currentPost.likeCount - 1 : 0);

    // Optimistic local update
    _posts[index] = currentPost.copyWith(
      isLiked: willLike,
      likeCount: newCount,
    );
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.toggleLike,
        body: {
          'post_id': postId,
          'user_id': userId,
        },
      );

      final int serverLikeCount = response['like_count'] is int
          ? response['like_count'] as int
          : int.tryParse(response['like_count']?.toString() ?? '') ?? newCount;
      final bool serverIsLiked = response['is_liked'] == true;

      _posts[index] = _posts[index].copyWith(
        likeCount: serverLikeCount,
        isLiked: serverIsLiked,
      );
      notifyListeners();
      return true;
    } catch (e) {
      // Revert if error
      _posts[index] = currentPost;
      notifyListeners();
      return false;
    }
  }

  // Edit Post Caption
  Future<bool> updatePost({
    required int postId,
    required int userId,
    required String caption,
  }) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return false;

    final original = _posts[index];
    _posts[index] = original.copyWith(caption: caption);
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.updatePost,
        body: {
          'post_id': postId,
          'user_id': userId,
          'caption': caption,
        },
      );
      return true;
    } catch (e) {
      // Revert
      _posts[index] = original;
      notifyListeners();
      return false;
    }
  }

  // Delete Post
  Future<bool> deletePost({
    required int postId,
    required int userId,
  }) async {
    final originalIndex = _posts.indexWhere((p) => p.id == postId);
    if (originalIndex == -1) return false;

    final removedPost = _posts.removeAt(originalIndex);
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
      // Revert
      _posts.insert(originalIndex, removedPost);
      notifyListeners();
      return false;
    }
  }

  void updateCommentCount(int postId, int newCount) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index] = _posts[index].copyWith(commentCount: newCount);
      notifyListeners();
    }
  }
}
