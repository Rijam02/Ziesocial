import 'package:flutter/foundation.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/core/network.dart';
import 'package:ziesocial/model/post_model.dart';

class HomeViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  HomeViewModel(this._apiClient);

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPosts({int? viewerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

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
